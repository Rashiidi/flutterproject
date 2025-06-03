import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:typed_data';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final displayNameCtrl = TextEditingController();
  XFile? _pickedImage;
  bool _uploading = false;
  String? _profileImageUrl;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    final data = doc.data();
    displayNameCtrl.text = data?['displayName'] ?? '';
    setState(() {
      _profileImageUrl = data?['profileImageUrl'];
    });
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked != null) {
      setState(() {
        _pickedImage = picked;
      });
    }
  }

  Future<String?> _uploadProfileImage() async {
    if (_pickedImage == null) return _profileImageUrl;
    setState(() => _uploading = true);
    final ref = FirebaseStorage.instance
        .ref()
        .child('profile_images')
        .child('${FirebaseAuth.instance.currentUser!.uid}_${DateTime.now().millisecondsSinceEpoch}');
    if (kIsWeb) {
      final bytes = await _pickedImage!.readAsBytes();
      await ref.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
    } else {
      await ref.putFile(File(_pickedImage!.path));
    }
    final url = await ref.getDownloadURL();
    setState(() => _uploading = false);
    return url;
  }

  Widget _imagePreview() {
    if (_pickedImage != null) {
      if (kIsWeb) {
        return FutureBuilder<Uint8List>(
          future: _pickedImage!.readAsBytes(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const CircularProgressIndicator();
            return CircleAvatar(
              radius: 48,
              backgroundImage: MemoryImage(snapshot.data!),
            );
          },
        );
      } else {
        return CircleAvatar(
          radius: 48,
          backgroundImage: FileImage(File(_pickedImage!.path)),
        );
      }
    } else if (_profileImageUrl != null && _profileImageUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: 48,
        backgroundImage: NetworkImage(_profileImageUrl!),
      );
    } else {
      return const CircleAvatar(
        radius: 48,
        child: Icon(Icons.person, size: 48),
      );
    }
  }

  Future<void> _saveProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final imageUrl = await _uploadProfileImage();
    await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
      'displayName': displayNameCtrl.text,
      'profileImageUrl': imageUrl,
    });
    if (user.displayName != displayNameCtrl.text) {
      await user.updateDisplayName(displayNameCtrl.text);
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: ListView(
          children: [
            Center(
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  _imagePreview(),
                  Positioned(
                    child: IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      onPressed: _pickImage,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: displayNameCtrl,
              decoration: const InputDecoration(labelText: 'Display Name'),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _uploading ? null : _saveProfile,
              child: _uploading
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save Changes'),
            ),
          ],
        ),
      ),
    );
  }
}