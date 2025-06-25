import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:scuba_diving_admin_panel/color/color_palette.dart';
import 'package:scuba_diving_admin_panel/main.dart'; // API_BASE_URL için
import 'package:scuba_diving_admin_panel/picture/picture.dart';
import '../models/product.dart'; // Product modeliniz için

class MostFavoritedProductsPage extends StatefulWidget {
  const MostFavoritedProductsPage({super.key});

  @override
  State<MostFavoritedProductsPage> createState() =>
      _MostFavoritedProductsPageState();
}

class _MostFavoritedProductsPageState extends State<MostFavoritedProductsPage> {
  List<Product> _products = [];
  int _currentPage = 1;
  final int _pageSize = 12;
  bool _isLoading = false;
  bool _hasMore = true; // Daha fazla ürün olup olmadığını belirtir
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

  /// En çok favorilenen ürünleri API'den sayfalama yaparak çeker.
  Future<void> _fetchProducts() async {
    if (_isLoading || !_hasMore)
      return; // Zaten yükleniyorsa veya daha fazlası yoksa çık

    setState(() {
      _isLoading = true;
      _errorMessage =
          null; // Yeni bir yükleme başlatırken önceki hatayı temizle
    });

    try {
      final uri = Uri.parse(
        '$API_BASE_URL/api/Product/most-favorited-paged?PageNumber=$_currentPage&PageSize=$_pageSize',
      );
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final List<dynamic> productJsonList = json.decode(response.body);

        // Eğer gelen liste boşsa veya önceki sayfayla aynı ürünleri içeriyorsa, daha fazla ürün yoktur.
        if (productJsonList.isEmpty) {
          setState(() {
            _hasMore = false;
          });
        } else {
          final List<Product> newProducts =
              productJsonList.map((json) => Product.fromJson(json)).toList();

          setState(() {
            _products.addAll(newProducts);
            _currentPage++; // Bir sonraki sayfa için sayfa numarasını artır
          });
        }
      } else {
        setState(() {
          _errorMessage =
              'Failed to load most favorited products: Status code ${response.statusCode}. Please try again.';
          _hasMore = false; // Hata durumunda daha fazla yüklemeyi durdur
        });
        print(
          'API Error: ${response.statusCode} - ${response.body}',
        ); // Hata detaylarını logla
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Network error: Could not connect to the server. $e';
        _hasMore = false; // Hata durumunda daha fazla yüklemeyi durdur
        print(
          'Error fetching most favorited products: $e',
        ); // İstisna detaylarını logla
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Kullanıcı listenin sonuna yaklaştığında daha fazla ürün yükler.
  void _onScroll() {
    // Scroll konumunun %80'ine gelindiğinde ve yükleme yoksa ve daha fazla ürün varsa
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent * 0.8 &&
        !_isLoading &&
        _hasMore) {
      _fetchProducts();
    }
  }

  /// Ürün listesini sıfırlar ve yeniden yükler.
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
    // Ekran genişliğini al
    final screenWidth = MediaQuery.of(context).size.width;
    // Ekran genişliğine göre sütun sayısını belirle
    int crossAxisCount;
    if (screenWidth < 600) {
      crossAxisCount = 2; // Mobil cihazlar için 2 sütun
    } else if (screenWidth < 900) {
      crossAxisCount = 3; // Tabletler için 3 sütun
    } else {
      crossAxisCount = 4; // Masaüstü için 4 sütun
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Most Favorited Products',
          style: GoogleFonts.playfair(color: ColorPalette.white),
        ),
        backgroundColor: ColorPalette.primary,
        iconTheme: IconThemeData(color: ColorPalette.white),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshProducts,
            tooltip: 'Refresh Products',
          ),
        ],
      ),
      body:
          _errorMessage != null
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Error: $_errorMessage',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red, fontSize: 16),
                    ),
                    const SizedBox(height: 16),
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
              ? const Center(child: Text('No most favorited products found.'))
              : RefreshIndicator(
                onRefresh: _refreshProducts,
                child: GridView.builder(
                  controller: _scrollController,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount, // Dinamik sütun sayısı
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.7, // Her bir öğenin en boy oranı
                  ),
                  padding: const EdgeInsets.all(16),
                  itemCount:
                      _products.length +
                      (_hasMore
                          ? 1
                          : 0), // Daha fazla varsa yükleme göstergesi için +1
                  itemBuilder: (context, index) {
                    if (index == _products.length) {
                      // Listenin sonuna gelindiğinde ve daha fazla ürün varsa yükleme göstergesini göster
                      return _isLoading
                          ? const Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Center(child: CircularProgressIndicator()),
                          )
                          : const SizedBox.shrink(); // Daha fazla yoksa boş bir kutu
                    }

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
                              'Number of Favorites: ${product.favoriteCount}', // Favori sayısı gösterimi
                              style: TextStyle(
                                fontSize: 12,
                                color:
                                    Colors.pink[400], // Renk biraz değiştirildi
                                fontWeight:
                                    FontWeight
                                        .bold, // Favori sayısı daha belirgin
                              ),
                            ),
                            // Bu sayfada ürün silme veya düzenleme butonları varsayılan olarak kaldırılmıştır.
                            // Sadece bir görüntüleme sayfası olduğu varsayılmıştır.
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
    );
  }
}
