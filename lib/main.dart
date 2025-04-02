// Import Flutter package
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(InventoryApp());
}

class InventoryApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Inventory Management App',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: InventoryHomePage(title: 'Inventory Home Page'),
    );
  }
}

class InventoryHomePage extends StatefulWidget {
  InventoryHomePage({Key? key, required this.title}) : super(key: key);
  final String title;

  @override
  _InventoryHomePageState createState() => _InventoryHomePageState();
}

class _InventoryHomePageState extends State<InventoryHomePage> {
  final CollectionReference itemsCollection =
      FirebaseFirestore.instance.collection('items');

  void _showProductDialog({String? id, String name = '', double price = 0.0}) {
    TextEditingController nameController = TextEditingController(text: name);
    TextEditingController priceController = TextEditingController(
        text: price > 0 ? price.toString() : '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(id == null ? 'Add Product' : 'Update Product'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(hintText: 'Enter product name'),
            ),
            TextField(
              controller: priceController,
              decoration: InputDecoration(hintText: 'Enter product price'),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel')),
          TextButton(
            onPressed: () {
              if (nameController.text.isNotEmpty && priceController.text.isNotEmpty) {
                final productData = {
                  'Name': nameController.text,
                  'Price': double.tryParse(priceController.text) ?? 0.0,
                };
                id == null ? itemsCollection.add(productData) : itemsCollection.doc(id).update(productData);
              }
              Navigator.pop(context);
            },
            child: Text(id == null ? 'Add' : 'Update'),
          ),
        ],
      ),
    );
  }

  void _deleteProduct(String id) {
    itemsCollection.doc(id).delete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: StreamBuilder(
        stream: itemsCollection.snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (!snapshot.hasData) return Center(child: CircularProgressIndicator());
          return ListView(
            children: snapshot.data!.docs.map((doc) {
              return ListTile(
                title: Text(doc['Name']),
                subtitle: Text('Price: \$${doc['Price']}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(Icons.edit),
                      onPressed: () => _showProductDialog(
                        id: doc.id,
                        name: doc['Name'],
                        price: doc['Price'],
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.delete),
                      onPressed: () => _deleteProduct(doc.id),
                    ),
                  ],
                ),
              );
            }).toList(),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showProductDialog(),
        tooltip: 'Add Item',
        child: Icon(Icons.add),
      ),
    );
  }
}
