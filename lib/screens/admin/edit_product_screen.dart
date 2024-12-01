import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class EditProductScreen extends StatefulWidget {
  final String productId;
  final Map<String, dynamic> productData;

  const EditProductScreen({
    super.key,
    required this.productId,
    required this.productData,
  });

  @override
  EditProductScreenState createState() => EditProductScreenState();
}

class EditProductScreenState extends State<EditProductScreen> {
  final _formKey = GlobalKey<FormState>();
  late String _name;
  late double _price;
  File? _imageFile;
  late String _imageUrl;

  @override
  void initState() {
    super.initState();
    _name = widget.productData['name'] ?? '';
    _price = (widget.productData['price'] ?? 0).toDouble();
    _imageUrl = widget.productData['image'] ?? '';
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _updateProduct() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      String imageUrl = _imageUrl;

      if (_imageFile != null) {
        // Upload new image to Firebase Storage
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('products/${DateTime.now().toIso8601String()}');
        await storageRef.putFile(_imageFile!);
        imageUrl = await storageRef.getDownloadURL();
      }

      // Update product in Firestore
      await FirebaseFirestore.instance
          .collection('products')
          .doc(widget.productId)
          .update({
        'name': _name,
        'price': _price,
        'image': imageUrl,
      });

      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Product'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                initialValue: _name,
                decoration: const InputDecoration(labelText: 'Product Name'),
                validator: (value) =>
                    value!.isEmpty ? 'Enter a product name' : null,
                onSaved: (value) => _name = value!,
              ),
              TextFormField(
                initialValue: _price.toString(),
                decoration: const InputDecoration(labelText: 'Price'),
                keyboardType: TextInputType.number,
                validator: (value) => value!.isEmpty ? 'Enter a price' : null,
                onSaved: (value) => _price = double.parse(value!),
              ),
              const SizedBox(height: 16),
              _imageFile == null
                  ? (_imageUrl.isNotEmpty
                      ? Image.network(_imageUrl, height: 200, fit: BoxFit.cover)
                      : const Placeholder(fallbackHeight: 200))
                  : Image.file(_imageFile!, height: 200, fit: BoxFit.cover),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                icon: const Icon(Icons.image),
                label: const Text('Change Image'),
                onPressed: _pickImage,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _updateProduct,
                child: const Text('Update Product'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
