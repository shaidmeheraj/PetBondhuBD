import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class CommunityForumPage extends StatefulWidget {
  const CommunityForumPage({super.key});

  @override
  State<CommunityForumPage> createState() => _CommunityForumPageState();
}

class _CommunityForumPageState extends State<CommunityForumPage> {
  final TextEditingController _questionController = TextEditingController();
  StreamSubscription<User?>? _authSubscription;
  User? _currentUser;
  bool _postingQuestion = false;

  Future<_ForumProfile> _loadForumProfile(User user) async {
    String name = _displayName(user);
    String photoUrl = user.photoURL ?? '';
    try {
      final doc = await FirebaseFirestore.instance
          .collection('settings')
          .doc(user.uid)
          .get();
      if (doc.exists) {
        final data = doc.data();
        if (data != null) {
          final storedName = (data['name'] as String?)?.trim();
          final storedPhoto =
              ((data['photoURL'] as String?) ?? (data['photoUrl'] as String?))
                  ?.trim();
          if (storedName != null && storedName.isNotEmpty) {
            name = storedName;
          }
          if (storedPhoto != null && storedPhoto.isNotEmpty) {
            photoUrl = storedPhoto;
          }
        }
      }
    } catch (_) {
      // Silently ignore profile lookup failures; fall back to auth info.
    }
    return _ForumProfile(name: name, photoUrl: photoUrl);
  }

  @override
  void initState() {
    super.initState();
    _currentUser = FirebaseAuth.instance.currentUser;
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen((
      event,
    ) {
      if (!mounted) return;
      setState(() => _currentUser = event);
    });
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _questionController.dispose();
    super.dispose();
  }

  String _displayName(User? user) {
    final displayName = user?.displayName;
    if (displayName != null && displayName.trim().isNotEmpty) {
      return displayName.trim();
    }
    final email = user?.email;
    if (email != null && email.trim().isNotEmpty) {
      return email.trim();
    }
    return 'Anonymous';
  }

