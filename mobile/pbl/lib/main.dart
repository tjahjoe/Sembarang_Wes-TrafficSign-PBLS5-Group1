import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
// import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
// import 'package:image/image.dart' as img;
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
  List<Map<String, dynamic>> _detections = [];
  double? _origImageWidth;
  double? _origImageHeight;

  static const String SERVER_URL = 'http://192.168.70.78:5000';
  Future<void> _pickAndPredict() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return;
    _processImage(pickedFile);
  }

  Future<void> _captureFromCamera() async {
    if (!Platform.isAndroid && !Platform.isIOS) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Fitur kamera tidak tersedia di platform ini.'),
          ),
        );
      }
      return;
    }

    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.camera);
    if (pickedFile == null) return;
    await _processImageYolo(pickedFile);
  }

  Future<void> _processImageYolo(XFile pickedFile) async {
    setState(() {
      _loading = true;
      _result = null;
      _detections = [];
    });

    try {
      final bytes = await pickedFile.readAsBytes();

      final uiImage = await _decodeImage(bytes);
      _origImageWidth = uiImage.width.toDouble();
      _origImageHeight = uiImage.height.toDouble();

      setState(() {
        _image = File(pickedFile.path);
      });

      final uri = Uri.parse('$SERVER_URL/predict-yolo');
      final request = http.MultipartRequest('POST', uri);
      request.files.add(
        http.MultipartFile.fromBytes(
          'image',
          bytes,
          // filename: pickedFile.name ?? 'image.jpg',
          filename: pickedFile.name,
        ),
      );

      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);

        if (body is List) {
          final List<Map<String, dynamic>> dets = [];

          for (final item in body) {
            if (item is Map<String, dynamic>) {
              dets.add(item);
            } else if (item is Map) {
              dets.add(Map<String, dynamic>.from(item));
            }
          }

          setState(() {
            _detections = dets;

            final classes = dets.map((d) => d['class_name'] ?? 'obj').toList();

            final classesString = classes.join(', ');

            _result = 'Terdeteksi: ${dets.length} objek\nClass: $classesString';
          });
        } else if (body is Map && body['error'] != null) {
          setState(() {
            _result = 'Server error: ${body['error']}';
          });
        } else {
          setState(() {
            _result = 'Response tidak dalam format deteksi.';
          });
        }
      } else {
        setState(() {
          _result = 'Request gagal: HTTP ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _result = 'Error saat mengirim ke server: $e';
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  Future<ui.Image> _decodeImage(Uint8List bytes) {
    final completer = Completer<ui.Image>();
    ui.decodeImageFromList(bytes, (ui.Image img) {
      completer.complete(img);
    });
    return completer.future;
  }

  Future<void> _processImage(XFile pickedFile) async {
    setState(() {
      _image = File(pickedFile.path);
      _loading = true;
      _result = null;
    });

    try {
      final uri = Uri.parse('$SERVER_URL/predict-svm');
      final request = http.MultipartRequest('POST', uri);
      request.files.add(
        await http.MultipartFile.fromPath('image', pickedFile.path),
      );

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
        _result = 'Error saat mengirim ke server: $e';
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
      debugShowCheckedModeBanner: false,
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
          backgroundColor: const Color(0xFF1A1A1A),
          foregroundColor: Colors.white,
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [const Color(0xFF2A2A2A), const Color(0xFF4A4A4A)],
            ),
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 24,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_image != null)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade800,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.amber.shade300,
                            width: 1.5,
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(
                              'Gambar Input',
                              style: TextStyle(
                                color: Colors.amber.shade300,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: Colors.amber.shade200,
                                  width: 1,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: Image.file(_image!, fit: BoxFit.cover),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Preview resized untuk model',
                              style: TextStyle(
                                color: Colors.grey.shade400,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 28),
                    // Column(
                    //   crossAxisAlignment: CrossAxisAlignment.stretch,
                    //   children: [
                    //     if (_detections.isNotEmpty)
                    //       Wrap(
                    //         spacing: 8,
                    //         runSpacing: 6,
                    //         children: _detections.map((d) {
                    //           final name = d['class_name'] ?? 'obj';
                    //           final conf = d['confidence'] != null
                    //               ? ((d['confidence'] as num) * 100)
                    //               .toStringAsFixed(0) +
                    //               '%'
                    //               : '';
                    //           return Chip(
                    //             label: Text('$name $conf'),
                    //             backgroundColor: Colors.black54,
                    //             labelStyle: const TextStyle(
                    //               color: Colors.white,
                    //             ),
                    //           );
                    //         }).toList(),
                    //       ),
                    //   ],
                    // ),
                    // const SizedBox(height: 28),

                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ElevatedButton.icon(
                          onPressed: _loading ? null : _pickAndPredict,
                          icon: const Icon(Icons.image, size: 24),
                          label: const Text(
                            "Pilih dari Galeri",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
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

                        if (Platform.isAndroid || Platform.isIOS)
                          ElevatedButton.icon(
                            onPressed: _loading ? null : _captureFromCamera,
                            icon: const Icon(Icons.camera_alt, size: 24),
                            label: const Text(
                              "Ambil Foto Kamera",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
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
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.grey.shade400,
                                foregroundColor: Colors.grey.shade700,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 28),

                    if (_loading)
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.blueAccent.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.blueAccent,
                            width: 1.5,
                          ),
                        ),
                        child: Column(
                          children: [
                            const CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.blueAccent,
                              ),
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
                          color: _result!.startsWith('Error')
                              ? Colors.redAccent.withOpacity(0.2)
                              : Colors.greenAccent.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _result!.startsWith('Error')
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
                                  _result!.startsWith('Error')
                                      ? Icons.error
                                      : Icons.check_circle,
                                  color: _result!.startsWith('Error')
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
