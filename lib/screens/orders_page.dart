import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:scuba_diving_admin_panel/color/color_palette.dart';
import 'package:scuba_diving_admin_panel/main.dart';
import 'package:scuba_diving_admin_panel/screens/order_details_page.dart';
import '../../models/order.dart';

class OrdersPage extends StatefulWidget {
  const OrdersPage({super.key});

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  List<Order> _orders = [];
  bool _isLoading = false;
  String? _errorMessage;

  double _deliveredRevenue = 0.0;
  double _inTransitRevenue = 0.0;
  double _waitingRevenue = 0.0;

  @override
  void initState() {
    super.initState();
    _fetchOrders();
    _fetchTotalRevenue();
  }

  Future<void> _fetchTotalRevenue() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final statuses = ['Delivered', 'In Transit', 'Waiting'];
      for (var status in statuses) {
        final uri = Uri.parse(
          '$API_BASE_URL/api/Order/total-revenue?status=$status',
        );
        final response = await http.get(uri);

        if (response.statusCode == 200) {
          final Map<String, dynamic> jsonResponse = json.decode(response.body);
          final double revenue = jsonResponse['totalAmount']?.toDouble() ?? 0.0;

          setState(() {
            if (status == 'Delivered') {
              _deliveredRevenue = revenue;
            } else if (status == 'In Transit') {
              _inTransitRevenue = revenue;
            } else if (status == 'Waiting') {
              _waitingRevenue = revenue;
            }
          });
        } else {
          print(
            'Failed to load total revenue for $status: Status code ${response.statusCode}',
          );
        }
      }
    } catch (e) {
      print('API call error fetching total revenue: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
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
      final uri = Uri.parse('$API_BASE_URL/api/Order/$orderId/status');

      final response = await http.patch(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'status': newStatus}),
      );

      if (response.statusCode == 204 || response.statusCode == 200) {
        await _fetchOrders();
        await _fetchTotalRevenue();
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
    await _fetchTotalRevenue();
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
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(80.0),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildRevenueCard(
                      'Delivered',
                      _deliveredRevenue,
                      ColorPalette.success,
                    ),
                    Icon(Icons.add, size: 16, color: Colors.white),
                    _buildRevenueCard(
                      'In Transit',
                      _inTransitRevenue,
                      Colors.deepOrange,
                    ),
                    Icon(Icons.add, size: 16, color: Colors.white),
                    _buildRevenueCard(
                      'Waiting',
                      _waitingRevenue,
                      ColorPalette.error,
                    ),
                    Icon(
                      Icons.arrow_forward_outlined,
                      size: 16,
                      color: Colors.white,
                    ),
                    _buildRevenueCard(
                      'Total',
                      _waitingRevenue + _inTransitRevenue + _deliveredRevenue,
                      ColorPalette.white,
                    ),
                  ],
                ),
                const SizedBox(height: 8.0),
              ],
            ),
          ),
        ),
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
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) => OrderDetailsPage(
                                    orderId: order.id,
                                    userId: order.userId,
                                    shippingAddressId: order.shippingAddressId,
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

  Widget _buildRevenueCard(String title, double revenue, Color color) {
    return Column(
      children: [
        Text(
          title,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        Text(
          '\$${revenue.toStringAsFixed(2)}',
          style: TextStyle(
            color: color,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
