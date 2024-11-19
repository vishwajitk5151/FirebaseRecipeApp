import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PostScreen extends StatefulWidget {
  @override
  State createState() => _PostScreenState();
}

class _PostScreenState extends State<PostScreen> {
  String userName = '';
  TextEditingController titleController = TextEditingController();
  TextEditingController ingredientController = TextEditingController();
  TextEditingController procedureController = TextEditingController();
  TextEditingController timeController = TextEditingController(); // Time input controller

  List<String> ingredients = [];
  List<String> procedures = [];
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      userName = currentUser.email!;
    }
  }

  void addIngredient() {
    String ingredient = ingredientController.text.trim();
    if (ingredient.isNotEmpty) {
      setState(() {
        ingredients.add(ingredient);
        ingredientController.clear();
      });
    }
  }

  void addProcedure() {
    String procedure = procedureController.text.trim();
    if (procedure.isNotEmpty) {
      setState(() {
        procedures.add(procedure);
        procedureController.clear();
      });
    }
  }

  Future<void> pickImage(ImageSource source) async {
    final XFile? pickedFile = await _picker.pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<void> uploadDataToFirestore() async {
    try {
      final title = titleController.text.trim();
      final time = timeController.text.trim();
      if (title.isEmpty || time.isEmpty || ingredients.isEmpty || procedures.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please fill all fields')),
        );
        return;
      }

      String imageURL = _selectedImage != null
          ? "https://your-placeholder-url.com/${_selectedImage!.path.split('/').last}"
          : "https://via.placeholder.com/200";

      await FirebaseFirestore.instance.collection('posts').add({
        'title': title,
        'time': time,
        'ingredients': ingredients,
        'procedures': procedures,
        'imageURL': imageURL,
        'userEmail': userName,
        'timestamp': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Recipe added successfully')),
      );

      setState(() {
        titleController.clear();
        timeController.clear();
        ingredients.clear();
        procedures.clear();
        _selectedImage = null;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add recipe: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white60,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                Row(
                  children: [
                    const Spacer(),
                    const Text(
                      "Add Post",
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: uploadDataToFirestore,
                      child: const Text(
                        "Post",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Recipe Title
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Recipe Title",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: titleController,
                  decoration: InputDecoration(
                    hintText: "Enter title of recipe",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Preparation Time
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Preparation Time (in minutes)",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: timeController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: "Enter preparation time",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Recipe Image
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Recipe Image",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 10),
                _selectedImage != null
                    ? Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.green, width: 3),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.file(
                            _selectedImage!,
                            height: 200,
                            width: double.infinity,
                            fit: BoxFit.fitWidth,
                          ),
                        ),
                      )
                    : TextButton.icon(
                        onPressed: () {
                          showModalBottomSheet(
                            context: context,
                            builder: (context) => Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ListTile(
                                  leading: const Icon(Icons.photo),
                                  title: const Text("Gallery"),
                                  onTap: () {
                                    Navigator.of(context).pop();
                                    pickImage(ImageSource.gallery);
                                  },
                                ),
                                ListTile(
                                  leading: const Icon(Icons.camera_alt),
                                  title: const Text("Camera"),
                                  onTap: () {
                                    Navigator.of(context).pop();
                                    pickImage(ImageSource.camera);
                                  },
                                ),
                              ],
                            ),
                          );
                        },
                        icon: const Icon(Icons.image),
                        label: const Text("Pick an Image"),
                      ),
                const SizedBox(height: 20),

                // Ingredients
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Ingredients",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: ingredientController,
                  decoration: InputDecoration(
                    hintText: "Add Ingredients",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: addIngredient,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  children: ingredients
                      .map((ingredient) => Chip(
                            label: Text(ingredient),
                          ))
                      .toList(),
                ),
                const SizedBox(height: 20),

                // Procedures
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Procedures",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: procedureController,
                  decoration: InputDecoration(
                    hintText: "Add Procedure",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: addProcedure,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  children: procedures
                      .map((procedure) => Chip(
                            label: Text(procedure),
                          ))
                      .toList(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
