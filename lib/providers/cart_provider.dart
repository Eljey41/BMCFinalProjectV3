import 'dart:async';                       // For StreamSubscription
import 'package:flutter/foundation.dart';  // For ChangeNotifier
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


// ===========================================================
// PART 1 — CartItem Model with toJson / fromJson
// ===========================================================
class CartItem {
  final String id;
  final String name;
  final double price;
  int quantity;

  CartItem({
    required this.id,
    required this.name,
    required this.price,
    this.quantity = 1,
  });

  // Convert object → JSON (Map)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'quantity': quantity,
    };
  }

  // Convert JSON (Map) → object
  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      id: json['id'],
      name: json['name'],
      price: json['price'],
      quantity: json['quantity'],
    );
  }
}



// ===========================================================
// PART 2 — CartProvider (The Brain)
// ===========================================================
class CartProvider with ChangeNotifier {

  // Local cart items (not final because Firestore overwrites them)
  List<CartItem> _items = [];

  // Firebase tracking
  String? _userId;
  StreamSubscription? _authSubscription;

  // Firebase instances
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;



  // ===========================================================
  // Getters
  // ===========================================================
  List<CartItem> get items => _items;

  int get itemCount {
    int total = 0;
    for (var item in _items) {
      total += item.quantity;
    }
    return total;
  }

  double get totalPrice {
    double total = 0.0;
    for (var item in _items) {
      total += item.price * item.quantity;
    }
    return total;
  }



  // ===========================================================
  // Constructor — listens to login/logout changes
  // ===========================================================
  CartProvider() {
    print("CartProvider initialized");

    _authSubscription = _auth.authStateChanges().listen((User? user) {
      if (user == null) {
        // Logged out
        print("User logged out → clearing cart");
        _userId = null;
        _items = [];
      } else {
        // Logged in
        print("User logged in: ${user.uid} → fetching cart...");
        _userId = user.uid;
        _fetchCart();
      }
      notifyListeners();
    });
  }



  // ===========================================================
  // Load user's saved cart from Firestore
  // ===========================================================
  Future<void> _fetchCart() async {
    if (_userId == null) return;

    try {
      final doc = await _firestore.collection('userCarts').doc(_userId).get();

      if (doc.exists && doc.data()!['cartItems'] != null) {
        List<dynamic> cartData = doc.data()!['cartItems'];

        // Convert each Map → CartItem
        _items = cartData
            .map((jsonItem) => CartItem.fromJson(jsonItem))
            .toList();

        print("Cart fetched: ${_items.length} items");
      } else {
        _items = [];
      }

    } catch (e) {
      print("Error fetching cart: $e");
      _items = [];
    }

    notifyListeners();
  }



  // ===========================================================
  // Save local cart → Firestore
  // ===========================================================
  Future<void> _saveCart() async {
    if (_userId == null) return;

    try {
      final cartData = _items.map((item) => item.toJson()).toList();

      await _firestore.collection('userCarts').doc(_userId).set({
        'cartItems': cartData,
      });

      print("Cart saved to Firestore");

    } catch (e) {
      print("Error saving cart: $e");
    }
  }



  // ===========================================================
  // Add Item To Cart
  // ===========================================================
  void addItem(String id, String name, double price) {
    var index = _items.indexWhere((item) => item.id == id);

    if (index != -1) {
      _items[index].quantity++;
    } else {
      _items.add(CartItem(id: id, name: name, price: price));
    }

    _saveCart();   // Sync changes to Firestore
    notifyListeners();
  }



  // ===========================================================
  // Remove Item From Cart
  // ===========================================================
  void removeItem(String id) {
    _items.removeWhere((item) => item.id == id);

    _saveCart();   // Sync changes to Firestore
    notifyListeners();
  }

  Future<void> placeOrder() async {
    // 2. Check if we have a user and items
    if (_userId == null || _items.isEmpty) {
      // Don't place an order if cart is empty or user is logged out
      throw Exception('Cart is empty or user is not logged in.');
    }

    try {
      // 3. Convert our List<CartItem> to a List<Map> using toJson()
      final List<Map<String, dynamic>> cartData =
      _items.map((item) => item.toJson()).toList();

      // 4. Get total price and item count from our getters
      final double total = totalPrice;
      final int count = itemCount;

      // 5. Create a new document in the 'orders' collection
      await _firestore.collection('orders').add({
        'userId': _userId,
        'items': cartData, // Our list of item maps
        'totalPrice': total,
        'itemCount': count,
        'status': 'Pending', // 6. IMPORTANT: For admin verification
        'createdAt': FieldValue.serverTimestamp(), // For sorting
      });

      // 7. Note: We DO NOT clear the cart here.
      //    We'll call clearCart() separately from the UI after this succeeds.

    } catch (e) {
      print('Error placing order: $e');
      // 8. Re-throw the error so the UI can catch it
      throw e;
    }
  }


  Future<void> clearCart() async {
    // 10. Clear the local list
    _items = [];

    // 11. If logged in, clear the Firestore cart as well
    if (_userId != null) {
      try {
        // 12. Set the 'cartItems' field in their cart doc to an empty list
        await _firestore.collection('userCarts').doc(_userId).set({
          'cartItems': [],
        });
        print('Firestore cart cleared.');
      } catch (e) {
        print('Error clearing Firestore cart: $e');
      }
    }

    // 13. Notify all listeners (this will clear the UI)
    notifyListeners();
  }





  // ===========================================================
  // Dispose — stop auth listener
  // ===========================================================
  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}
