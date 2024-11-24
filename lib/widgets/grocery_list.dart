// import 'package:shopping_list/data/categories.dart';
// import 'package:shopping_list/data/dummy_items.dart';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shopping_list/data/categories.dart';
import 'package:shopping_list/models/category.dart';
import 'package:shopping_list/models/grocery_item.dart';
import 'package:shopping_list/widgets/new_item.dart';
import 'package:http/http.dart' as http;

class GroceryList extends StatefulWidget {
  const GroceryList({super.key});

  @override
  State<GroceryList> createState() => _GroceryListState();
}

class _GroceryListState extends State<GroceryList> {
  List<GroceryItem> _groceryItems = [];
  bool _isLoading = true;
  String? _error;
  @override
  void initState() {
    super.initState();

    _loadItems();
  }

  void _loadItems() async {
    final url = Uri.https('flutter-shopping-64b46-default-rtdb.firebaseio.com',
        'shopping-list.json'); // the second argument will create a node {subfolder}in the firebase database with the name provided

    try {
      final response = await http.get(url);

      if (response.statusCode >= 400) {
        setState(() {
          _error = "Failed to fetch the Data, please try again later";
        });
      }

      // if the body was empty it will send a null as string
      if (response.body == 'null') {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final Map<String, dynamic> listData = json.decode(response.body);
      final List<GroceryItem> loadedItems = [];
      for (final item in listData.entries) {
        final category = categories.entries
            .firstWhere((categoryItem) =>
                categoryItem.value.name == item.value['category'])
            .value;
        loadedItems.add(
          GroceryItem(
            id: item.key,
            name: item.value['name'],
            category: category,
            quantity: item.value['quantity'],
          ),
        );
      }
      setState(() {
        _groceryItems = loadedItems;
        _isLoading = false;
      });
    } catch (err) {
      setState(() {
        _error = "Something Went Wrong, please try again later";
      });
    }
  }

  void _addItem() async {
    final newItem = await Navigator.of(context).push<GroceryItem>(
      MaterialPageRoute(
        builder: (ctx) => const NewItem(),
      ),
    );
    if (newItem == null) {
      return;
    }
    setState(() {
      _groceryItems.add(newItem);
    });

    // we should not fetch the data again when getting back from the add new item screen since we already have the response from the post method there so we use the Navigator features to add it instantly since we know that the post method succeeded.
    // _loadItems();
  }

  void _removeGroceryItem(GroceryItem groceryItem) async {
    final indexOfGItem = _groceryItems.indexOf(groceryItem);

    // final groceryItemIndex = _groceryItems.indexOf(groceryItem);

    setState(
      () {
        _groceryItems.remove(groceryItem);
      },
    );

    final url = Uri.https('flutter-shopping-64b46-default-rtdb.firebaseio.com',
        'shopping-list/${groceryItem.id}.json'); // the second argument will create a node {subfolder}in the firebase database with the name provided
    final res = await http.delete(url);

    if (res.statusCode >= 400) {
      //   if something went wrong with the deletion the item will come back.
      setState(
        () {
          _groceryItems.insert(indexOfGItem, groceryItem);
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget content = const Center(
      child: Text(
        'You got no hoes',
        style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
      ),
    );

    if (_isLoading) {
      content = const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      content = Center(
          child: Text(
        _error!,
        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
      ));
    }

    if (_groceryItems.isNotEmpty) {
      content = ListView.builder(
        itemBuilder: (ctx, index) => Dismissible(
          key: ValueKey(_groceryItems[index].id),
          child: ListTile(
            title: Text(_groceryItems[index].name),
            leading: Container(
              decoration:
                  BoxDecoration(color: _groceryItems[index].category.color),
              child: const SizedBox(
                height: 24,
                width: 24,
              ),
            ),
            trailing: Text(
              _groceryItems[index].quantity.toString(),
            ),
          ),
          onDismissed: (direction) {
            _removeGroceryItem(_groceryItems[index]);
          },
        ),
        itemCount: _groceryItems.length,
      );
    }
    return Scaffold(
        appBar: AppBar(
          title: const Text('Your Groceries'),
          actions: [
            IconButton(
              onPressed: _addItem,
              icon: const Icon(Icons.add),
            )
          ],
        ),
        body: content);
  }
}
