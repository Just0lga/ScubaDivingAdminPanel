import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:scuba_diving_admin_panel/color/color_palette.dart';
import 'package:scuba_diving_admin_panel/main.dart';
import 'package:scuba_diving_admin_panel/picture/picture.dart';
import '../../models/product.dart';

class TopViewedProductsPage extends StatefulWidget {
  const TopViewedProductsPage({super.key});

  @override
  State<TopViewedProductsPage> createState() => _TopViewedProductsPageState();
}

class _TopViewedProductsPageState extends State<TopViewedProductsPage> {
  List<Product> _products = [];
  int _currentPage = 1;
  final int _pageSize = 12;
  bool _isLoading = false;
  bool _hasMore = true;
  String? _errorMessage;

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _fetchProducts();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchProducts() async {
    if (_isLoading || !_hasMore) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final uri = Uri.parse(
        '$API_BASE_URL/api/Product/top-viewed-paged?PageNumber=$_currentPage&PageSize=$_pageSize',
      );
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final List<dynamic> productJsonList = json.decode(response.body);

        final List<Product> newProducts =
            productJsonList.map((json) => Product.fromJson(json)).toList();

        setState(() {
          if (newProducts.isEmpty) {
            _hasMore = false;
          } else {
            _products.addAll(newProducts);
            _currentPage++;
          }
        });
      } else {
        setState(() {
          _errorMessage =
              'Failed to load top viewed products: Status code ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'API call error: $e';
        print('Error fetching top viewed products: $e');
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent * 0.8 &&
        !_isLoading &&
        _hasMore) {
      _fetchProducts();
    }
  }

  Future<void> _refreshProducts() async {
    setState(() {
      _products = [];
      _currentPage = 1;
      _hasMore = true;
      _errorMessage = null;
    });
    await _fetchProducts();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    int crossAxisCount;
    if (screenWidth < 600) {
      crossAxisCount = 2;
    } else if (screenWidth < 900) {
      crossAxisCount = 3;
    } else {
      crossAxisCount = 4;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Top Viewed Products',
          style: GoogleFonts.playfair(color: ColorPalette.white),
        ),
        backgroundColor: ColorPalette.primary,
        iconTheme: IconThemeData(color: ColorPalette.white),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshProducts,
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
                      onPressed: _refreshProducts,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              )
              : _products.isEmpty && _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _products.isEmpty && !_isLoading && !_hasMore
              ? const Center(child: Text('No top viewed products found.'))
              : RefreshIndicator(
                onRefresh: _refreshProducts,
                child: GridView.builder(
                  controller: _scrollController,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.6,
                  ),
                  padding: const EdgeInsets.all(16),
                  itemCount: _products.length + (_isLoading ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index < _products.length) {
                      final product = _products[index];
                      return Card(
                        color: Colors.white,
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Container(
                                  alignment: Alignment.center,
                                  width: screenWidth,
                                  decoration: BoxDecoration(
                                    color: Colors.transparent,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Picture(
                                    baseUrl:
                                        "https://scuba-diving-s3-bucket.s3.eu-north-1.amazonaws.com/products",
                                    fileName: "${product.name}-1",
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                product.name,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                product.description ?? 'No description',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[700],
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Price: \$${product.price.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                'Brand: ${product.brand}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                              Text(
                                'Review Count: ${product.reviewCount}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    } else {
                      return _hasMore
                          ? const Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Center(child: CircularProgressIndicator()),
                          )
                          : const SizedBox.shrink();
                    }
                  },
                ),
              ),
    );
  }
}
