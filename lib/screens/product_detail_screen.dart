import 'package:flutter/material.dart';
import 'package:ecommerce_app/providers/cart_provider.dart'; // 1. ADD THIS
import 'package:provider/provider.dart';


class ProductDetailScreen extends StatefulWidget  {
  final Map<String, dynamic> productData;  // Product info map
  final String productId;                 // Firestore document ID

  const ProductDetailScreen({
    super.key,
    required this.productData,
    required this.productId,
  });

  @override
  // 2. Create the State class
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}


class _ProductDetailScreenState extends State<ProductDetailScreen> {

  // 4. ADD OUR NEW STATE VARIABLE FOR QUANTITY
  int _quantity = 1;

  void _incrementQuantity() {
    setState(() {
      _quantity++;
    });
  }

  // 2. ADD THIS FUNCTION
  void _decrementQuantity() {
    // We don't want to go below 1
    if (_quantity > 1) {
      setState(() {
        _quantity--;
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    // Extract product data
    final String name = widget.productData['name'];
    final String description = widget.productData['description'];
    final String imageUrl = widget.productData['imageUrl'];
    final double price = widget.productData['price'];

    // 2. Get the CartProvider (same as before)
    final cart = Provider.of<CartProvider>(context, listen: false);



    return Scaffold(
      appBar: AppBar(
        title: Text(name),
      ),

      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [

            // Large product image
            Image.network(
              imageUrl,
              height: 300,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return const SizedBox(
                  height: 300,
                  child: Center(child: CircularProgressIndicator()),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                return const SizedBox(
                  height: 300,
                  child: Center(
                    child: Icon(Icons.broken_image, size: 100),
                  ),
                );
              },
            ),

            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // Product Name
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Price
                  Text(
                    '₱${price.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: Colors.deepPurple,
                    ),
                  ),
                  const SizedBox(height: 16),

                  const Divider(thickness: 1),
                  const SizedBox(height: 16),

                  // Section Title
                  Text(
                    'About this item',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),

                  // Description
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 16,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 30),

                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // 5. DECREMENT BUTTON
                      IconButton.filledTonal(
                        icon: const Icon(Icons.remove),
                        onPressed: _decrementQuantity,
                      ),

                      // 6. QUANTITY DISPLAY
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Text(
                          '$_quantity', // 7. Display our state variable
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                      ),

                      // 8. INCREMENT BUTTON
                      IconButton.filled(
                        icon: const Icon(Icons.add),
                        onPressed: _incrementQuantity,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),


                  // Add to Cart Button (UI only for now)
                  ElevatedButton.icon(
                    onPressed: () {
                      cart.addItem(
                        widget.productId,
                        name,
                        price,
                        _quantity, // 11. Pass the selected quantity
                      );


                      // 5. Show a confirmation pop-up
                      ScaffoldMessenger.of(context).showSnackBar(
                         SnackBar(
                          content: Text('Added $_quantity x $name to cart!'),
                          duration: Duration(seconds: 2),
                        ),
                      );

                    },
                    icon: const Icon(Icons.shopping_cart_outlined),
                    label: const Text('Add to Cart'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      textStyle: const TextStyle(fontSize: 18),
                    ),
                  ),
                ],
              ),
            ),

          ],
        ),
      ),
    );
  }
}
