import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart';
import 'package:scuba_diving_admin_panel/main.dart';

class S3Uploader {
  final ImagePicker _picker = ImagePicker();

  String getContentType(String fileName) {
    final ext = fileName.toLowerCase();
    if (ext.endsWith('.png')) return 'image/png';
    if (ext.endsWith('.webp')) return 'image/webp';
    return 'image/jpeg';
  }

  Future<void> pickAndUploadImage(String name) async {
    try {
      final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile == null) {
        print("❗ No image selected.");
        return;
      }

      final file = File(pickedFile.path);
      final fileName = basename(file.path);
      print("📷 Selected file: $fileName");

      final contentType = getContentType(fileName);
      String contentType2 = contentType.split('/').last;
      print("xxxxxx$contentType");
      print("xxxxxx$contentType2");

      final urlResponse = await http.get(
        Uri.parse(
          "$API_BASE_URL/api/S3/presigned-url?fileName=${name}-1.${contentType2}&contentType=$contentType",
        ),
      );

      if (urlResponse.statusCode != 200) {
        print("❗ Failed to get presigned URL. Code: ${urlResponse.statusCode}");
        print("Response: ${urlResponse.body}");
        return;
      }

      final presignedUrl = urlResponse.body.replaceAll('"', '');
      print("🔗 Presigned URL: $presignedUrl");

      final fileBytes = await file.readAsBytes();
      print("📦 File size: ${fileBytes.length} bytes");

      final putResponse = await http.put(
        Uri.parse(presignedUrl),
        headers: {"Content-Type": contentType},
        body: fileBytes,
      );

      print("📤 PUT response code: ${putResponse.statusCode}");
      print("📤 PUT response body: ${putResponse.body}");
      print("Presigned URL: $presignedUrl");
      print("Flutter UTC Time: ${DateTime.now().toUtc()}");

      if (putResponse.statusCode == 200) {
        print("✅ Upload successful!");
      } else {
        print("❌ Upload failed. Error code: ${putResponse.statusCode}");
      }
    } catch (e) {
      print("⚠️ An error occurred: $e");
    }
  }
}
