import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:scuba_diving_admin_panel/add_product_page.dart';
import 'package:scuba_diving_admin_panel/color/color_palette.dart';
import 'package:scuba_diving_admin_panel/main.dart'; // API_BASE_URL buradan geliyor
import 'package:scuba_diving_admin_panel/picture/picture.dart';
import 'package:scuba_diving_admin_panel/update_product_page.dart';
import 'package:scuba_diving_admin_panel/product_comments_page.dart';
import '../models/product.dart';

class AdminProductPage extends StatefulWidget {
  const AdminProductPage({super.key});

  @override
  State<AdminProductPage> createState() => _AdminProductPageState();
}

class _AdminProductPageState extends State<AdminProductPage> {
  List<Product> _products = [];
  int _currentPage = 1;
  final int _pageSize = 12;
  bool _isLoading = false;
  bool _hasMore = true;
  String? _errorMessage;

  final ScrollController _scrollController = ScrollController();

  // Maksimum ID'yi tutacak değişken
  int _maxProductId = 0; // Initialize with a default value

  @override
  void initState() {
    super.initState();
    _fetchMaxProductId(); // Fetch max product ID first
    _fetchProducts(); // Then fetch products
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  // New method to fetch max product ID
  Future<void> _fetchMaxProductId() async {
    try {
      final uri = Uri.parse('$API_BASE_URL/api/Product/max-id');
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        setState(() {
          _maxProductId = int.parse(response.body);
        });
      } else {
        setState(() {
          _errorMessage =
              'Failed to load max product ID: Status code ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'API call error for max-id: $e';
        print('Error fetching max product ID: $e');
      });
    }
  }

  Future<void> _fetchProducts() async {
    if (_isLoading || !_hasMore) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final uri = Uri.parse(
        '$API_BASE_URL/api/Product/all-products-paged?PageNumber=$_currentPage&PageSize=$_pageSize',
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
              'Failed to load products: Status code ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'API call error: $e';
        print('Error fetching products: $e');
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
    await _fetchMaxProductId(); // Also refresh max ID on product refresh
    await _fetchProducts();
  }

  Future<void> _deleteProduct(int productId) async {
    setState(() {
      _isLoading = true;
    });
    try {
      final uri = Uri.parse('$API_BASE_URL/api/Product/$productId');
      final response = await http.delete(uri);

      if (response.statusCode == 204) {
        setState(() {
          _products.removeWhere((product) => product.id == productId);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Product deleted successfully!')),
        );
      } else {
        setState(() {
          _errorMessage =
              'Failed to delete product: Status code ${response.statusCode}. Body: ${response.body}';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error deleting product: Status code ${response.statusCode}',
            ),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'API call error during delete: $e';
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error deleting product: $e')));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
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
          'Admin Product Panel',
          style: GoogleFonts.playfair(color: ColorPalette.white),
        ),
        backgroundColor: ColorPalette.primary,
        iconTheme: IconThemeData(color: ColorPalette.white),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () async {
              // Ensure _maxProductId is fetched before navigating
              await _fetchMaxProductId();
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddProductPage(id: _maxProductId + 1),
                ),
              );
              _refreshProducts(); // Refresh products after adding a new one
            },
            icon: Icon(Icons.add),
          ),
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
              ? const Center(child: Text('No products found.'))
              : RefreshIndicator(
                onRefresh: _refreshProducts,
                child: GridView.builder(
                  controller: _scrollController,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.7,
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
                                'Stock: ${product.stock}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  IconButton(
                                    icon: const Icon(
                                      Icons.comment,
                                      color: ColorPalette.primary,
                                      size: 20,
                                    ),
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder:
                                              (context) => ProductCommentsPage(
                                                productId: product.id,
                                                productName: product.name,
                                              ),
                                        ),
                                      );
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.edit,
                                      color: Colors.blue,
                                      size: 20,
                                    ),
                                    onPressed: () async {
                                      await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder:
                                              (context) => UpdateProductPage(
                                                product: product,
                                              ),
                                        ),
                                      );
                                      _refreshProducts();
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete,
                                      color: Colors.red,
                                      size: 20,
                                    ),
                                    onPressed:
                                        () => _showDeleteConfirmationDialog(
                                          context,
                                          product,
                                        ),
                                  ),
                                ],
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

  void _showDeleteConfirmationDialog(BuildContext context, Product product) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Delete Product?'),
          content: Text('Are you sure you want to delete "${product.name}"?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            TextButton(
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
              onPressed: () {
                _deleteProduct(product.id);
                Navigator.of(dialogContext).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
