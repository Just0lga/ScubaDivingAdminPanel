import 'dart:html' as html;
import 'package:http/http.dart' as http;
import 'package:scuba_diving_admin_panel/main.dart';

class S3UploaderWeb {
  // contentType döndürme fonksiyonu aynı kalabilir

  String getContentType(String fileName) {
    final ext = fileName.toLowerCase();
    if (ext.endsWith('.png')) return 'image/png';
    if (ext.endsWith('.webp')) return 'image/webp';
    return 'image/jpeg';
  }

  Future<void> pickAndUploadImage(String name) async {
    try {
      // 1. Dosya seç (input element)
      final input = html.FileUploadInputElement();
      input.accept = 'image/*';
      input.click();

      await input.onChange.first;

      if (input.files == null || input.files!.isEmpty) {
        print("❗ Fotoğraf seçilmedi.");
        return;
      }

      final file = input.files!.first;
      final fileName = file.name;
      print("📷 Seçilen dosya: $fileName");

      final contentType = getContentType(fileName);
      String contentType2 = contentType.split('/').last;

      // 2. Presigned URL alma
      final urlResponse = await http.get(
        Uri.parse(
          "$API_BASE_URL/api/S3/presigned-url?fileName=${name}-1.${contentType2}&contentType=$contentType",
        ),
      );

      if (urlResponse.statusCode != 200) {
        print("❗ Presigned URL alınamadı. Kod: ${urlResponse.statusCode}");
        print("Yanıt: ${urlResponse.body}");
        return;
      }

      final presignedUrl = urlResponse.body.replaceAll('"', '');
      print("🔗 Presigned URL: $presignedUrl");

      // 3. Dosyayı byte dizisine oku
      final reader = html.FileReader();
      reader.readAsArrayBuffer(file);
      await reader.onLoad.first;
      final fileBytes = reader.result as List<int>;

      print("📦 Dosya boyutu: ${fileBytes.length} byte");

      // 4. PUT isteği
      final putResponse = await http.put(
        Uri.parse(presignedUrl),
        headers: {"Content-Type": contentType},
        body: fileBytes,
      );

      print("📤 PUT yanıt kodu: ${putResponse.statusCode}");
      if (putResponse.statusCode == 200) {
        print("✅ Yükleme başarılı!");
      } else {
        print("❌ Yükleme başarısız.");
      }
    } catch (e) {
      print("⚠️ Hata oluştu: $e");
    }
  }
}
