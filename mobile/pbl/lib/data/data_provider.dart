import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:pbl/data/login_info.dart';

class DataProvider extends ChangeNotifier {
  // --- State Variables ---
  File? _image;
  String? _result;
  bool _loading = false;
  List<Map<String, dynamic>> _detections = [];
  double? _origImageWidth;
  double? _origImageHeight;

  // --- Getters untuk akses UI ---
  File? get image => _image;
  String? get result => _result;
  bool get isLoading => _loading;
  List<Map<String, dynamic>> get detections => _detections;
  double? get origImageWidth => _origImageWidth;
  double? get origImageHeight => _origImageHeight;

  static const String SERVER_URL = 'http://192.168.1.6:5000';

  // --- Logika Pemrosesan Gambar dan Komunikasi Server ---

  Future<bool> isLoggedIn() async
  {
    LoginInfo loginInfo = await LoginInfo.fromSharedPreferences();
    return loginInfo.isLoggedIn;
  }

  Future<void> saveLoginInfo(String username, String password) async
  {
    LoginInfo loginInfo = await LoginInfo.fromSharedPreferences();

    loginInfo.username = username;
    loginInfo.password = password;
    loginInfo.isLoggedIn = true;

    loginInfo.saveToSharedPreferences();
  }

  Future<void> pickAndPredict() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return;
    // Panggil metode prediksi yang digunakan SVM
    await _processImage(pickedFile);
  }

  Future<void> captureFromCamera(BuildContext context) async {
    if (!Platform.isAndroid && !Platform.isIOS) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Fitur kamera tidak tersedia di platform ini.'),
        ),
      );
      return;
    }

    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.camera);
    if (pickedFile == null) return;
    // Panggil metode prediksi yang digunakan YOLO
    await _processImageYolo(pickedFile);
  }

  Future<ui.Image> _decodeImage(Uint8List bytes) {
    final completer = Completer<ui.Image>();
    ui.decodeImageFromList(bytes, (ui.Image img) {
      completer.complete(img);
    });
    return completer.future;
  }

  Future<void> _processImageYolo(XFile pickedFile) async {
    _loading = true;
    _result = null;
    _detections = [];
    notifyListeners();

    try {
      final bytes = await pickedFile.readAsBytes();

      final uiImage = await _decodeImage(bytes);
      _origImageWidth = uiImage.width.toDouble();
      _origImageHeight = uiImage.height.toDouble();

      _image = File(pickedFile.path);

      final uri = Uri.parse('$SERVER_URL/predict-yolo');
      final request = http.MultipartRequest('POST', uri);
      request.files.add(
        http.MultipartFile.fromBytes(
          'image',
          bytes,
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
          _detections = dets;
          final classes = dets.map((d) => d['class_name'] ?? 'obj').toList();
          final classesString = classes.join(', ');
          _result = 'Terdeteksi: ${dets.length} objek\nClass: $classesString';
        } else if (body is Map && body['error'] != null) {
          _result = 'Server error: ${body['error']}';
        } else {
          _result = 'Response tidak dalam format deteksi.';
        }
      } else {
        _result = 'Request gagal: HTTP ${response.statusCode}';
      }
    } catch (e) {
      _result = 'Error saat mengirim ke server: $e';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> _processImage(XFile pickedFile) async {
    _image = File(pickedFile.path);
    _loading = true;
    _result = null;
    notifyListeners();

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
          _result = 'Prediksi: $labelName (index: $labelIndex)';
        } else if (body['error'] != null) {
          _result = 'Server error: ${body['error']}';
        } else {
          _result = 'Tidak ada prediksi pada response.';
        }
      } else {
        _result = 'Request gagal: HTTP ${response.statusCode}';
      }
    } catch (e) {
      _result = 'Error saat mengirim ke server: $e';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}