import 'package:ecommerce_app/providers/cart_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ecommerce_app/screens/order_success_screen.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  // 3. Create the State
  State<CartScreen> createState() => _CartScreenState();
}
class _CartScreenState extends State<CartScreen> {

  // 5. Add our loading state variable
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    // Get the cart provider (listens for changes)
    final cart = Provider.of<CartProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Cart'),
      ),

      body: Column(
        children: [
          // ITEM LIST
          Expanded(
            child: cart.items.isEmpty
                ? const Center(
              child: Text(
                'Your cart is empty.',
                style: TextStyle(fontSize: 18),
              ),
            )
                : ListView.builder(
              itemCount: cart.items.length,
              itemBuilder: (context, index) {
                final cartItem = cart.items[index];

                return ListTile(
                  leading: CircleAvatar(
                    child: Text(
                      cartItem.name[0].toUpperCase(),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  title: Text(
                    cartItem.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    'Qty: ${cartItem.quantity}',
                    style: const TextStyle(fontSize: 14),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // ITEM TOTAL PRICE
                      Text(
                        '₱${(cartItem.price * cartItem.quantity).toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),

                      const SizedBox(width: 10),

                      // DELETE ICON
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          cart.removeItem(cartItem.id);

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('${cartItem.name} removed.'),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50), // Wide button
              ),

              // 5. Disable button if loading OR if cart is empty
              onPressed: (_isLoading || cart.items.isEmpty) ? null : () async {
                // 6. Start the loading spinner
                setState(() {
                  _isLoading = true;
                });

                try {
                  // 7. Get provider (listen: false is for functions)
                  final cartProvider = Provider.of<CartProvider>(context, listen: false);

                  // 8. Call our new methods
                  await cartProvider.placeOrder();
                  await cartProvider.clearCart();

                  // 9. Navigate to success screen
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => const OrderSuccessScreen()),
                        (route) => false,
                  );

                } catch (e) {
                  // 10. Show error if placeOrder() fails
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to place order: $e')),
                  );
                } finally {
                  // 11. ALWAYS stop the spinner
                  if (mounted) {
                    setState(() {
                      _isLoading = false;
                    });
                  }
                }
              },

              // 12. Show spinner or text based on loading state
              child: _isLoading
                  ? const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              )
                  : const Text('Place Order'),
            ),
          ),


          // TOTAL PRICE SUMMARY
          Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total:',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '₱${cart.totalPrice.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple,
                    ),
                  ),
                ],
              ),
            ),
          ),


          // Future module will add Checkout button here
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

