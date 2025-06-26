import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:scuba_diving_admin_panel/color/color_palette.dart';
import 'package:scuba_diving_admin_panel/main.dart';
import '../models/review.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

class ProductCommentsPage extends StatefulWidget {
  final int productId;
  final String productName;

  const ProductCommentsPage({
    super.key,
    required this.productId,
    required this.productName,
  });

  @override
  State<ProductCommentsPage> createState() => _ProductCommentsPageState();
}

class _ProductCommentsPageState extends State<ProductCommentsPage> {
  List<Review> _reviews = [];
  bool _isLoading = false;
  String? _errorMessage;
  double? _averageRating;

  @override
  void initState() {
    super.initState();
    _fetchProductReviews();
  }

  Future<void> _fetchProductReviews() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _averageRating = null;
    });

    try {
      final uri = Uri.parse(
        '$API_BASE_URL/api/Review/product/${widget.productId}',
      );
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final List<dynamic> reviewJsonList = json.decode(response.body);

        final List<Review> fetchedReviews =
            reviewJsonList.map((json) => Review.fromJson(json)).toList();

        if (fetchedReviews.isNotEmpty) {
          double totalRating = fetchedReviews.fold(
            0,
            (sum, review) => sum + review.rating,
          );
          _averageRating = totalRating / fetchedReviews.length;
        } else {
          _averageRating = 0.0;
        }

        if (mounted) {
          setState(() {
            _reviews = fetchedReviews;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _errorMessage =
                'Failed to load comments: Status code ${response.statusCode}. Body: ${response.body}';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'API call error: $e';
          print('Error fetching product comments: $e');
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _refreshReviews() async {
    setState(() {
      _reviews = [];
      _errorMessage = null;
      _averageRating = null;
    });
    await _fetchProductReviews();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Reviews for ${widget.productName}',
          style: GoogleFonts.playfair(color: ColorPalette.white),
        ),
        backgroundColor: ColorPalette.primary,
        iconTheme: IconThemeData(color: ColorPalette.white),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshReviews,
          ),
        ],
      ),
      body:
          _errorMessage != null
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Error: $_errorMessage'),
                    ElevatedButton(
                      onPressed: _refreshReviews,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              )
              : _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                children: [
                  if (_averageRating != null)
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          Text(
                            'Average Rating',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          RatingBar.builder(
                            initialRating: _averageRating!,
                            minRating: 0,
                            direction: Axis.horizontal,
                            allowHalfRating: true,
                            itemCount: 5,
                            itemSize: 24.0,
                            itemPadding: const EdgeInsets.symmetric(
                              horizontal: 2.0,
                            ),
                            itemBuilder:
                                (context, _) =>
                                    const Icon(Icons.star, color: Colors.amber),
                            onRatingUpdate: (rating) {},
                            ignoreGestures: true,
                          ),
                          Text(
                            '(${_averageRating!.toStringAsFixed(1)})',
                            style: const TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  Expanded(
                    child:
                        _reviews.isEmpty
                            ? const Center(
                              child: Text('No reviews found for this product.'),
                            )
                            : ListView.builder(
                              padding: const EdgeInsets.all(16.0),
                              itemCount: _reviews.length,
                              itemBuilder: (context, index) {
                                final review = _reviews[index];
                                return Card(
                                  margin: const EdgeInsets.symmetric(
                                    vertical: 8.0,
                                  ),
                                  elevation: 2,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            RatingBar.builder(
                                              initialRating:
                                                  review.rating.toDouble(),
                                              minRating: 0,
                                              direction: Axis.horizontal,
                                              allowHalfRating: false,
                                              itemCount: 5,
                                              itemSize: 20.0,
                                              itemPadding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 1.0,
                                                  ),
                                              itemBuilder:
                                                  (context, _) => const Icon(
                                                    Icons.star,
                                                    color: Colors.amber,
                                                  ),
                                              onRatingUpdate: (rating) {},
                                              ignoreGestures: true,
                                            ),
                                            Text(
                                              '(${review.rating})',
                                              style: const TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          review.comment,
                                          style: const TextStyle(fontSize: 14),
                                        ),
                                        const SizedBox(height: 8),
                                        Align(
                                          alignment: Alignment.bottomRight,
                                          child: Text(
                                            'User ID: ${review.userId.substring(0, 8)}...',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        ),
                                        Align(
                                          alignment: Alignment.bottomRight,
                                          child: Text(
                                            'Date: ${review.createdAt.toLocal().toString().split(' ')[0]}',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                  ),
                ],
              ),
    );
  }
}
