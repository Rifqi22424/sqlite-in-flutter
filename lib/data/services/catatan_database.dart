import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../../domain/models/catatan.dart';

/// Database SQLite di dalam HP untuk catatan kuliah.
///
/// Setiap method CRUD mengikuti RESEP 3 LANGKAH yang sama:
///   1. Buka database
///   2. Jalankan perintah (insert, query, update, delete)
///   3. Ubah hasilnya menjadi objek (hanya saat membaca)
class CatatanDatabase {
  /// Lokasi file database. Saat testing diisi `inMemoryDatabasePath`
  /// (lihat test/data/catatan_database_test.dart).
  CatatanDatabase({this.path});

  final String? path;

  /// Naikkan angka ini setiap kali struktur tabel berubah.
  /// Versi 1: rilis pertama. Versi 2: tambah kolom `disematkan`.
  static const versi = 2;

  Database? _db;

  /// Buka database. Jika file belum ada, `onCreate` membuat tabelnya.
  /// Jika file berasal dari versi lama, `onUpgrade` memperbaruinya.
  Future<Database> _buka() async {
    if (_db != null) return _db!;

    final lokasi = path ?? join(await getDatabasesPath(), 'nusacatat.db');
    _db = await openDatabase(
      lokasi,
      version: versi,
      onCreate: _buatTabel,
      onUpgrade: _migrasi,
    );
    return _db!;
  }

  /// Instal baru: langsung buat tabel versi TERBARU.
  Future<void> _buatTabel(Database db, int version) async {
    await db.execute('''
      CREATE TABLE catatan(
        id          INTEGER PRIMARY KEY AUTOINCREMENT,
        judul       TEXT NOT NULL,
        mata_kuliah TEXT NOT NULL,
        isi         TEXT NOT NULL,
        dibuat      TEXT NOT NULL,
        disematkan  INTEGER NOT NULL DEFAULT 0
      )
    ''');
  }

  /// Update aplikasi: file lama tetap ada, jadi ubah tabelnya tanpa
  /// menghapus data. Satu blok `if` untuk setiap kenaikan versi.
  Future<void> _migrasi(Database db, int versiLama, int versiBaru) async {
    if (versiLama < 2) {
      await db.execute(
        'ALTER TABLE catatan ADD COLUMN disematkan INTEGER NOT NULL DEFAULT 0',
      );
    }
  }

  /// CREATE: simpan catatan baru. Hasilnya id yang dibuat SQLite.
  Future<int> tambah(Catatan catatan) async {
    // 1. Buka database
    final db = await _buka();

    // 2. Jalankan perintah. Objek diubah dulu menjadi Map (baris tabel).
    return db.insert('catatan', catatan.toMap());
  }

  /// READ: ambil catatan, yang disematkan di atas, lalu yang terbaru.
  /// Jika [mataKuliah] diisi, hanya catatan mata kuliah itu.
  Future<List<Catatan>> ambilSemua({String? mataKuliah}) async {
    // 1. Buka database
    final db = await _buka();

    // 2. Jalankan perintah: SELECT * FROM catatan WHERE ... ORDER BY ...
    final rows = await db.query(
      'catatan',
      where: mataKuliah == null ? null : 'mata_kuliah = ?',
      whereArgs: mataKuliah == null ? null : [mataKuliah],
      orderBy: 'disematkan DESC, dibuat DESC',
    );

    // 3. Ubah hasilnya (List<Map>) menjadi objek
    return rows.map((row) => Catatan.fromMap(row)).toList();
  }

  /// UPDATE: simpan perubahan satu catatan.
  Future<void> ubah(Catatan catatan) async {
    // 1. Buka database
    final db = await _buka();

    // 2. Jalankan perintah. Tanpa where, SEMUA baris ikut berubah.
    await db.update(
      'catatan',
      catatan.toMap(),
      where: 'id = ?',
      whereArgs: [catatan.id],
    );
  }

  /// DELETE: hapus satu catatan.
  Future<void> hapus(int id) async {
    // 1. Buka database
    final db = await _buka();

    // 2. Jalankan perintah
    await db.delete('catatan', where: 'id = ?', whereArgs: [id]);
  }

  /// Simpan banyak catatan sekaligus dengan batch.
  /// Semua perintah dikirim bersama: berhasil semua, atau gagal semua.
  Future<void> tambahBanyak(List<Catatan> daftar) async {
    final db = await _buka();
    final batch = db.batch();
    for (final catatan in daftar) {
      batch.insert('catatan', catatan.toMap());
    }
    await batch.commit(noResult: true);
  }

  /// Tutup database. Dipakai di test dan saat aplikasi ditutup.
  Future<void> close() async {
    await _db?.close();
    _db = null;
  }
}
