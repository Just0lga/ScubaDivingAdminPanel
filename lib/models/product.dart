import 'package:freezed_annotation/freezed_annotation.dart';

part 'product.freezed.dart';
part 'product.g.dart';

@freezed
class Product with _$Product {
  const factory Product({
    required int id,
    required String name,
    required int categoryId,
    required String brand,
    required double price,
    @Default(0.0) double discountPrice,
    required int stock,
    String? description,
    @Default(0) int reviewCount,
    Map<String, dynamic>? features,
    @Default(true) bool isActive,
    @Default(0) int favoriteCount,
    required DateTime createdAt,
    required DateTime updatedAt,
    required String mainPictureUrl,
  }) = _Product;

  factory Product.fromJson(Map<String, dynamic> json) =>
      _$ProductFromJson(json);
}
