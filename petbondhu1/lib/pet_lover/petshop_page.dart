import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class PetShopPage extends StatefulWidget {
  const PetShopPage({super.key});

  @override
  State<PetShopPage> createState() => _PetShopPageState();
}

class _PetShopPageState extends State<PetShopPage> {
  // Controllers for add-product form
  final TextEditingController _shopOwnerCtrl = TextEditingController();
  final TextEditingController _shopProductCtrl = TextEditingController();
  final TextEditingController _shopDescCtrl = TextEditingController();
  final TextEditingController _shopContactCtrl = TextEditingController();

  final _shopFormKey = GlobalKey<FormState>();
  String? _pickedShopImageBase64;
  bool _saving = false;

  // 0 = listing, 1 = add product form
  int _viewIndex = 0;

  Future<void> _pickShopImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? file = await picker.pickImage(source: ImageSource.gallery, maxWidth: 1200, maxHeight: 1200, imageQuality: 80);
      if (file == null) return;
      final bytes = await file.readAsBytes();
      final b64 = base64Encode(bytes);
      setState(() {
        _pickedShopImageBase64 = 'data:image;base64,$b64';
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Image pick failed: $e')));
    }
  }

  Future<void> _addShopProduct() async {
    if (!(_shopFormKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    try {
      await FirebaseFirestore.instance.collection('product').add({
        'owner': _shopOwnerCtrl.text.trim(),
        'product': _shopProductCtrl.text.trim(),
        'description': _shopDescCtrl.text.trim(),
        'picture': _pickedShopImageBase64 ?? '',
        'contact': _shopContactCtrl.text.trim(),
        'status': 'available',
        'date': FieldValue.serverTimestamp(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Product listed')));
        setState(() {
          _shopOwnerCtrl.clear();
          _shopProductCtrl.clear();
          _shopDescCtrl.clear();
          _shopContactCtrl.clear();
          _pickedShopImageBase64 = null;
          _viewIndex = 0; // go back to listings after save
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error saving product: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _updateProductStatus(DocumentReference ref, String status) async {
    try {
      await ref.update({
        'status': status,
        'statusUpdatedAt': FieldValue.serverTimestamp(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(status == 'sold' ? 'Marked as sold' : 'Marked as available')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to update status: $e')));
      }
    }
  }

  Widget _shopPreview() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: 72,
                height: 72,
                color: Colors.grey.shade100,
                child: _buildImageFromString(_pickedShopImageBase64, width: 72, height: 72),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _shopProductCtrl.text.isEmpty ? 'Product name' : _shopProductCtrl.text,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _shopDescCtrl.text.isEmpty ? 'Product description' : _shopDescCtrl.text,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _shopListings() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('product').orderBy('date', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) return const Center(child: Text('No products yet.'));
        return ListView.separated(
          itemCount: docs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data() as Map<String, dynamic>;
            final picture = (data['picture'] ?? '').toString();
            final productName = (data['product'] ?? '').toString();
            final owner = (data['owner'] ?? '').toString();
            final desc = (data['description'] ?? '').toString();
            final contact = (data['contact'] ?? '').toString();
            final ts = data['date'];
            final dateStr = ts is Timestamp ? ts.toDate().toString() : ts?.toString() ?? '';
            final status = (data['status'] ?? 'available').toString();

            Color chipColor;
            String chipLabel;
            switch (status) {
              case 'sold':
                chipColor = Colors.redAccent;
                chipLabel = 'Sold';
                break;
              default:
                chipColor = Colors.green;
                chipLabel = 'Available';
            }

            return Card(
              margin: const EdgeInsets.symmetric(vertical: 6),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        width: 56,
                        height: 56,
                        color: Colors.grey.shade100,
                        child: _buildImageFromString(picture, width: 56, height: 56),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(productName, style: const TextStyle(fontWeight: FontWeight.w600)),
                          const SizedBox(height: 4),
                          Text(desc, maxLines: 2, overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Chip(
                                label: Text(chipLabel),
                                backgroundColor: chipColor.withOpacity(0.15),
                                labelStyle: TextStyle(color: chipColor, fontWeight: FontWeight.w600),
                                side: BorderSide(color: chipColor.withOpacity(0.3)),
                                visualDensity: VisualDensity.compact,
                              ),
                              Text('by $owner', style: const TextStyle(fontSize: 12, color: Colors.black87)),
                              Text(dateStr, style: const TextStyle(fontSize: 12, color: Colors.black54)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              ElevatedButton.icon(
                                onPressed: () => _showContactDialog(contact),
                                icon: const Icon(Icons.call, size: 18),
                                label: const Text('Contact'),
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.deepOrange),
                              ),
                              OutlinedButton.icon(
                                onPressed: () => _updateProductStatus(doc.reference, status == 'sold' ? 'available' : 'sold'),
                                icon: Icon(status == 'sold' ? Icons.undo : Icons.sell_outlined, size: 18),
                                label: Text(status == 'sold' ? 'Mark Available' : 'Mark Sold'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showContactDialog(String contact) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Contact'),
        content: Text(contact.isEmpty ? 'No contact provided' : contact),
        actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Close'))],
      ),
    );
  }

  Widget _buildImageFromString(String? imageStr, {double? width, double? height}) {
    if (imageStr == null || imageStr.isEmpty) return const Icon(Icons.pets, size: 40, color: Colors.teal);
    try {
      if (imageStr.startsWith('data:image')) {
        final comma = imageStr.indexOf(',');
        final payload = comma >= 0 ? imageStr.substring(comma + 1) : imageStr;
        final bytes = base64Decode(payload);
        return Image.memory(bytes, width: width, height: height, fit: BoxFit.cover);
      }
      if (imageStr.startsWith('http') || imageStr.startsWith('https')) {
        return Image.network(imageStr, width: width, height: height, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.pets, size: 40, color: Colors.teal));
      }
      if (imageStr.length > 100) {
        final bytes = base64Decode(imageStr);
        return Image.memory(bytes, width: width, height: height, fit: BoxFit.cover);
      }
    } catch (_) {
      return const Icon(Icons.pets, size: 40, color: Colors.teal);
    }
    return const Icon(Icons.pets, size: 40, color: Colors.teal);
  }

  @override
  void dispose() {
    _shopOwnerCtrl.dispose();
    _shopProductCtrl.dispose();
    _shopDescCtrl.dispose();
    _shopContactCtrl.dispose();
    super.dispose();
  }

  Widget _buildFormView(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('List a Product', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          Form(
            key: _shopFormKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _shopOwnerCtrl,
                  decoration: const InputDecoration(labelText: 'Shop Owner Name'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter owner name' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _shopProductCtrl,
                  decoration: const InputDecoration(labelText: 'Product Name'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter product name' : null,
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _shopDescCtrl,
                  decoration: const InputDecoration(labelText: 'Description'),
                  maxLines: 3,
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _shopContactCtrl,
                  decoration: const InputDecoration(labelText: 'Contact Number'),
                  keyboardType: TextInputType.phone,
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter contact' : null,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _pickShopImage,
                        icon: const Icon(Icons.photo_library),
                        label: const Text('Choose Image'),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.blueGrey),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (_pickedShopImageBase64 != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: double.infinity,
                      height: 160,
                      color: Colors.grey.shade100,
                      child: _buildImageFromString(_pickedShopImageBase64, width: double.infinity, height: 160),
                    ),
                  ),
                const SizedBox(height: 16),
                _shopPreview(),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _saving ? null : _addShopProduct,
                    icon: const Icon(Icons.add_business),
                    label: Text(_saving ? 'Saving...' : 'List Product'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.deepOrange),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pet Shop'),
        backgroundColor: Colors.orange,
      ),
      body: Column(
        children: [
          // Toggle buttons row
            Padding(
              padding: const EdgeInsets.fromLTRB(12,12,12,0),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _viewIndex == 0 ? null : () => setState(() => _viewIndex = 0),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _viewIndex == 0 ? Colors.deepOrange : Colors.grey.shade300,
                        foregroundColor: _viewIndex == 0 ? Colors.white : Colors.black87,
                      ),
                      child: const Text('Available Products'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _viewIndex == 1 ? null : () => setState(() => _viewIndex = 1),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _viewIndex == 1 ? Colors.blueGrey : Colors.grey.shade300,
                        foregroundColor: _viewIndex == 1 ? Colors.white : Colors.black87,
                      ),
                      child: const Text('List Product'),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 8),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (child, anim) => FadeTransition(opacity: anim, child: child),
              child: _viewIndex == 0
                  ? Padding(
                      key: const ValueKey('listing'),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: _shopListings(),
                    )
                  : Container(
                      key: const ValueKey('form'),
                      color: Colors.white,
                      child: _buildFormView(context),
                    ),
            ),
          ),
        ],
      ),
      floatingActionButton: _viewIndex == 0
          ? FloatingActionButton(
              backgroundColor: Colors.deepOrange,
              onPressed: () => setState(() => _viewIndex = 1),
              tooltip: 'List Product',
              child: const Icon(Icons.add_business),
            )
          : null,
    );
  }
}
