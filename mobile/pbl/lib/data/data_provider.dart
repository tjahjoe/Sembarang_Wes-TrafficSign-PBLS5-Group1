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
  File? _image;
  String? _result;
  bool _loading = false;
  List<Map<String, dynamic>> _detections = [];
  double? _origImageWidth;
  double? _origImageHeight;
  String? _predictionMethod;
  int _minConfidence = 75;
  bool _showMethodAlert = false;

  File? get image => _image;
  String? get result => _result;
  bool get isLoading => _loading;
  List<Map<String, dynamic>> get detections => _detections;
  double? get origImageWidth => _origImageWidth;
  double? get origImageHeight => _origImageHeight;
  String? get predictionMethod => _predictionMethod;
  int get minConfidence => _minConfidence;
  bool get showMethodAlert => _showMethodAlert;

  void setMinConfidence(int value) {
    _minConfidence = value;
    notifyListeners();
  }

  // Set IP sesuai dengan server yang digunakan
  static const String SERVER_URL = 'https://elchilz-sembarang-wes.hf.space';

  void setPredictionMethod(String method) {
    if (_predictionMethod == method) {
      _predictionMethod = null;
      _result = null;
      _image = null;
      _detections.clear();
    } else {
      _predictionMethod = method;
      _showMethodAlert = false; // Reset alert ketika metode dipilih
    }
    notifyListeners();
  }

  void cancelPredictionMethod() {
    _predictionMethod = null;
    notifyListeners();
  }

  Future<bool> isLoggedIn() async {
    LoginInfo loginInfo = await LoginInfo.fromSharedPreferences();
    return loginInfo.isLoggedIn;
  }

  Future<void> saveLoginInfo(String username, String password) async {
    LoginInfo loginInfo = await LoginInfo.fromSharedPreferences();
    loginInfo.username = username;
    loginInfo.password = password;
    loginInfo.isLoggedIn = true;
    loginInfo.saveToSharedPreferences();
  }

  // Fungsi untuk Gallery (Butuh Metode SVM/RF)
  Future<void> pickAndPredict() async {
    if (_predictionMethod == null) {
      // Tampilkan alert merah
      _showMethodAlert = true;
      notifyListeners();
      return;
    }

    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return;

    await _processImage(pickedFile);
  }

  // Fungsi untuk Kamera (LANGSUNG YOLO, TIDAK BUTUH METODE DIPILIH)
  Future<void> captureFromCamera(BuildContext context) async {
    if (!Platform.isAndroid && !Platform.isIOS) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Fitur kamera tidak tersedia di platform ini.'),
        ),
      );
      return;
    }

    // --- PERBAIKAN: Hapus pengecekan _predictionMethod di sini ---
    // Karena kamera otomatis pakai YOLO.

    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.camera);
    if (pickedFile == null) return;

    // Langsung panggil fungsi YOLO
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
    // Reset prediction method UI agar tidak membingungkan
    _predictionMethod = null;
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
        http.MultipartFile.fromBytes('image', bytes, filename: pickedFile.name),
      );
      request.fields['min_confidence'] = _minConfidence.toString();

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

          if (dets.isEmpty) {
            _result =
                'Tidak terdeteksi karena confidence dibawah $_minConfidence%';
          } else {
            final classesString = dets
                .map((d) {
                  final name = d['class_name'] ?? 'obj';
                  final conf = d['confidence'];
                  return "$name ($conf%)";
                })
                .join(', ');
            _result = 'Terdeteksi: ${dets.length} objek\nClass: $classesString';
          }
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
    // Jika tombol Galeri memanggil ini

    _image = File(pickedFile.path);
    _loading = true;
    _result = null;
    notifyListeners();

    try {
      // Pastikan metode dipilih (Hanya untuk Galeri/SVM/RF)
      if (_predictionMethod == null) {
        _result = 'Metode prediksi belum dipilih.';
        _loading = false;
        notifyListeners();
        return;
      }

      final endpoint = _predictionMethod == 'svm'
          ? '/predict-svm'
          : '/predict-rf';
      final uri = Uri.parse('$SERVER_URL$endpoint');
      final request = http.MultipartRequest('POST', uri);
      request.files.add(
        await http.MultipartFile.fromPath('image', pickedFile.path),
      );
      request.fields['min_confidence'] = _minConfidence.toString();

      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);

      if (response.statusCode == 200) {
        final Map<String, dynamic> body = jsonDecode(response.body);

        if (body['success'] == true && body['prediction'] != null) {
          final pred = body['prediction'];
          final labelName = pred['label_name'] ?? 'unknown';

          double confidenceRaw = 0.0;
          if (pred['confidence'] != null)
            confidenceRaw = (pred['confidence'] as num).toDouble();
          else if (pred['probability'] != null)
            confidenceRaw = (pred['probability'] as num).toDouble();
          else if (pred['score'] != null)
            confidenceRaw = (pred['score'] as num).toDouble();

          double confidencePercent = confidenceRaw;
          if (confidenceRaw <= 1.0) {
            confidencePercent = confidenceRaw * 100;
          }

          if (confidencePercent < _minConfidence) {
            _result =
                'Tidak terdeteksi karena confidence dibawah $_minConfidence%';
          } else {
            final methodName = _predictionMethod == 'svm'
                ? 'SVM'
                : 'Random Forest';
            final confString = confidencePercent.toStringAsFixed(1);
            _result = 'Prediksi ($methodName): $labelName ($confString%)';
          }
        } else {
          _result =
              'Tidak terdeteksi karena confidence dibawah $_minConfidence%';
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
