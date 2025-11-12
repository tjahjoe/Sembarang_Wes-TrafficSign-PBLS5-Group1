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

  Future<void> _pickAndPredict() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return;
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
      home: Scaffold(
        appBar: AppBar(title: const Text("Prediksi ONNX di Flutter")),
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _image != null
                  ? Image.file(_image!, height: 200)
                  : const Icon(Icons.image, size: 150, color: Colors.grey),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _loading ? null : _pickAndPredict,
                icon: const Icon(Icons.upload),
                label: const Text("Pilih & Prediksi Gambar"),
              ),
              const SizedBox(height: 20),
              if (_loading) const CircularProgressIndicator(),
              if (_result != null)
                Text(
                  _result!,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
