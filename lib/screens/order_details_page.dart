import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:scuba_diving_admin_panel/color/color_palette.dart';
import 'package:scuba_diving_admin_panel/main.dart';
import 'package:scuba_diving_admin_panel/models/address.dart';
import 'package:scuba_diving_admin_panel/models/order_item.dart';

class OrderDetailsPage extends StatefulWidget {
  final int orderId;
  final String userId;
  final int shippingAddressId;

  const OrderDetailsPage({
    super.key,
    required this.orderId,
    required this.userId,
    required this.shippingAddressId,
  });

  @override
  State<OrderDetailsPage> createState() => _OrderDetailsPageState();
}

class _OrderDetailsPageState extends State<OrderDetailsPage> {
  List<OrderItem> _orderItems = [];
  Address? _shippingAddress;
  String? _userName;
  bool _isLoading = false;
  String? _errorMessage;

  bool _isAddressLoading = false;
  String? _addressErrorMessage;

  bool _isUsernameLoading = false;
  String? _usernameErrorMessage;

  @override
  void initState() {
    super.initState();
    _fetchOrderItems();
    _fetchShippingAddress();
    _fetchUsername();
  }

  Future<void> _fetchOrderItems() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final uri = Uri.parse(
        '$API_BASE_URL/api/OrderItem/byOrder/${widget.orderId}',
      );
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final List<dynamic> orderItemJsonList = json.decode(response.body);
        if (mounted) {
          setState(() {
            _orderItems =
                orderItemJsonList
                    .map((json) => OrderItem.fromJson(json))
                    .toList();
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _errorMessage =
                'Failed to load order items: Status code ${response.statusCode}. Body: ${response.body}';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'API call error for order items: $e';
          print('Error fetching order items: $e');
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

  Future<void> _fetchShippingAddress() async {
    if (!mounted) return;
    setState(() {
      _isAddressLoading = true;
      _addressErrorMessage = null;
    });

    try {
      final uri = Uri.parse(
        '$API_BASE_URL/api/Address/${widget.userId}/${widget.shippingAddressId}',
      );
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final dynamic addressJson = json.decode(response.body);
        if (mounted) {
          setState(() {
            _shippingAddress = Address.fromJson(addressJson);
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _addressErrorMessage =
                'Failed to load shipping address: Status code ${response.statusCode}. Body: ${response.body}';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _addressErrorMessage = 'API call error for shipping address: $e';
          print('Error fetching shipping address: $e');
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isAddressLoading = false;
        });
      }
    }
  }

  Future<void> _fetchUsername() async {
    if (!mounted) return;
    setState(() {
      _isUsernameLoading = true;
      _usernameErrorMessage = null;
    });

    try {
      final uri = Uri.parse('$API_BASE_URL/api/Auth/username/${widget.userId}');
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final Map<String, dynamic> usernameJson = json.decode(response.body);
        if (mounted) {
          setState(() {
            _userName = usernameJson['userName'];
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _usernameErrorMessage =
                'Failed to load username: Status code ${response.statusCode}. Body: ${response.body}';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _usernameErrorMessage = 'API call error for username: $e';
          print('Error fetching username: $e');
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUsernameLoading = false;
        });
      }
    }
  }

  Future<void> _refreshAllData() async {
    await Future.wait([
      _fetchOrderItems(),
      _fetchShippingAddress(),
      _fetchUsername(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Order #${widget.orderId} Details',
          style: GoogleFonts.playfair(color: ColorPalette.white),
        ),
        backgroundColor: ColorPalette.primary,
        iconTheme: IconThemeData(color: ColorPalette.white),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshAllData,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Customer Information',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _isUsernameLoading
                          ? const Center(child: CircularProgressIndicator())
                          : _usernameErrorMessage != null
                          ? Text(
                            'Error loading customer name: $_usernameErrorMessage',
                            style: const TextStyle(color: Colors.red),
                          )
                          : _userName != null
                          ? Text('Customer Name: ${_userName!}')
                          : const Text('Customer name not available.'),
                    ],
                  ),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              child: Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Shipping Address',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _isAddressLoading
                          ? const Center(child: CircularProgressIndicator())
                          : _addressErrorMessage != null
                          ? Text(
                            'Error loading address: $_addressErrorMessage',
                            style: const TextStyle(color: Colors.red),
                          )
                          : _shippingAddress != null
                          ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Title: ${_shippingAddress!.title}'),
                              Text(
                                'Full Address: ${_shippingAddress!.fullAddress}',
                              ),
                              Text('City: ${_shippingAddress!.city}'),
                              Text('State: ${_shippingAddress!.state}'),
                              Text('Zip Code: ${_shippingAddress!.zipcode}'),
                              Text('Country: ${_shippingAddress!.country}'),
                            ],
                          )
                          : const Text('Shipping address not available.'),
                    ],
                  ),
                ),
              ),
            ),

            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Text(
                'Order Items',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),

            _errorMessage != null
                ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Error: $_errorMessage'),
                      ElevatedButton(
                        onPressed: _refreshAllData,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
                : _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _orderItems.isEmpty
                ? const Center(child: Text('No items found for this order.'))
                : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _orderItems.length,
                  itemBuilder: (context, index) {
                    final item = _orderItems[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text('Quantity: ${item.quantity}'),
                            Text('Price: \$${item.price.toStringAsFixed(2)}'),
                            Text(
                              'Total for Item: \$${(item.quantity * item.price).toStringAsFixed(2)}',
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
          ],
        ),
      ),
    );
  }
}
