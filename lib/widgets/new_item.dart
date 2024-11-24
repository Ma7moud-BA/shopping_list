import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shopping_list/data/categories.dart';
import 'package:shopping_list/models/category.dart';
import 'package:shopping_list/models/grocery_item.dart';
import 'package:http/http.dart' as http;

class NewItem extends StatefulWidget {
  const NewItem({super.key});

  @override
  State<NewItem> createState() {
    return _NewItemState();
  }
}

class _NewItemState extends State<NewItem> {
//   every form should have a GlobalKey, this will add more features to it and gives access to invoke  the validator

  final _formKey = GlobalKey<FormState>();
  var _enteredName = '';
  var _enteredQuantity = 1;
  var _selectedCategory = categories[Categories.vegetables]!;
  var _isSending = false;

  void _saveItem() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      setState(() {
        _isSending = true;
      });
      //  after creating a realtime database in firebase
      final url = Uri.https(
          'flutter-shopping-64b46-default-rtdb.firebaseio.com',
          'shopping-list.json'); // the second argument will create a node {subfolder}in the firebase database with the name provided

      final response = await http.post(
        url,
        headers: {
          "Content-Type": 'application/json',
        },
        body: json.encode(
          {
            'name': _enteredName,
            'category': _selectedCategory.name,
            'quantity': _enteredQuantity
          },
        ),
      );
//  based on firebase official documentation the post method will return a json object
      final Map<String, dynamic> resData = json.decode(response.body);
      if (!context.mounted) {
        return;
      }
      //  flutter can't make sure if the context is still the same since we are using an async function that might be resulting into going to another screen so another context.
      Navigator.of(context).pop(GroceryItem(
          id: resData['name'],
          name: _enteredName,
          category: _selectedCategory,
          quantity: _enteredQuantity));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Add a new item"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                maxLength: 50,
                decoration: const InputDecoration(
                  label: Text("Name"),
                ),
                validator: (value) {
                  if (value == null ||
                      value.isEmpty ||
                      value.trim().length <= 1 ||
                      value.trim().length > 50) {
                    return 'Must be between 1 and 50 characters.';
                  }
                  return null;
                },
                onSaved: (value) {
                  //  we know for certain that the value will be valid because we trigger the onSave after validating the inputs
                  _enteredName = value!;
                },
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  //  the TextFormFiled is not constraint horizontally
                  Expanded(
                    child: TextFormField(
                      keyboardType: TextInputType.number,
                      initialValue: _enteredQuantity.toString(),
                      validator: (value) {
                        // int.tryParse returns null if the value fails to be converted to a number
                        if (value == null ||
                            value.isEmpty ||
                            int.tryParse(value) == null ||
                            int.tryParse(value)! <= 0) {
                          return 'Must be a valid positive number.';
                        }
                        return null;
                      },
                      onSaved: (value) {
                        //  we know for certain that the value will be valid because we trigger the onSave after validating the inputs
                        _enteredQuantity = int.parse(value!);
                      },
                      decoration: const InputDecoration(
                        label: Text("Quantity"),
                      ),
                    ),
                  ),
                  const SizedBox(
                    width: 8,
                  ),
                  //  the DropdownButtonFormField is not constraint horizontally

                  Expanded(
                    child: DropdownButtonFormField(
                        value: _selectedCategory,
                        items: [
                          // categories by it self is a map, and we can;t use for loop on a map, so we should use the .entries method to return a list that contains a key value pair of that map as items
                          for (final category in categories.entries)
                            DropdownMenuItem(
                              value: category.value,
                              child: Row(
                                children: [
                                  Container(
                                      width: 16,
                                      height: 16,
                                      color: category.value.color),
                                  const SizedBox(
                                    width: 6,
                                  ),
                                  Text(category.value.name)
                                ],
                              ),
                            )
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedCategory = value!;
                          });
                        }),
                  )
                ],
              ),
              const SizedBox(
                height: 12,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    //  passing null to a button will disable it.
                    onPressed: _isSending
                        ? null
                        : () {
                            _formKey.currentState!.reset();
                          },
                    child: const Text('Reset'),
                  ),
                  ElevatedButton(
                    onPressed: _isSending ? null : _saveItem,
                    child: _isSending
                        ? const SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(),
                          )
                        : const Text('Add Item'),
                  )
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
