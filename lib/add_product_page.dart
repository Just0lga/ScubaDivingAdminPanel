import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:scuba_diving_admin_panel/color/color_palette.dart';
import 'package:scuba_diving_admin_panel/main.dart';
import 'package:scuba_diving_admin_panel/picture/s3_uploader.dart';

class AddProductPage extends StatefulWidget {
  const AddProductPage({super.key, required this.id});
  final int id;

  @override
  State<AddProductPage> createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage> {
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false;

  final TextEditingController nameController = TextEditingController();
  final TextEditingController brandController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  final TextEditingController stockController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();

  int selectedCategoryGroup = 1;
  List<CategoryItemModel> categoryItems = [];
  CategoryItemModel? selectedCategoryItem;

  final List<TextEditingController> _featureKeyControllers = [];
  final List<TextEditingController> _featureValueControllers = [];

  final S3Uploader _uploader = S3Uploader();
  bool _isLoading2 = false;
  String? _uploadResult;

  Future<void> _uploadImage() async {
    setState(() {
      _isLoading2 = true;
      _uploadResult = null;
    });

    try {
      await _uploader.pickAndUploadImage(nameController.text);
      setState(() {
        _uploadResult = "Photo uploaded successfully!";
      });
    } catch (e) {
      setState(() {
        _uploadResult = "An error occurred during upload: $e";
      });
    } finally {
      setState(() {
        _isLoading2 = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    categoryItems = _getList(selectedCategoryGroup);
    _addFeatureField();
  }

  @override
  void dispose() {
    nameController.dispose();
    brandController.dispose();
    priceController.dispose();
    stockController.dispose();
    descriptionController.dispose();

    for (var controller in _featureKeyControllers) {
      controller.dispose();
    }
    for (var controller in _featureValueControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _addFeatureField() {
    setState(() {
      _featureKeyControllers.add(TextEditingController());
      _featureValueControllers.add(TextEditingController());
    });
  }

  void _removeFeatureField(int index) {
    setState(() {
      _featureKeyControllers[index].dispose();
      _featureValueControllers[index].dispose();
      _featureKeyControllers.removeAt(index);
      _featureValueControllers.removeAt(index);
    });
  }

  List<CategoryItemModel> _getList(int id) {
    switch (id) {
      case 1:
        return [
          CategoryItemModel('Dress', 5),
          CategoryItemModel('Mask', 6),
          CategoryItemModel('Diving Tank', 7),
          CategoryItemModel('Palette', 8),
          CategoryItemModel('Snorkel', 9),
        ];
      case 2:
        return [
          CategoryItemModel('Mask', 10),
          CategoryItemModel('Dress', 11),
          CategoryItemModel('Palette', 12),
          CategoryItemModel('Glove', 13),
          CategoryItemModel('Harpoon', 14),
        ];
      case 3:
        return [
          CategoryItemModel('Shoes and Slippers', 15),
          CategoryItemModel('Bonnet', 16),
          CategoryItemModel('Pool Bag', 17),
          CategoryItemModel('Swim Goggles', 18),
          CategoryItemModel('Mask-Snorkel', 19),
        ];
      default:
        return [];
    }
  }

  Future<bool> postProductToApi(Map<String, dynamic> productData) async {
    String apiUrl = '$API_BASE_URL/api/Product';

    try {
      print('Sent product data: ${jsonEncode(productData)}');

      final response = await http.post(
        Uri.parse(apiUrl),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(productData),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        print(
          'Product added successfully. Status code: ${response.statusCode}',
        );
        print('Response body: ${response.body}');
        return true;
      } else {
        print('Failed to add product. Status code: ${response.statusCode}');
        print('Response body: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error sending product to API: $e');
      return false;
    }
  }

  Future<void> _addProduct() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (selectedCategoryItem == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a category')));
      return;
    }

    setState(() {
      _isLoading = true;
    });

    Map<String, dynamic> featuresMap = {};
    for (int i = 0; i < _featureKeyControllers.length; i++) {
      String key = _featureKeyControllers[i].text.trim();
      String value = _featureValueControllers[i].text.trim();
      if (key.isNotEmpty && value.isNotEmpty) {
        featuresMap[key] = value;
      }
    }

    DateTime now = DateTime.now();

    final productData = {
      "name": nameController.text,
      "categoryId": selectedCategoryItem!.id,
      "category": null,
      "description":
          descriptionController.text.isEmpty
              ? null
              : descriptionController.text,
      "mainPictureUrl":
          "https://scuba-diving-s3-bucket.s3.eu-north-1.amazonaws.com/products/${nameController.text}-1",
      "brand": brandController.text,
      "price": double.parse(priceController.text),
      "discountPrice": 0.0,
      "stock": int.parse(stockController.text),
      "rating": null,
      "reviewCount": 0,
      "features": featuresMap,
      "isActive": true,
      "favoriteCount": 0,
      "createdAt": now.toIso8601String(),
      "updatedAt": now.toIso8601String(),
    };

    bool success = await postProductToApi(productData);

    setState(() {
      _isLoading = false;
    });

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Product added successfully!')),
      );

      nameController.clear();
      brandController.clear();
      priceController.clear();
      stockController.clear();
      descriptionController.clear();
      setState(() {
        selectedCategoryGroup = 1;
        categoryItems = _getList(selectedCategoryGroup);
        selectedCategoryItem = null;

        for (var controller in _featureKeyControllers) {
          controller.dispose();
        }
        for (var controller in _featureValueControllers) {
          controller.dispose();
        }
        _featureKeyControllers.clear();
        _featureValueControllers.clear();
        _addFeatureField();
      });
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to add product.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Add New Product',
          style: GoogleFonts.playfair(color: ColorPalette.white),
        ),
        backgroundColor: ColorPalette.primary,
        iconTheme: IconThemeData(color: ColorPalette.white),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child:
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        DropdownButtonFormField<int>(
                          value: selectedCategoryGroup,
                          decoration: const InputDecoration(
                            labelText: 'Category Group',
                            border: OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(value: 1, child: Text('Scuba')),
                            DropdownMenuItem(
                              value: 2,
                              child: Text('Spearfishing'),
                            ),
                            DropdownMenuItem(value: 3, child: Text('Swimming')),
                          ],
                          onChanged: (int? newValue) {
                            if (newValue != null) {
                              setState(() {
                                selectedCategoryGroup = newValue;
                                categoryItems = _getList(newValue);
                                selectedCategoryItem = null;
                              });
                            }
                          },
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<CategoryItemModel>(
                          value: selectedCategoryItem,
                          decoration: const InputDecoration(
                            labelText: 'Category',
                            border: OutlineInputBorder(),
                          ),
                          items:
                              categoryItems
                                  .map(
                                    (category) =>
                                        DropdownMenuItem<CategoryItemModel>(
                                          value: category,
                                          child: Text(category.name),
                                        ),
                                  )
                                  .toList(),
                          onChanged: (CategoryItemModel? newCategory) {
                            setState(() {
                              selectedCategoryItem = newCategory;
                            });
                          },
                          validator:
                              (value) =>
                                  value == null
                                      ? 'Please select a category'
                                      : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: nameController,
                          decoration: const InputDecoration(
                            labelText: 'Product Name',
                            border: OutlineInputBorder(),
                          ),
                          validator:
                              (value) =>
                                  value!.isEmpty
                                      ? 'Please enter a product name'
                                      : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: brandController,
                          decoration: const InputDecoration(
                            labelText: 'Brand',
                            border: OutlineInputBorder(),
                          ),
                          validator:
                              (value) =>
                                  value!.isEmpty
                                      ? 'Please enter a brand'
                                      : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: priceController,
                          decoration: const InputDecoration(
                            labelText: 'Price',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter a price';
                            }
                            if (double.tryParse(value) == null) {
                              return 'Please enter a valid number';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: stockController,
                          decoration: const InputDecoration(
                            labelText: 'Stock',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter stock quantity';
                            }
                            if (int.tryParse(value) == null) {
                              return 'Please enter a valid integer';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: descriptionController,
                          decoration: const InputDecoration(
                            labelText: 'Description',
                            border: OutlineInputBorder(),
                          ),
                          maxLines: 3,
                        ),
                        const SizedBox(height: 24),

                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Features',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _featureKeyControllers.length,
                          itemBuilder: (context, index) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      controller: _featureKeyControllers[index],
                                      decoration: const InputDecoration(
                                        labelText: 'Feature Name',
                                        border: OutlineInputBorder(),
                                        isDense: true,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: TextFormField(
                                      controller:
                                          _featureValueControllers[index],
                                      decoration: const InputDecoration(
                                        labelText: 'Value',
                                        border: OutlineInputBorder(),
                                        isDense: true,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.remove_circle_outline,
                                    ),
                                    onPressed: () => _removeFeatureField(index),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton.icon(
                            onPressed: _addFeatureField,
                            icon: const Icon(Icons.add),
                            label: const Text('Add Feature'),
                          ),
                        ),
                        const SizedBox(height: 24),
                        GestureDetector(
                          onTap: _isLoading ? null : _uploadImage,
                          child: Container(
                            alignment: Alignment.center,
                            width: width * 0.4,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              color: ColorPalette.primary,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  Icon(Icons.photo, color: Colors.white),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        if (_isLoading)
                          const CircularProgressIndicator()
                        else if (_uploadResult != null)
                          Text(
                            _uploadResult!,
                            style: TextStyle(
                              color:
                                  _uploadResult!.contains("error")
                                      ? Colors.red
                                      : Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        GestureDetector(
                          onTap: _addProduct,
                          child: Container(
                            alignment: Alignment.center,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              color: ColorPalette.primary,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Text(
                                'Add Product',
                                style: TextStyle(
                                  fontSize: 22,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
      ),
    );
  }
}

class CategoryItemModel {
  final String name;
  final int id;

  CategoryItemModel(this.name, this.id);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CategoryItemModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
