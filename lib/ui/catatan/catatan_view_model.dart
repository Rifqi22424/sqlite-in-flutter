import 'package:flutter/foundation.dart';

import '../../data/services/catatan_database.dart';
import '../../domain/models/catatan.dart';

/// Logika layar catatan.
///
/// Setiap aksi pengguna ditulis dengan pola yang sama:
/// tulis ke database dulu, lalu muat ulang daftar dari database.
/// Dengan begitu, yang tampil di layar selalu sama dengan isi database.
class CatatanViewModel extends ChangeNotifier {
  CatatanViewModel({required CatatanDatabase database}) : _database = database;

  final CatatanDatabase _database;

  List<Catatan> _daftar = [];
  List<Catatan> get daftar => _daftar;

  bool _memuat = false;
  bool get memuat => _memuat;

  Object? _error;
  Object? get error => _error;

  /// Filter mata kuliah. null = semua.
  String? _filter;
  String? get filter => _filter;

  Future<void> muat() async {
    _memuat = true;
    _error = null;
    notifyListeners();
    try {
      _daftar = await _database.ambilSemua(mataKuliah: _filter);
    } catch (e) {
      _error = e;
    } finally {
      _memuat = false;
      notifyListeners();
    }
  }

  Future<void> pilihFilter(String? mataKuliah) {
    _filter = mataKuliah;
    return muat();
  }

  /// Catatan tanpa id adalah catatan baru (INSERT), selain itu UPDATE.
  Future<void> simpan(Catatan catatan) async {
    if (catatan.id == null) {
      await _database.tambah(catatan);
    } else {
      await _database.ubah(catatan);
    }
    await muat();
  }

  Future<void> sematkan(Catatan catatan) async {
    await _database.ubah(catatan.copyWith(disematkan: !catatan.disematkan));
    await muat();
  }

  Future<void> hapus(Catatan catatan) async {
    // Hilangkan dari layar dulu (wajib untuk Dismissible), baru dari database.
    _daftar = _daftar.where((c) => c.id != catatan.id).toList();
    notifyListeners();
    await _database.hapus(catatan.id!);
    await muat();
  }

  /// Isi 3 catatan contoh sekaligus (batch), untuk mencoba aplikasi.
  Future<void> isiContoh() async {
    final sekarang = DateTime.now();
    await _database.tambahBanyak([
      Catatan(
        judul: 'Normalisasi tabel',
        mataKuliah: 'Basis Data',
        isi: 'Satu tabel untuk satu hal. Data yang berulang dipisah ke tabel lain.',
        dibuat: sekarang.subtract(const Duration(days: 2)),
      ),
      Catatan(
        judul: 'StatelessWidget vs StatefulWidget',
        mataKuliah: 'Pemrograman Mobile',
        isi: 'Stateful dipakai jika tampilan berubah karena data di dalam widget.',
        dibuat: sekarang.subtract(const Duration(days: 1)),
      ),
      Catatan(
        judul: 'Persiapan presentasi',
        mataKuliah: 'Etika Profesi',
        isi: 'Kelompok 3, studi kasus kebocoran data. Slide maksimal 10.',
        dibuat: sekarang,
      ),
    ]);
    await muat();
  }

  // ---- Aturan isian formulir ----

  static String? validasiJudul(String? value) {
    if (value == null || value.trim().isEmpty) return 'Judul wajib diisi';
    return null;
  }
}
