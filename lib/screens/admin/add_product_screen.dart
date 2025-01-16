import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key});

  @override
  _AddProductScreenState createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedCategory;
  String _productName = '';
  String _description = '';
  double? _price;
  File? _imageFile;
  String? _imageUrl;

  List<String> _categories = [];

  @override
  void initState() {
    super.initState();
    _fetchCategories();
  }

  Future<void> _fetchCategories() async {
    final querySnapshot =
        await FirebaseFirestore.instance.collection('categories').get();
    setState(() {
      _categories =
          querySnapshot.docs.map((doc) => doc['name'].toString()).toList();
    });
  }

  Future<void> _pickImage() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _uploadImage() async {
    if (_imageFile == null) return;
    final storageRef = FirebaseStorage.instance.ref();
    final fileName = DateTime.now().millisecondsSinceEpoch.toString();
    final imageRef = storageRef.child('products/$fileName');

    await imageRef.putFile(_imageFile!);
    final url = await imageRef.getDownloadURL();
    setState(() {
      _imageUrl = url;
    });
  }

  Future<void> _saveProduct() async {
    if (_formKey.currentState!.validate() && _imageUrl != null) {
      _formKey.currentState!.save();
      final product = {
        'categoryId': _selectedCategory,
        'name': _productName,
        'description': _description,
        'price': _price,
        'imageUrl': _imageUrl,
        'createdAt': Timestamp.now(),
      };

      await FirebaseFirestore.instance.collection('products').add(product);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Produkt erfolgreich hinzugefügt!')),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Bitte füllen Sie alle Felder aus und laden Sie ein Bild hoch.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Neues Produkt hinzufügen'),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () {
              // Add help functionality here.
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Category'),
                  value: _selectedCategory,
                  items: _categories.map((category) {
                    return DropdownMenuItem(
                      value: category,
                      child: Text(category),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedCategory = value;
                    });
                  },
                  validator: (value) => value == null
                      ? 'Bitte wählen Sie eine Kategorie aus'
                      : null,
                ),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Produktname'),
                  onSaved: (value) => _productName = value!,
                  validator: (value) => value!.isEmpty
                      ? 'Bitte geben Sie einen Produktnamen ein'
                      : null,
                ),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Beschreibung'),
                  maxLines: 3,
                  onSaved: (value) => _description = value!,
                  validator: (value) => value!.isEmpty
                      ? 'Bitte geben Sie eine Beschreibung ein'
                      : null,
                ),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Preis (€)'),
                  keyboardType: TextInputType.number,
                  onSaved: (value) => _price = double.tryParse(value!),
                  validator: (value) =>
                      value == null || double.tryParse(value) == null
                          ? 'Bitte geben Sie einen gültigen Preis ein'
                          : null,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    ElevatedButton(
                      onPressed: _pickImage,
                      child: const Text('Bild hochladen'),
                    ),
                    const SizedBox(width: 16),
                    if (_imageFile != null)
                      Image.file(
                        _imageFile!,
                        width: 100,
                        height: 100,
                        fit: BoxFit.cover,
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () async {
                    await _uploadImage();
                    _saveProduct();
                  },
                  child: const Text('Produkt speichern'),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Abbrechen'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
