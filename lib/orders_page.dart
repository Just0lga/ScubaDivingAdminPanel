import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:scuba_diving_admin_panel/color/color_palette.dart';
import 'package:scuba_diving_admin_panel/main.dart'; // API_BASE_URL için
import 'package:scuba_diving_admin_panel/order_details_page.dart'; // OrderDetailsPage için import
import '../models/order.dart'; // Order modeli

class OrdersPage extends StatefulWidget {
  const OrdersPage({super.key});

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  List<Order> _orders = [];
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchOrders();
  }

  Future<void> _fetchOrders() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final uri = Uri.parse('$API_BASE_URL/api/Order');
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final List<dynamic> orderJsonList = json.decode(response.body);

        setState(() {
          _orders = orderJsonList.map((json) => Order.fromJson(json)).toList();
        });
      } else {
        setState(() {
          _errorMessage =
              'Failed to load orders: Status code ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'API call error: $e';
        print('Error fetching orders: $e');
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _updateOrderStatus(int orderId, String newStatus) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // API_BASE_URL'iniz doğrudan API portunuza işaret etmeli.
      // Eğer API_BASE_URL'iniz hala 'http://localhost:5173' ise ve API'niz 7096'da ise,
      // API_BASE_URL'i main.dart'ta 'https://localhost:7096' olarak ayarlamanız GEREKİR.
      // Aksi takdirde, bu çağrı başarısız olabilir.
      // Şu anki kod, doğrudan API_BASE_URL'i kullanıyor ve bir dönüşüm yapmıyor.
      final uri = Uri.parse('$API_BASE_URL/api/Order/$orderId/status');

      final response = await http.patch(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'status': newStatus}),
      );

      if (response.statusCode == 204 || response.statusCode == 200) {
        // 200 de başarılı sayılabilir
        await _fetchOrders(); // Durum güncellendikten sonra listeyi yeniden çek
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Order #$orderId status updated to $newStatus'),
          ),
        );
      } else {
        setState(() {
          _errorMessage =
              'Failed to update status for order #$orderId: Status code ${response.statusCode}. Body: ${response.body}';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update status: ${response.statusCode}'),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'API call error during update: $e';
        print('Error updating order status: $e');
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error updating status: $e')));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshOrders() async {
    setState(() {
      _orders = [];
      _errorMessage = null;
    });
    await _fetchOrders();
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'delivered':
        return ColorPalette.success;
      case 'in transit':
        return ColorPalette.primary;
      case 'waiting':
        return ColorPalette.error;
      case 'cancelled':
        return ColorPalette.error;
      default:
        return ColorPalette.error;
    }
  }

  String _getNextStatus(String currentStatus) {
    switch (currentStatus.toLowerCase()) {
      case 'waiting':
        return 'In Transit';
      case 'in transit':
        return 'Delivered';
      case 'delivered':
        return 'Delivered';
      case 'cancelled':
        return 'Cancelled';
      default:
        return 'Waiting';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'My Orders',
          style: GoogleFonts.playfair(color: ColorPalette.white),
        ),
        backgroundColor: ColorPalette.primary,
        iconTheme: IconThemeData(color: ColorPalette.white),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshOrders,
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
                      onPressed: _refreshOrders,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              )
              : _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _orders.isEmpty
              ? const Center(child: Text('No orders found.'))
              : RefreshIndicator(
                onRefresh: _refreshOrders,
                child: ListView.builder(
                  itemCount: _orders.length,
                  itemBuilder: (context, index) {
                    final order = _orders[index];
                    final nextStatus = _getNextStatus(order.status);
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      elevation: 3,
                      child: GestureDetector(
                        onTap: () {
                          // Navigator.push ile OrderDetailsPage'e userId ve shippingAddressId gönderiliyor
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) => OrderDetailsPage(
                                    orderId: order.id,
                                    userId:
                                        order
                                            .userId, // Order modelinizde bu alan olmalı
                                    shippingAddressId:
                                        order
                                            .shippingAddressId, // Order modelinizde bu alan olmalı
                                  ),
                            ),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Order #${order.id}',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Total Price: \$${order.totalAmount.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Order Date: ${order.createdAt.toLocal().toString().split(' ')[0]}',
                                style: const TextStyle(fontSize: 14),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      const Text(
                                        'Status: ',
                                        style: TextStyle(fontSize: 15),
                                      ),
                                      Text(
                                        order.status,
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                          color: _getStatusColor(order.status),
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (order.status.toLowerCase() !=
                                          'delivered' &&
                                      order.status.toLowerCase() != 'cancelled')
                                    ElevatedButton(
                                      onPressed: () {
                                        _updateOrderStatus(
                                          order.id,
                                          nextStatus,
                                        );
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: ColorPalette.primary,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 8,
                                        ),
                                      ),
                                      child: Text('Set to $nextStatus'),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
    );
  }
}
