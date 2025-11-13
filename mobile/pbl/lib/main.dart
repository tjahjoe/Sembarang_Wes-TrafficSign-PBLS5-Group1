import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'dart:convert';
import 'package:http/http.dart' as http;

void main() {
  runApp(const MyDJApp());
}

class MyDJApp extends StatefulWidget {
  const MyDJApp({super.key});

  @override
  State<MyDJApp> createState() => _MyDJAppState();
}

class _MyDJAppState extends State<MyDJApp> {
  File? _image;
  String? _result;
  bool _loading = false;

  // Server to POST images for prediction. Change if your server runs elsewhere.
  static const String SERVER_URL = 'http://127.0.0.1:5000';

  // Ambil gambar dari galeri
  Future<void> _pickAndPredict() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return;
    _processImage(pickedFile);
  }

  // Ambil gambar dari kamera
  Future<void> _captureFromCamera() async {
    // Cek apakah platform mendukung kamera
    if (!Platform.isAndroid && !Platform.isIOS) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Fitur kamera tidak tersedia di platform ini.')),
        );
      }
      return;
    }
    
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.camera);
    if (pickedFile == null) return;
    _processImage(pickedFile);
  }

  // Proses gambar (kirim ke server untuk prediksi)
  Future<void> _processImage(XFile pickedFile) async {
    setState(() {
      _image = File(pickedFile.path);
      _loading = true;
      _result = null;
    });

    try {
      // Use multipart/form-data to POST the image file under field name 'image'
      final uri = Uri.parse('$SERVER_URL/predict-svm');
      final request = http.MultipartRequest('POST', uri);
      request.files.add(await http.MultipartFile.fromPath('image', pickedFile.path));

      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);

      if (response.statusCode == 200) {
        final Map<String, dynamic> body = jsonDecode(response.body);
        if (body['success'] == true && body['prediction'] != null) {
          final pred = body['prediction'];
          final labelName = pred['label_name'] ?? 'unknown';
          final labelIndex = pred['label_index'] ?? 'unknown';
          setState(() {
            _result = 'Prediksi: $labelName (index: $labelIndex)';
          });
        } else if (body['error'] != null) {
          setState(() {
            _result = 'Server error: ${body['error']}';
          });
        } else {
          setState(() {
            _result = 'Tidak ada prediksi pada response.';
          });
        }
      } else {
        setState(() {
          _result = 'Request gagal: HTTP ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _result = '❌ Error saat mengirim ke server: $e';
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.amber,
          brightness: Brightness.light,
        ),
      ),
      home: Scaffold(
        appBar: AppBar(
          title: const Row(
            children: [
              Icon(Icons.traffic, size: 28),
              SizedBox(width: 10),
              Text("Traffic Sign Detection"),
            ],
          ),
          centerTitle: false,
          elevation: 2,
          backgroundColor: const Color(0xFF1A1A1A), // Dark road color
          foregroundColor: Colors.white,
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                const Color(0xFF2A2A2A), // Dark gray (road)
                const Color(0xFF4A4A4A), // Lighter gray
              ],
            ),
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Image Preview Card
                    Card(
                      elevation: 8,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                          color: Colors.amber.shade400,
                          width: 2,
                        ),
                      ),
                      child: Container(
                        height: 280,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          color: Colors.grey[200],
                        ),
                        child: _image != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(14),
                                child: Image.file(
                                  _image!,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.image_search,
                                      size: 80,
                                      color: Colors.grey[400],
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      'Pilih Gambar Traffic Sign',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.grey[600],
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Buttons Section
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Gallery Button
                        ElevatedButton.icon(
                          onPressed: _loading ? null : _pickAndPredict,
                          icon: const Icon(Icons.image, size: 24),
                          label: const Text(
                            "Pilih dari Galeri",
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.amber.shade600,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 4,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Camera Button
                        if (Platform.isAndroid || Platform.isIOS)
                          ElevatedButton.icon(
                            onPressed: _loading ? null : _captureFromCamera,
                            icon: const Icon(Icons.camera_alt, size: 24),
                            label: const Text(
                              "Ambil Foto Kamera",
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange.shade600,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 4,
                            ),
                          )
                        else
                          Tooltip(
                            message: "Fitur kamera tidak tersedia di Windows",
                            child: ElevatedButton.icon(
                              onPressed: null,
                              icon: const Icon(Icons.camera_alt, size: 24),
                              label: const Text(
                                "Ambil Foto Kamera (N/A)",
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.grey.shade400,
                                foregroundColor: Colors.grey.shade700,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 28),

                    // Loading & Result Section
                    if (_loading)
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.blueAccent.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.blueAccent, width: 1.5),
                        ),
                        child: Column(
                          children: [
                            const CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.blueAccent),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Menganalisis gambar...',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      )
                    else if (_result != null)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: _result!.startsWith('❌')
                              ? Colors.redAccent.withOpacity(0.2)
                              : Colors.greenAccent.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _result!.startsWith('❌')
                                ? Colors.redAccent
                                : Colors.greenAccent,
                            width: 1.5,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  _result!.startsWith('❌') ? Icons.error : Icons.check_circle,
                                  color: _result!.startsWith('❌')
                                      ? Colors.redAccent
                                      : Colors.greenAccent,
                                  size: 24,
                                ),
                                const SizedBox(width: 12),
                                const Expanded(
                                  child: Text(
                                    'Hasil Prediksi',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              _result!,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
