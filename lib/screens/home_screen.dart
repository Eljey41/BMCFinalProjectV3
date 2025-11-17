import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ecommerce_app/screens/admin_panel_screen.dart';
import 'package:ecommerce_app/widgets/product_card.dart';
import 'package:ecommerce_app/screens/product_detail_screen.dart'; // ⭐ NEW IMPORT
import 'package:ecommerce_app/providers/cart_provider.dart'; // 1. ADD THIS
import 'package:ecommerce_app/screens/cart_screen.dart'; // 2. ADD THIS
import 'package:provider/provider.dart';
import 'package:ecommerce_app/screens/order_history_screen.dart';
import 'package:ecommerce_app/screens/profile_screen.dart';
import 'package:ecommerce_app/widgets/notification_icon.dart';
import 'package:ecommerce_app/screens/chat_screen.dart';



class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _userRole = 'user';
  final User? _currentUser = FirebaseAuth.instance.currentUser;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _fetchUserRole();
  }

  Future<void> _fetchUserRole() async {
    if (_currentUser == null) return;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUser.uid)
          .get();

      if (doc.exists && doc.data() != null) {
        setState(() {
          _userRole = doc.data()!['role'];
        });
      }
    } catch (e) {
      print("Error fetching user role: $e");
    }
  }
  Future<void> _signOut() async {
    try {
      await FirebaseAuth.instance.signOut();
    } catch (e) {
      print('Error signing out: $e');
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_currentUser != null ? 'Welcome, ${_currentUser.email}' : 'Home'),
        actions: [
          Consumer<CartProvider>(
            // 2. The "builder" function rebuilds *only* the icon
            builder: (context, cart, child) {
              // 3. The "Badge" widget adds a small label
              return Badge(
                // 4. Get the count from the provider
                label: Text(cart.itemCount.toString()),
                // 5. Only show the badge if the count is > 0
                isLabelVisible: cart.itemCount > 0,
                // 6. This is the child (our icon button)
                child: IconButton(
                  icon: const Icon(Icons.shopping_cart),
                  onPressed: () {
                    // 7. Navigate to the CartScreen
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const CartScreen(),
                      ),
                    );
                  },
                ),
              );

            },

          ),

          const   NotificationIcon(),


          IconButton(
            icon: const Icon(Icons.receipt_long), // A "receipt" icon
            tooltip: 'My Orders',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const OrderHistoryScreen(),
                ),
              );
            },
          ),


          if (_userRole == 'admin')
            IconButton(
              icon: const Icon(Icons.admin_panel_settings),
              tooltip: 'Admin Panel',
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const AdminPanelScreen(),
                  ),
                );
              },
            ),

          IconButton(
            icon: const Icon(Icons.person_outline),
            tooltip: 'Profile',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const ProfileScreen(),
                ),
              );
            },
          ),

        ],
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('products')
            .orderBy('createdAt', descending: true)
            .snapshots(),

        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text('No products found. Add some in the Admin Panel!'),
            );
          }

          final products = snapshot.data!.docs;

          return GridView.builder(
            padding: const EdgeInsets.all(10.0),

            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 3 / 4,
            ),

            itemCount: products.length,
            itemBuilder: (context, index) {
              final productDoc = products[index];
              final productData = productDoc.data() as Map<String, dynamic>;

              // ⭐ UPDATED: Added onTap + navigation
              return ProductCard(
                productName: productData['name'],
                price: productData['price'],
                imageUrl: productData['imageUrl'],
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => ProductDetailScreen(
                          productData: productData,   // pass map
                          productId: productDoc.id,   // pass Firestore ID
                        ),
                      ),
                    );
                  },
              );
            },
          );
        },
      ),
      floatingActionButton: _userRole == 'user'
          ? StreamBuilder<DocumentSnapshot>( // 2. A new StreamBuilder
        // 3. Listen to *this user's* chat document
        stream: _firestore.collection('chats').doc(_currentUser!.uid).snapshots(),
        builder: (context, snapshot) {

          int unreadCount = 0;
          // 4. Check if the doc exists and has our count field
          if (snapshot.hasData && snapshot.data!.exists) {
            // Ensure data is not null before casting
            final data = snapshot.data!.data();
            if (data != null) {
              unreadCount = (data as Map<String, dynamic>)['unreadByUserCount'] ?? 0;
            }
          }

          // 5. --- THE FIX for "trailing not defined" ---
          //    We wrap the FAB in the Badge widget
          return Badge(
            // 6. Show the count in the badge
            label: Text('$unreadCount'),
            // 7. Only show the badge if the count is > 0
            isLabelVisible: unreadCount > 0,
            // 8. The FAB is now the *child* of the Badge
            child: FloatingActionButton.extended(
              icon: const Icon(Icons.support_agent),
              label: const Text('Contact Admin'),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => ChatScreen(
                      chatRoomId: _currentUser!.uid,
                    ),
                  ),
                );
              },
            ),
          );
          // --- END OF FIX ---
        },
      ) : null, // 9. If admin, don't show the FAB
    );


  }
}
