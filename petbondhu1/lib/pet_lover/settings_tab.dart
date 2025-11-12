import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import '../login_screen.dart';
import '../main.dart';
import 'my_pets_page.dart';


class SettingsTab extends StatefulWidget {
  final String role;
  const SettingsTab({super.key, this.role = "Pet Lover"});

  @override
  State<SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends State<SettingsTab> {
  String name = 'Demo User';
  String email = '';
  String photoUrl = ''; // may contain network URL or a data URL (base64)
  late String role;
  bool notificationsEnabled = true;
  bool _loading = true;

  String? _pickedPhotoDataUrl; // temporary picked image as data URL while editing

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    role = widget.role;
    _loadProfile();
  }

  void _editProfile() {
    // Prefill controllers with current values
    TextEditingController nameCtrl = TextEditingController(text: name);
    TextEditingController emailCtrl = TextEditingController(text: email);
    TextEditingController photoCtrl = TextEditingController(text: photoUrl);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Profile'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              // Email editing is allowed in UI but we won't change auth email here
              TextField(
                controller: emailCtrl,
                decoration: const InputDecoration(labelText: 'Email (read-only)'),
                readOnly: true,
              ),
              // Photo selector: allow picking from gallery and preview
              const SizedBox(height: 12),
              Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundImage: _pickedPhotoDataUrl != null
                        ? MemoryImage(base64Decode(_pickedPhotoDataUrl!.split(',').last)) as ImageProvider
                        : (photoUrl.isNotEmpty && photoUrl.startsWith('data:')
                            ? MemoryImage(base64Decode(photoUrl.split(',').last))
                            : (photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null)),
                    child: (photoUrl.isEmpty && _pickedPhotoDataUrl == null) ? const Icon(Icons.person) : null,
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: () async {
                      // pick image from gallery, convert to base64 data URL and show preview
                      final ImagePicker picker = ImagePicker();
                      final XFile? file = await picker.pickImage(
                        source: ImageSource.gallery,
                        maxWidth: 1024,
                        maxHeight: 1024,
                        imageQuality: 80,
                      );
                      if (file == null) return;
                      final bytes = await file.readAsBytes();
                      final mime = file.mimeType ?? 'image/jpeg';
                      final b64 = base64Encode(bytes);
                      final dataUrl = 'data:$mime;base64,$b64';
                      setState(() {
                        _pickedPhotoDataUrl = dataUrl;
                        photoCtrl.text = dataUrl; // reflect in the controller if needed
                      });
                    },
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Pick from gallery'),
                  ),
                ],
              ),
              DropdownButtonFormField<String>(
                value: role,
                decoration: const InputDecoration(labelText: 'Role'),
                items: ['Pet Lover', 'Shop Owner', 'Admin']
                    .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                    .toList(),
                onChanged: (val) {
                  if (val != null) setState(() => role = val);
                },
              ),
            ],
          ),
        ),
        actions: [
              TextButton(
                onPressed: () async {
                  // Save to Firestore under collection `settings/{uid}` with field name `photoURL`
                  final user = _auth.currentUser;
                  if (user == null) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Not signed in')));
                    return;
                  }

                  final docRef = _firestore.collection('settings').doc(user.uid);
                  try {
                    // prefer the newly picked data URL, otherwise use whatever is in photoCtrl
                    final dataUrlToSave = _pickedPhotoDataUrl ?? (photoCtrl.text.trim().isNotEmpty ? photoCtrl.text.trim() : null);

                    final Map<String, Object?> payload = {
                      'name': nameCtrl.text.trim(),
                      'role': role,
                      'email': email,
                    };
                    if (dataUrlToSave != null) payload['photoURL'] = dataUrlToSave;

                    await docRef.set(payload, SetOptions(merge: true));

                    setState(() {
                      name = nameCtrl.text.trim();
                      if (dataUrlToSave != null) photoUrl = dataUrlToSave;
                    });

                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated')));
                    Navigator.pop(context);
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to save profile: $e')));
                  }
                },
                child: const Text('Save'),
              ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _changePassword() {
    TextEditingController passCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Password'),
        content: TextField(
          controller: passCtrl,
          decoration: const InputDecoration(labelText: 'New Password'),
          obscureText: true,
        ),
        actions: [
          TextButton(
            onPressed: () {
              // TODO: Save password securely
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _logout() async {
    await _auth.signOut();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  Future<void> _loadProfile() async {
    setState(() => _loading = true);
    final user = _auth.currentUser;
    if (user == null) {
      // Not signed in
      setState(() {
        email = '';
        name = 'Demo User';
        photoUrl = '';
        _loading = false;
      });
      return;
    }

    try {
      email = user.email ?? '';
      final doc = await _firestore.collection('settings').doc(user.uid).get();
      if (doc.exists) {
        final data = doc.data()!;
        setState(() {
          name = (data['name'] as String?) ?? name;
          // support both legacy 'photoUrl' and new 'photoURL' fields
          photoUrl = (data['photoURL'] as String?) ?? (data['photoUrl'] as String?) ?? photoUrl;
          role = (data['role'] as String?) ?? role;
        });
      }
    } catch (e) {
      // Defer showing SnackBar until after build to avoid 'deactivated widget' errors
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to load profile: $e')));
      });
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.deepPurple.shade100, Colors.teal.shade50],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Center(
                child: Column(
                  children: [
                    CircleAvatar(
            radius: 48,
            backgroundImage: photoUrl.isNotEmpty
              ? (photoUrl.startsWith('data:')
                ? MemoryImage(base64Decode(photoUrl.split(',').last))
                : NetworkImage(photoUrl))
              : null,
            child: photoUrl.isEmpty ? const Icon(Icons.person, size: 48) : null,
                    ),
                    const SizedBox(height: 16),
                    Text(name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(email, style: const TextStyle(fontSize: 16, color: Colors.grey)),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.person, color: Colors.deepPurple),
                        const SizedBox(width: 8),
                        Text(role, style: const TextStyle(fontWeight: FontWeight.w600)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _editProfile,
                      icon: const Icon(Icons.edit),
                      label: const Text('Edit Profile'),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Card(
                elevation: 3,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.light_mode, color: Colors.amber),
                              const SizedBox(width: 8),
                              const Text('Theme'),
                            ],
                          ),
                          Switch(
                            value: themeModeNotifier.value == ThemeMode.dark,
                            onChanged: (val) {
                              setState(() {
                                themeModeNotifier.value = val ? ThemeMode.dark : ThemeMode.light;
                              });
                            },
                          ),
                        ],
                      ),
                      const Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.notifications_active, color: Colors.teal),
                              const SizedBox(width: 8),
                              const Text('Notifications'),
                            ],
                          ),
                          Switch(
                            value: notificationsEnabled,
                            onChanged: (val) {
                              setState(() {
                                notificationsEnabled = val;
                              });
                            },
                          ),
                        ],
                      ),
                      const Divider(),
                      ListTile(
                        leading: const Icon(Icons.lock, color: Colors.teal),
                        title: const Text('Change Password'),
                        onTap: _changePassword,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Card(
                elevation: 3,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.pets, color: Colors.deepPurple),
                      title: const Text('My Pets'),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (context) => const MyPetsPage()),
                        );
                      },
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.forum, color: Colors.deepPurple),
                      title: const Text('My Posts'),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () {
                        // TODO: Navigate to My Posts page
                      },
                    ),
                    if (role == 'Shop Owner' || role == 'Admin') ...[
                      const Divider(),
                      ListTile(
                        leading: const Icon(Icons.shopping_bag, color: Colors.orange),
                        title: const Text('My Orders'),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () {
                          // TODO: Navigate to My Orders page
                        },
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 32),
              Center(
                child: ElevatedButton.icon(
                  onPressed: _logout,
                  icon: const Icon(Icons.logout),
                  label: const Text('Logout'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
