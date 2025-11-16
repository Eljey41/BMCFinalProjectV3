import 'package:flutter/material.dart';

class ProductCard extends StatelessWidget {

  // Data needed for each card
  final String productName;
  final double price;
  final String imageUrl;
  final VoidCallback onTap; // NEW

  const ProductCard({
    super.key,
    required this.productName,
    required this.price,
    required this.imageUrl,
    required this.onTap, // NEW
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(               // ← NEW: Makes whole card tappable
      onTap: onTap,               // ← Calls the function passed in
      child: Card(
        elevation: 3,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [

            // PRODUCT IMAGE
            Expanded(
              child: Image.network(
                imageUrl,
                fit: BoxFit.cover,

                // Loading spinner
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                },

                // Error if image fails to load
                errorBuilder: (context, error, stackTrace) {
                  return const Center(
                    child: Icon(Icons.broken_image,
                        size: 40, color: Colors.grey),
                  );
                },
              ),
            ),

            // PRODUCT TEXT
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // Product name
                  Text(
                    productName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 4),

                  // Price
                  Text(
                    '₱${price.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
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