  Future<void> _createQuestion() async {
    final text = _questionController.text.trim();
    if (text.isEmpty) {
      return;
    }
    final user = _currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sign in to post a question.')),
      );
      return;
    }
    setState(() => _postingQuestion = true);
    try {
      final profile = await _loadForumProfile(user);
      await FirebaseFirestore.instance.collection('community_questions').add({
        'text': text,
        'ownerId': user.uid,
        'ownerName': profile.name,
        'ownerEmail': user.email ?? '',
        'ownerPhoto': profile.photoUrl,
        'createdAt': FieldValue.serverTimestamp(),
        'commentCount': 0,
      });
      _questionController.clear();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Question posted.')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not post question: $e')));
    } finally {
      if (mounted) {
        setState(() => _postingQuestion = false);
      }
    }
  }

  Future<void> _promptCommentDialog(
    QueryDocumentSnapshot<Map<String, dynamic>> questionDoc,
  ) async {
    final user = _currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sign in to add a comment.')),
      );
      return;
    }
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Comment'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: 4,
          minLines: 1,
          decoration: const InputDecoration(
            hintText: 'Share your answer or suggestion',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final text = controller.text.trim();
              if (text.isEmpty) {
                Navigator.of(context).pop();
                return;
              }
              Navigator.of(context).pop(text);
            },
            child: const Text('Post'),
          ),
        ],
      ),
    );
    if (result == null) return;
    await _addComment(questionDoc, result.trim(), user);
  }

  Future<void> _addComment(
    QueryDocumentSnapshot<Map<String, dynamic>> questionDoc,
    String comment,
    User user,
  ) async {
    if (comment.isEmpty) return;

    final questionRef = questionDoc.reference;
    final commentRef = questionRef.collection('comments').doc();

    try {
      final profile = await _loadForumProfile(user);
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final questionSnapshot = await transaction.get(questionRef);
        final data = questionSnapshot.data() ?? <String, dynamic>{};
        final currentCount = (data['commentCount'] ?? 0) as num;
        transaction.set(commentRef, {
          'text': comment,
          'createdAt': FieldValue.serverTimestamp(),
          'ownerId': user.uid,
          'ownerName': profile.name,
          'ownerEmail': user.email ?? '',
          'ownerPhoto': profile.photoUrl,
        });
        transaction.update(questionRef, {
          'commentCount': currentCount + 1,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Comment added.')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to add comment: $e')));
    }
  }

  bool _canManageQuestion(String ownerId) {
    final uid = _currentUser?.uid;
    if (uid == null) return false;
    return uid == ownerId;
  }

  bool _canDeleteComment(String commentOwnerId, String questionOwnerId) {
    final uid = _currentUser?.uid;
    if (uid == null) return false;
    return uid == commentOwnerId || uid == questionOwnerId;
  }

  Future<void> _confirmDeleteQuestion(
    QueryDocumentSnapshot<Map<String, dynamic>> questionDoc,
  ) async {
    final data = questionDoc.data();
    final ownerId = (data['ownerId'] ?? '').toString();
    if (!_canManageQuestion(ownerId)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Only the author can delete this question.'),
        ),
      );
      return;
    }

    final text = (data['text'] ?? '').toString();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete question'),
        content: Text('Remove "$text" and all associated comments?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    await _deleteQuestion(questionDoc.reference);
  }

  Future<void> _deleteQuestion(
    DocumentReference<Map<String, dynamic>> questionRef,
  ) async {
    try {
      final commentsSnapshot = await questionRef.collection('comments').get();
      final batch = FirebaseFirestore.instance.batch();
      for (final commentDoc in commentsSnapshot.docs) {
        batch.delete(commentDoc.reference);
      }
      batch.delete(questionRef);
      await batch.commit();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Question deleted.')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not delete question: $e')));
    }
  }

  Future<void> _deleteComment(
    QueryDocumentSnapshot<Map<String, dynamic>> questionDoc,
    QueryDocumentSnapshot<Map<String, dynamic>> commentDoc,
  ) async {
    final questionData = questionDoc.data();
    final commentData = commentDoc.data();
    final questionOwnerId = (questionData['ownerId'] ?? '').toString();
    final commentOwnerId = (commentData['ownerId'] ?? '').toString();

    if (!_canDeleteComment(commentOwnerId, questionOwnerId)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You do not have permission to remove this comment.'),
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete comment'),
        content: const Text('Remove this comment?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        transaction.delete(commentDoc.reference);
        final questionSnapshot = await transaction.get(questionDoc.reference);
        final data = questionSnapshot.data() ?? <String, dynamic>{};
        final currentCount = (data['commentCount'] ?? 0) as num;
        final updatedCount = currentCount <= 0 ? 0 : currentCount - 1;
        transaction.update(questionDoc.reference, {
          'commentCount': updatedCount,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Comment deleted.')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to delete comment: $e')));
    }
  }

  String? _formatTimestamp(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) {
      final date = value.toDate();
      return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    }
    if (value is DateTime) {
      return '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
    }
    return value.toString();
  }

  String _initials(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return '?';
    final parts = trimmed.split(RegExp(r'\s+'));
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }
    return (parts[0].substring(0, 1) + parts[1].substring(0, 1)).toUpperCase();
  }

  Widget _buildQuestionCard(
    QueryDocumentSnapshot<Map<String, dynamic>> questionDoc,
  ) {
    final data = questionDoc.data();
    final questionText = (data['text'] ?? '').toString();
    final ownerName = (data['ownerName'] ?? 'Anonymous').toString();
    final ownerPhoto = (data['ownerPhoto'] ?? '').toString();
    final ownerId = (data['ownerId'] ?? '').toString();
    final createdAt = _formatTimestamp(data['createdAt']);
    final commentCount = (data['commentCount'] ?? 0) as num;
    final canManage = _canManageQuestion(ownerId);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildAvatar(
                  radius: 22,
                  photoUrl: ownerPhoto,
                  fallbackName: ownerName,
                  backgroundColor: Colors.deepPurple.shade100,
                  foregroundColor: Colors.deepPurple.shade700,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        questionText,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        createdAt == null
                            ? 'Asked by $ownerName'
                            : 'Asked by $ownerName · $createdAt',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
                if (canManage)
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'delete') {
                        _confirmDeleteQuestion(questionDoc);
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem<String>(
                        value: 'delete',
                        child: Text('Delete'),
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Comments ($commentCount)',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: questionDoc.reference
                  .collection('comments')
                  .orderBy('createdAt', descending: false)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                if (snapshot.hasError) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Text('Error loading comments: ${snapshot.error}'),
                  );
                }
                final comments = snapshot.data?.docs ?? [];
                if (comments.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text('No answers yet. Be the first to help.'),
                  );
                }
                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: comments.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final commentDoc = comments[index];
                    return _buildCommentTile(questionDoc, commentDoc);
                  },
                );
              },
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => _promptCommentDialog(questionDoc),
                icon: const Icon(Icons.add_comment_outlined),
                label: const Text('Add comment'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommentTile(
    QueryDocumentSnapshot<Map<String, dynamic>> questionDoc,
    QueryDocumentSnapshot<Map<String, dynamic>> commentDoc,
  ) {
    final data = commentDoc.data();
    final text = (data['text'] ?? '').toString();
    final ownerName = (data['ownerName'] ?? 'Anonymous').toString();
    final ownerPhoto = (data['ownerPhoto'] ?? '').toString();
    final ownerId = (data['ownerId'] ?? '').toString();
    final createdAt = _formatTimestamp(data['createdAt']);
    final questionOwnerId = (questionDoc.data()['ownerId'] ?? '').toString();
    final canDelete = _canDeleteComment(ownerId, questionOwnerId);

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: _buildAvatar(
        radius: 18,
        photoUrl: ownerPhoto,
        fallbackName: ownerName,
        backgroundColor: Colors.grey.shade200,
        foregroundColor: Colors.grey.shade800,
      ),
      title: Text(
        ownerName,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Text(text),
          if (createdAt != null)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                createdAt,
                style: const TextStyle(fontSize: 11, color: Colors.black45),
              ),
            ),
        ],
      ),
      trailing: canDelete
          ? IconButton(
              tooltip: 'Remove comment',
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
              onPressed: () => _deleteComment(questionDoc, commentDoc),
            )
          : null,
    );
  }

  Widget _buildAvatar({
    required double radius,
    required String photoUrl,
    required String fallbackName,
    Color? backgroundColor,
    Color? foregroundColor,
  }) {
    final imageProvider = _resolveImageProvider(photoUrl);
    if (imageProvider != null) {
      return CircleAvatar(
        radius: radius,
        backgroundImage: imageProvider,
        backgroundColor: Colors.transparent,
      );
    }
    return CircleAvatar(
      radius: radius,
      backgroundColor: backgroundColor ?? Colors.grey.shade200,
      foregroundColor: foregroundColor ?? Colors.grey.shade800,
      child: Text(_initials(fallbackName)),
    );
  }

  ImageProvider? _resolveImageProvider(String? value) {
    if (value == null || value.isEmpty) return null;
    try {
      if (value.startsWith('data:')) {
        final commaIndex = value.indexOf(',');
        final payload = commaIndex >= 0
            ? value.substring(commaIndex + 1)
            : value;
        final bytes = base64Decode(payload);
        return MemoryImage(bytes);
      }
      if (value.startsWith('http')) {
        return NetworkImage(value);
      }
      final bytes = base64Decode(value);
      return MemoryImage(bytes);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Community Forum'),
        backgroundColor: Colors.deepPurple,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _questionController,
                      minLines: 1,
                      maxLines: 4,
                      enabled: !_postingQuestion,
                      decoration: InputDecoration(
                        labelText: _currentUser == null
                            ? 'Sign in to ask a question'
                            : 'Ask a question',
                        border: const OutlineInputBorder(),
                      ),
                      onSubmitted: (_) => _createQuestion(),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _postingQuestion ? null : _createQuestion,
                        icon: _postingQuestion
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.send),
                        label: Text(
                          _postingQuestion ? 'Posting...' : 'Post question',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('community_questions')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text('Error loading questions: ${snapshot.error}'),
                    ),
                  );
                }
                final docs = snapshot.data?.docs ?? [];
                if (docs.isEmpty) {
                  return const Center(
                    child: Text('No questions yet. Be the first to ask!'),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  itemCount: docs.length,
                  itemBuilder: (context, index) =>
                      _buildQuestionCard(docs[index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ForumProfile {
  const _ForumProfile({required this.name, required this.photoUrl});

  final String name;
  final String photoUrl;
}
