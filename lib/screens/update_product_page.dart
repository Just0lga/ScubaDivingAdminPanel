import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:scuba_diving_admin_panel/color/color_palette.dart';
import 'package:scuba_diving_admin_panel/main.dart';
import 'package:scuba_diving_admin_panel/models/product.dart';

class UpdateProductPage extends StatefulWidget {
  final Product product;

  const UpdateProductPage({super.key, required this.product});

  @override
  State<UpdateProductPage> createState() => _UpdateProductPageState();
}

class _UpdateProductPageState extends State<UpdateProductPage> {
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false;

  final TextEditingController priceController = TextEditingController();
  final TextEditingController stockController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();

  int selectedCategoryGroup = 1;
  List<CategoryItemModel> categoryItems = [];
  CategoryItemModel? selectedCategoryItem;

  final List<TextEditingController> _featureKeyControllers = [];
  final List<TextEditingController> _featureValueControllers = [];

  @override
  void initState() {
    super.initState();
    priceController.text = widget.product.price.toString();
    stockController.text = widget.product.stock.toString();
    descriptionController.text = widget.product.description ?? '';

    _initializeCategorySelection(widget.product.categoryId);

    if (widget.product.features != null) {
      widget.product.features!.forEach((key, value) {
        _featureKeyControllers.add(TextEditingController(text: key));
        _featureValueControllers.add(TextEditingController(text: value));
      });
    }
    if (_featureKeyControllers.isEmpty) {
      _addFeatureField();
    }
  }

  void _initializeCategorySelection(int categoryId) {
    int? foundGroup;
    CategoryItemModel? foundCategoryItem;

    for (int groupId = 1; groupId <= 3; groupId++) {
      final items = _getList(groupId);
      for (var item in items) {
        if (item.id == categoryId) {
          foundGroup = groupId;
          foundCategoryItem = item;
          break;
        }
      }
      if (foundGroup != null) break;
    }

    setState(() {
      selectedCategoryGroup = foundGroup ?? 1;
      categoryItems = _getList(selectedCategoryGroup);
      selectedCategoryItem = foundCategoryItem;
    });
  }

  @override
  void dispose() {
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

  Future<bool> updateProductToApi(
    int productId,
    Map<String, dynamic> productData,
  ) async {
    final String apiUrl = '$API_BASE_URL/api/Product/$productId';

    try {
      print('Gönderilen ürün güncelleme verisi: ${jsonEncode(productData)}');

      final response = await http.put(
        Uri.parse(apiUrl),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(productData),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        print('Ürün başarıyla güncellendi. Durum kodu: ${response.statusCode}');
        print('Yanıt gövdesi: ${response.body}');
        return true;
      } else {
        print('Ürün güncellenemedi. Durum kodu: ${response.statusCode}');
        print('Yanıt gövdesi: ${response.body}');
        return false;
      }
    } catch (e) {
      print('API\'ye ürün güncelleme hatası: $e');
      return false;
    }
  }

  Future<void> _updateProduct() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (selectedCategoryItem == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen bir kategori seçin')),
      );
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
      "id": widget.product.id,
      "name": widget.product.name,
      "categoryId": selectedCategoryItem!.id,
      "category": widget.product.categoryId,
      "description":
          descriptionController.text.isEmpty
              ? null
              : descriptionController.text,
      "mainPictureUrl": widget.product.mainPictureUrl,
      "brand": widget.product.brand,
      "price": double.parse(priceController.text),
      "discountPrice": widget.product.discountPrice,
      "stock": int.parse(stockController.text),
      "reviewCount": widget.product.reviewCount,
      "features": featuresMap,
      "isActive": widget.product.isActive,
      "favoriteCount": widget.product.favoriteCount,
      "createdAt": widget.product.createdAt.toIso8601String(),
      "updatedAt": now.toIso8601String(),
    };

    bool success = await updateProductToApi(widget.product.id, productData);

    setState(() {
      _isLoading = false;
    });

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ürün başarıyla güncellendi!')),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Ürün güncellenemedi.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Update the Product',
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
                            labelText: 'Kategori Grubu',
                            border: OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(value: 1, child: Text('Scuba')),
                            DropdownMenuItem(
                              value: 2,
                              child: Text('Zıpkın Avcılığı'),
                            ),
                            DropdownMenuItem(value: 3, child: Text('Yüzme')),
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
                            labelText: 'Kategori',
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
                                      ? 'Lütfen bir kategori seçin'
                                      : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: priceController,
                          decoration: const InputDecoration(
                            labelText: 'Fiyat',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Lütfen bir fiyat girin';
                            }
                            if (double.tryParse(value) == null) {
                              return 'Lütfen geçerli bir sayı girin';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: stockController,
                          decoration: const InputDecoration(
                            labelText: 'Stok',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Lütfen stok miktarı girin';
                            }
                            if (int.tryParse(value) == null) {
                              return 'Lütfen geçerli bir tam sayı girin';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: descriptionController,
                          decoration: const InputDecoration(
                            labelText: 'Açıklama',
                            border: OutlineInputBorder(),
                          ),
                          maxLines: 3,
                        ),
                        const SizedBox(height: 24),

                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Özellikler',
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
                                        labelText: 'Özellik Adı',
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
                                        labelText: 'Değer',
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
                            label: const Text('Özellik Ekle'),
                          ),
                        ),
                        const SizedBox(height: 24),
                        GestureDetector(
                          onTap: _updateProduct,
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
                                'Ürünü Güncelle',
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
