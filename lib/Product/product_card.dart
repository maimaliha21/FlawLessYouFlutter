import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

class ProductCard extends StatefulWidget {
  final dynamic product;
  final String token;
  final bool compactMode;

  const ProductCard({
    Key? key,
    required this.product,
    required this.token,
    this.compactMode = false,
  }) : super(key: key);

  @override
  _ProductCardState createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  bool isSaved = false;
  double userRating = 0;

  @override
  void initState() {
    super.initState();
    isSaved = widget.product['isSaved'] ?? false;
    _fetchUserRating();
  }

  Future<void> _fetchUserRating() async {
    try {
      final response = await http.get(
        Uri.parse('http://localhost:8080/product/${widget.product['productId']}/userReview'),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );

      if (response.statusCode == 200) {
        setState(() {
          userRating = jsonDecode(response.body)['rating']?.toDouble() ?? 0;
        });
      }
    } catch (e) {
      print('Error fetching user rating: $e');
    }
  }

  Future<void> _updateRating(double newRating) async {
    try {
      final response = await http.put(
        Uri.parse('http://localhost:8080/product/${widget.product['productId']}/reviews'),
        headers: {
          'Authorization': 'Bearer ${widget.token}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'rating': newRating}),
      );

      if (response.statusCode == 200) {
        setState(() => userRating = newRating);
      }
    } catch (e) {
      print('Error updating rating: $e');
    }
  }

  Future<void> toggleSave() async {
    final newState = !isSaved;
    setState(() => isSaved = newState);

    try {
      final endpoint = newState ? 'savedProduct' : 'removeSavedProduct';
      final response = await http.post(
        Uri.parse('http://localhost:8080/product/${widget.product['productId']}/$endpoint'),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );

      if (response.statusCode != 200) {
        setState(() => isSaved = !newState);
      }
    } catch (e) {
      setState(() => isSaved = !newState);
    }
  }

  void _showProductDetails(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => ProductDetailsPopup(
        product: widget.product,
        initialRating: userRating,
        onRatingUpdate: _updateRating,
        token: widget.token,
        onSaveToggle: toggleSave,
        isSaved: isSaved,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showProductDetails(context),
      child: Card(
        elevation: 4,
        child: Stack(
          children: [
            if (widget.product['photos'] != null && widget.product['photos'].isNotEmpty)
              Image.network(
                widget.product['photos'][0],
                fit: BoxFit.cover,
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
                      widget.product['name'] ?? 'No Name',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: widget.compactMode ? 14 : 16,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (!widget.compactMode) ...[
                      const SizedBox(height: 4),
                      Text(
                        widget.product['description'] ?? '',
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        RatingBar.builder(
                          initialRating: widget.product['rating']?.toDouble() ?? 0,
                          minRating: 1,
                          direction: Axis.horizontal,
                          allowHalfRating: true,
                          itemCount: 5,
                          itemSize: 16,
                          itemBuilder: (context, _) => const Icon(
                            Icons.star,
                            color: Colors.amber,
                          ),
                          onRatingUpdate: (rating) {},
                          ignoreGestures: true,
                        ),
                        if (!widget.compactMode)
                          Text(
                            (widget.product['rating']?.toDouble() ?? 0).toStringAsFixed(1),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
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
            Positioned(
              bottom: 8,
              left: 8,
              child: RatingWidget(
                initialRating: userRating,
                onRatingUpdate: _updateRating,
                itemSize: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class RatingWidget extends StatelessWidget {
  final double initialRating;
  final Function(double) onRatingUpdate;
  final double itemSize;

  const RatingWidget({
    Key? key,
    required this.initialRating,
    required this.onRatingUpdate,
    this.itemSize = 30,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return RatingBar.builder(
      initialRating: initialRating,
      minRating: 1,
      direction: Axis.horizontal,
      allowHalfRating: true,
      itemCount: 5,
      itemSize: itemSize,
      itemBuilder: (context, _) => Icon(
        Icons.star,
        color: Colors.amber,
      ),
      onRatingUpdate: onRatingUpdate,
    );
  }
}

class ProductDetailsPopup extends StatefulWidget {
  final dynamic product;
  final double initialRating;
  final Function(double) onRatingUpdate;
  final String token;
  final Function onSaveToggle;
  final bool isSaved;

  const ProductDetailsPopup({
    Key? key,
    required this.product,
    required this.initialRating,
    required this.onRatingUpdate,
    required this.token,
    required this.onSaveToggle,
    required this.isSaved,
  }) : super(key: key);

  @override
  _ProductDetailsPopupState createState() => _ProductDetailsPopupState();
}

class _ProductDetailsPopupState extends State<ProductDetailsPopup> {
  late double _currentRating;
  late bool _isSaved;

  @override
  void initState() {
    super.initState();
    _currentRating = widget.initialRating;
    _isSaved = widget.isSaved;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(
              height: 300,
              child: Image.network(
                widget.product['photos']?.isNotEmpty == true
                    ? widget.product['photos'][0]
                    : '',
                fit: BoxFit.cover,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: RatingWidget(
                initialRating: _currentRating,
                onRatingUpdate: (newRating) {
                  widget.onRatingUpdate(newRating);
                  setState(() => _currentRating = newRating);
                },
                itemSize: 40,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                widget.product['name'] ?? 'No Name',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                widget.product['description'] ?? 'No Description',
                style: const TextStyle(fontSize: 16),
              ),
            ),
            IconButton(
              icon: Icon(
                _isSaved ? Icons.bookmark : Icons.bookmark_border,
                color: _isSaved ? Colors.yellow : Colors.grey,
              ),
              onPressed: () {
                widget.onSaveToggle();
                setState(() => _isSaved = !_isSaved);
              },
            ),
          ],
        ),
      ),
    );
  }
}