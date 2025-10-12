import 'package:flutter/material.dart';

class CommunityForumPage extends StatefulWidget {
  const CommunityForumPage({super.key});

  @override
  State<CommunityForumPage> createState() => _CommunityForumPageState();
}

class _CommunityForumPageState extends State<CommunityForumPage> {
  final List<Map<String, dynamic>> questions = [
    {
      'question': 'My cat stopped eating, what should I do?',
      'comments': [
        {'text': 'Try changing the food brand.', 'upvotes': 2},
        {'text': 'Visit a vet if it continues.', 'upvotes': 5},
      ],
      'upvotes': 3,
    },
  ];

  final TextEditingController _questionController = TextEditingController();

  void _addQuestion() {
    if (_questionController.text.trim().isNotEmpty) {
      setState(() {
        questions.insert(0, {
          'question': _questionController.text.trim(),
          'comments': [],
          'upvotes': 0,
        });
        _questionController.clear();
      });
    }
  }

  void _addComment(int qIndex, String comment) {
    if (comment.trim().isNotEmpty) {
      setState(() {
        questions[qIndex]['comments'].add({'text': comment.trim(), 'upvotes': 0});
      });
    }
  }

  void _upvoteQuestion(int qIndex) {
    setState(() {
      questions[qIndex]['upvotes']++;
    });
  }

  void _upvoteComment(int qIndex, int cIndex) {
    setState(() {
      questions[qIndex]['comments'][cIndex]['upvotes']++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Community Forum 💬'),
        backgroundColor: Colors.deepPurple,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _questionController,
              decoration: InputDecoration(
                labelText: 'Ask a question...'
              ),
              onSubmitted: (_) => _addQuestion(),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _addQuestion,
              icon: const Icon(Icons.send),
              label: const Text('Post Question'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: questions.length,
                itemBuilder: (context, qIndex) {
                  final q = questions[qIndex];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(q['question'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              ),
                              IconButton(
                                icon: const Icon(Icons.thumb_up, color: Colors.deepPurple),
                                onPressed: () => _upvoteQuestion(qIndex),
                              ),
                              Text('${q['upvotes']}'),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ...List.generate(q['comments'].length, (cIndex) {
                            final c = q['comments'][cIndex];
                            return Row(
                              children: [
                                Expanded(child: Text(c['text'])),
                                IconButton(
                                  icon: const Icon(Icons.thumb_up, color: Colors.green),
                                  onPressed: () => _upvoteComment(qIndex, cIndex),
                                ),
                                Text('${c['upvotes']}'),
                              ],
                            );
                          }),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  decoration: const InputDecoration(hintText: 'Add a comment...'),
                                  onSubmitted: (comment) => _addComment(qIndex, comment),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
