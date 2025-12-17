import 'dart:io';
import 'package:flutter/material.dart';
import 'package:pbl/data/data_provider.dart';
import 'package:provider/provider.dart';
import 'package:pbl/data/login_info.dart';
import 'package:pbl/pages/login_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  Future<void> _logout(BuildContext context) async {
    await LoginInfo.deleteFromSharedPreferences();
    if (context.mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => const LoginPage(),
        ),
            (Route<dynamic> route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final dataProvider = context.watch<DataProvider>();
    final _image = dataProvider.image;
    final _loading = dataProvider.isLoading;
    final _result = dataProvider.result;

    final dataProviderFunction = context.read<DataProvider>();

    // --- LOGIKA LIST DROPDOWN ---
    Set<int> dropdownItems = Set.from(List.generate(11, (index) => index * 10));
    dropdownItems.add(dataProvider.minConfidence);
    List<int> sortedItems = dropdownItems.toList()..sort();
    // ----------------------------

    return Scaffold(
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
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            tooltip: 'Keluar',
            onPressed: () => _logout(context),
          )
        ],
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
            child: Container(
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Bagian Pratinjau Gambar
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
                              child: Image.file(_image, fit: BoxFit.cover),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 20),

                  // --- WIDGET DROPDOWN ---
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade800,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade600),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Min. Confidence:",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade600,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<int>(
                              value: dataProvider.minConfidence,
                              dropdownColor: Colors.grey.shade800,
                              icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                              items: sortedItems.map((val) {
                                return DropdownMenuItem<int>(
                                  value: val,
                                  child: Text("$val%"),
                                );
                              }).toList(),
                              onChanged: (int? newValue) {
                                if (newValue != null) {
                                  dataProviderFunction.setMinConfidence(newValue);
                                }
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Pilihan Metode Prediksi
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
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Metode Prediksi (Klasifikasi)',
                          style: TextStyle(
                            color: Colors.amber.shade300,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 12,
                          children: [
                            ChoiceChip(
                              label: const Text('SVM', style: TextStyle(color: Colors.white)),
                              selected: dataProvider.predictionMethod == 'svm',
                              selectedColor: Colors.amber.shade600,
                              backgroundColor: Colors.grey.shade700,
                              onSelected: _loading
                                  ? null
                                  : (_) => dataProviderFunction.setPredictionMethod('svm'),
                            ),
                            ChoiceChip(
                              label: const Text('Random Forest', style: TextStyle(color: Colors.white)),
                              selected: dataProvider.predictionMethod == 'rf',
                              selectedColor: Colors.amber.shade600,
                              backgroundColor: Colors.grey.shade700,
                              onSelected: _loading
                                  ? null
                                  : (_) => dataProviderFunction.setPredictionMethod('rf'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Tombol Aksi
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ElevatedButton.icon(
                        // KEMBALI SEPERTI SEMULA (TANPA CONTEXT)
                        onPressed: _loading ? null : dataProviderFunction.pickAndPredict,
                        icon: const Icon(Icons.image, size: 24),
                        label: const Text("Pilih dari Galeri"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.amber.shade600,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (Platform.isAndroid || Platform.isIOS)
                        ElevatedButton.icon(
                          onPressed: _loading ? null : () => dataProviderFunction.captureFromCamera(context),
                          icon: const Icon(Icons.camera_alt, size: 24),
                          label: const Text("Ambil Foto Kamera"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange.shade600,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        )
                      else
                        ElevatedButton.icon(
                          onPressed: null,
                          icon: const Icon(Icons.camera_alt, size: 24),
                          label: const Text("Ambil Foto Kamera (N/A)"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey.shade400,
                            foregroundColor: Colors.grey.shade700,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 28),

                  // Hasil Prediksi
                  if (_loading)
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.blueAccent.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blueAccent, width: 1.5),
                      ),
                      child: const Column(
                        children: [
                          CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.blueAccent)),
                          SizedBox(height: 12),
                          Text(
                            'Menganalisis gambar...',
                            style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    )
                  else if (_result != null)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _result.startsWith('Error')
                            ? Colors.redAccent.withOpacity(0.2)
                            : _result.contains('Tidak terdeteksi')
                            ? Colors.orangeAccent.withOpacity(0.2)
                            : Colors.greenAccent.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _result.startsWith('Error')
                              ? Colors.redAccent
                              : _result.contains('Tidak terdeteksi')
                              ? Colors.orangeAccent
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
                                _result.startsWith('Error')
                                    ? Icons.error
                                    : _result.contains('Tidak terdeteksi')
                                    ? Icons.warning_amber_rounded
                                    : Icons.check_circle,
                                color: _result.startsWith('Error')
                                    ? Colors.redAccent
                                    : _result.contains('Tidak terdeteksi')
                                    ? Colors.orangeAccent
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
                            _result,
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
    );
  }
}