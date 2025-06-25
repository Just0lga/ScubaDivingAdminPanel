/*import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart';
import 'package:scuba_diving_admin_panel/main.dart';

class S3Uploader {
  final ImagePicker _picker = ImagePicker();

  // Dosya uzantısına göre content type dönen fonksiyon

  String getContentType(String fileName) {
    final ext = fileName.toLowerCase();
    if (ext.endsWith('.png')) return 'image/png';
    if (ext.endsWith('.webp')) return 'image/webp';
    return 'image/jpeg';
  }

  Future<void> pickAndUploadImage(int id) async {
    try {
      // 1. Fotoğraf seçimi
      final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile == null) {
        print("❗ Fotoğraf seçilmedi.");
        return;
      }

      final file = File(pickedFile.path);
      final fileName = basename(file.path);
      print("📷 Seçilen dosya: $fileName");

      // ContentType belirle
      final contentType = getContentType(fileName);
      String contentType2 = contentType.split('/').last;
      print("xxxxxx$contentType");
      print("xxxxxx$contentType2");

      // 2. Presigned URL alma, contentType parametresini gönderiyoruz
      final urlResponse = await http.get(
        Uri.parse(
          "$API_BASE_URL/api/S3/presigned-url?fileName=${id}-1.${contentType2}&contentType=$contentType",
        ),
      );

      if (urlResponse.statusCode != 200) {
        print("❗ Presigned URL alınamadı. Kod: ${urlResponse.statusCode}");
        print("Yanıt: ${urlResponse.body}");
        return;
      }

      final presignedUrl = urlResponse.body.replaceAll('"', '');
      print("🔗 Presigned URL: $presignedUrl");

      // 3. Dosyayı byte olarak oku
      final fileBytes = await file.readAsBytes();
      print("📦 Dosya boyutu: ${fileBytes.length} byte");

      // 4. PUT isteği ile yükleme, Content-Type header olarak gönderiliyor
      final putResponse = await http.put(
        Uri.parse(presignedUrl),
        headers: {"Content-Type": contentType},
        body: fileBytes,
      );

      print("📤 PUT yanıt kodu: ${putResponse.statusCode}");
      print("📤 PUT yanıt body: ${putResponse.body}");
      print("Presigned URL: $presignedUrl");
      print("Flutter UTC Saati: ${DateTime.now().toUtc()}");

      if (putResponse.statusCode == 200) {
        print("✅ Yükleme başarılı!");
      } else {
        print("❌ Yükleme başarısız. Hata kodu: ${putResponse.statusCode}");
      }
    } catch (e) {
      print("⚠️ Hata oluştu: $e");
    }
  }
}
*/
