import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart';
import 'package:sesi12_database_sqlite/data/services/catatan_database.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

// MIGRASI: HP mahasiswa masih menyimpan database dari aplikasi versi 1.
// Setelah aplikasi diperbarui ke versi 2, datanya harus tetap ada
// dan tabelnya punya kolom baru `disematkan`.
//
// Database di memori hilang saat ditutup, jadi test ini memakai file
// sementara supaya bisa "ditutup lalu dibuka lagi" seperti di HP.
void main() {
  late Directory folder;
  late String lokasi;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    folder = await Directory.systemTemp.createTemp('nusacatat_');
    lokasi = join(folder.path, 'nusacatat.db');
  });
  tearDown(() => folder.delete(recursive: true));

  test('database versi 1 naik ke versi 2 tanpa kehilangan data', () async {
    // 1. Siapkan: buat database persis seperti aplikasi versi 1.
    final v1 = await openDatabase(
      lokasi,
      version: 1,
      onCreate: (db, version) => db.execute('''
        CREATE TABLE catatan(
          id          INTEGER PRIMARY KEY AUTOINCREMENT,
          judul       TEXT NOT NULL,
          mata_kuliah TEXT NOT NULL,
          isi         TEXT NOT NULL,
          dibuat      TEXT NOT NULL
        )
      '''),
    );
    await v1.insert('catatan', {
      'judul': 'Catatan dari versi 1',
      'mata_kuliah': 'Basis Data',
      'isi': 'Harus tetap ada setelah update.',
      'dibuat': '2026-11-01T08:00:00.000',
    });
    await v1.close();

    // 2. Jalankan: aplikasi versi 2 membuka file yang sama.
    final v2 = CatatanDatabase(path: lokasi);
    final daftar = await v2.ambilSemua();

    // 3. Periksa: data lama masih ada, kolom baru terisi nilai DEFAULT 0.
    expect(daftar, hasLength(1));
    expect(daftar.first.judul, 'Catatan dari versi 1');
    expect(daftar.first.disematkan, isFalse);

    await v2.ubah(daftar.first.copyWith(disematkan: true));
    expect((await v2.ambilSemua()).first.disematkan, isTrue);
    await v2.close();

    // Nomor versi tersimpan di dalam file database.
    final cek = await openDatabase(lokasi);
    expect(await cek.getVersion(), 2);
    await cek.close();
  });

  test('instal baru langsung membuat tabel versi 2', () async {
    final database = CatatanDatabase(path: lokasi);
    expect(await database.ambilSemua(), isEmpty);
    await database.close();

    final db = await openDatabase(lokasi);
    final kolom = await db.rawQuery('PRAGMA table_info(catatan)');
    expect(kolom.map((k) => k['name']), contains('disematkan'));
    expect(await db.getVersion(), 2);
    await db.close();
  });
}
