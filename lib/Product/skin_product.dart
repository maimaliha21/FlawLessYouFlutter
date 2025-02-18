import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'product.dart'; // استيراد ملف product.dart

class SkinProductCard extends StatefulWidget {
  final Product product;
  final String token;

  const SkinProductCard({Key? key, required this.product, required this.token}) : super(key: key);

  @override
  _SkinProductCardState createState() => _SkinProductCardState();
}

class _SkinProductCardState extends State<SkinProductCard> {
  bool isSaved = false;

  @override
  void initState() {
    super.initState();
    isSaved = widget.product.isSaved;
  }

  Future<void> toggleSave() async {
    final newState = !isSaved;
    setState(() => isSaved = newState);

    try {
      final response = await (newState
          ? http.post(
        Uri.parse('http://localhost:8080/product/${widget.product.productId}/savedProduct'),
        headers: {
          'Authorization': 'Bearer ${widget.token}',
          'Content-Type': 'application/json',
        },
      )
          : http.post(
        Uri.parse('http://localhost:8080/product/${widget.product.productId}/savedProduct'),
        headers: {
          'Authorization': 'Bearer ${widget.token}',
          'Content-Type': 'application/json',
        },
      ));

      if (response.statusCode != 200) {
        setState(() => isSaved = !newState);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to ${newState ? 'save' : 'unsave'} product')),
        );
      }
    } catch (e) {
      setState(() => isSaved = !newState);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Connection error')),
      );
    }
  }

  void _showProductDetails(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          insetPadding: EdgeInsets.all(16),
          child: SkinProductDetailsPopup(product: widget.product, token: widget.token),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showProductDetails(context),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (widget.product.photos != null && widget.product.photos!.isNotEmpty)
                Image.network(
                  widget.product.photos![0],
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                            loadingProgress.expectedTotalBytes!
                            : null,
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: Colors.grey[300],
                    child: const Icon(Icons.error),
                  ),
                )
              else
                Container(
                  color: Colors.grey[300],
                  child: const Center(
                    child: Icon(Icons.image_not_supported, color: Colors.white),
                  ),
                ),

              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withOpacity(0.8),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.product.name ?? 'No Name',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.product.description ?? 'No description available',
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          ...List.generate(5, (index) {
                            double starPosition = index + 1.0;
                            if (widget.product.rating >= starPosition) {
                              return const Icon(
                                Icons.star,
                                color: Colors.yellow,
                                size: 16,
                              );
                            } else if (widget.product.rating >= starPosition - 0.5) {
                              return const Icon(
                                Icons.star_half,
                                color: Colors.yellow,
                                size: 16,
                              );
                            } else {
                              return const Icon(
                                Icons.star_border,
                                color: Colors.grey,
                                size: 16,
                              );
                            }
                          }),
                          const SizedBox(width: 4),
                          Text(
                            widget.product.rating.toStringAsFixed(1),
                            style: const TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: IconButton(
                  icon: Icon(
                    isSaved ? Icons.bookmark : Icons.bookmark_border,
                    color: isSaved ? Colors.yellow : Colors.white,
                  ),
                  onPressed: toggleSave,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SkinProductDetailsPopup extends StatefulWidget {
  final Product product;
  final String token;

  const SkinProductDetailsPopup({Key? key, required this.product, required this.token}) : super(key: key);

  @override
  _SkinProductDetailsPopupState createState() => _SkinProductDetailsPopupState();
}

class _SkinProductDetailsPopupState extends State<SkinProductDetailsPopup> {
  late PageController _pageController;
  int _currentPage = 0;
  double _userRating = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _startAutoSlide();
  }

  void _startAutoSlide() {
    Timer.periodic(Duration(seconds: 8), (timer) {
      if (_currentPage < (widget.product.photos?.length ?? 1) - 1) {
        _currentPage++;
      } else {
        _currentPage = 0;
      }
      _pageController.animateToPage(
        _currentPage,
        duration: Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    });
  }

  Future<void> _submitRating(double rating) async {
    try {
      final response = await http.post(
        Uri.parse('http://localhost:8080/product/${widget.product.productId}/rate'),
        headers: {
          'Authorization': 'Bearer ${widget.token}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'rating': rating}),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Rating submitted successfully')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to submit rating')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Connection error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 200,
            child: PageView.builder(
              controller: _pageController,
              itemCount: widget.product.photos?.length ?? 1,
              itemBuilder: (context, index) {
                return Image.network(
                  widget.product.photos?[index] ?? widget.product.photos?.first ?? '',
                  fit: BoxFit.cover,
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.product.name ?? 'No Name',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  widget.product.description ?? 'No description available',
                  style: TextStyle(fontSize: 16),
                ),
                SizedBox(height: 16),
                if (widget.product.skinType.isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Skin Type:',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 4),
                      Text(
                        widget.product.skinType.join(', '),
                        style: TextStyle(fontSize: 14),
                      ),
                      SizedBox(height: 16),
                    ],
                  ),
                if (widget.product.ingredients.isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ingredients:',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 4),
                      Text(
                        widget.product.ingredients.join(', '),
                        style: TextStyle(fontSize: 14),
                      ),
                      SizedBox(height: 16),
                    ],
                  ),
                RatingBar.builder(
                  initialRating: widget.product.rating,
                  minRating: 1,
                  direction: Axis.horizontal,
                  allowHalfRating: true,
                  itemCount: 5,
                  itemPadding: EdgeInsets.symmetric(horizontal: 4.0),
                  itemBuilder: (context, _) => Icon(
                    Icons.star,
                    color: Colors.amber,
                  ),
                  onRatingUpdate: (rating) {
                    setState(() {
                      _userRating = rating;
                    });
                    _submitRating(rating);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}