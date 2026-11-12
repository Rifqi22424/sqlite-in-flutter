import 'package:flutter_test/flutter_test.dart';
import 'package:sesi12_database_sqlite/data/services/catatan_database.dart';
import 'package:sesi12_database_sqlite/domain/models/catatan.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

// Test ini berjalan di laptop (bukan HP), jadi sqflite memakai versi FFI
// dan database disimpan di memori saja. Setiap test mulai dari database kosong.
void main() {
  late CatatanDatabase database;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() => database = CatatanDatabase(path: inMemoryDatabasePath));
  tearDown(() => database.close());

  Catatan catatan(String judul, String mk, int tanggal, {bool disematkan = false}) => Catatan(
        judul: judul,
        mataKuliah: mk,
        isi: 'Isi $judul',
        dibuat: DateTime(2026, 11, tanggal),
        disematkan: disematkan,
      );

  test('toMap lalu fromMap menghasilkan data yang sama', () {
    final map = catatan('Widget', 'Pemrograman Mobile', 10, disematkan: true).toMap()..['id'] = 1;
    expect(map['disematkan'], 1); // bool disimpan sebagai INTEGER
    expect(map['dibuat'], '2026-11-10T00:00:00.000'); // DateTime disimpan sebagai TEXT

    final salinan = Catatan.fromMap(map);
    expect(salinan.judul, 'Widget');
    expect(salinan.disematkan, isTrue);
    expect(salinan.dibuat, DateTime(2026, 11, 10));
  });

  test('CREATE: insert mengembalikan id baru dari SQLite', () async {
    final id1 = await database.tambah(catatan('A', 'Basis Data', 1));
    final id2 = await database.tambah(catatan('B', 'Basis Data', 2));
    expect(id1, 1);
    expect(id2, 2);
  });

  test('READ: yang disematkan di atas, lalu yang terbaru', () async {
    await database.tambah(catatan('Lama', 'Basis Data', 1));
    await database.tambah(catatan('Baru', 'Basis Data', 3));
    await database.tambah(catatan('Penting', 'Basis Data', 2, disematkan: true));

    final semua = await database.ambilSemua();
    expect(semua.map((c) => c.judul), ['Penting', 'Baru', 'Lama']);
  });

  test('READ dengan WHERE: hanya catatan satu mata kuliah', () async {
    await database.tambah(catatan('Normalisasi', 'Basis Data', 1));
    await database.tambah(catatan('Widget', 'Pemrograman Mobile', 2));

    final hasil = await database.ambilSemua(mataKuliah: 'Basis Data');
    expect(hasil.map((c) => c.judul), ['Normalisasi']);
  });

  test('UPDATE hanya mengubah baris dengan id tersebut', () async {
    await database.tambah(catatan('A', 'Basis Data', 1));
    await database.tambah(catatan('B', 'Basis Data', 2));
    final a = (await database.ambilSemua()).firstWhere((c) => c.judul == 'A');

    await database.ubah(a.copyWith(judul: 'A (revisi)', disematkan: true));

    final semua = await database.ambilSemua();
    expect(semua.map((c) => c.judul), ['A (revisi)', 'B']);
    expect(semua.first.disematkan, isTrue);
  });

  test('DELETE menghapus satu baris saja', () async {
    final id = await database.tambah(catatan('A', 'Basis Data', 1));
    await database.tambah(catatan('B', 'Basis Data', 2));

    await database.hapus(id);

    final semua = await database.ambilSemua();
    expect(semua.map((c) => c.judul), ['B']);
  });

  test('batch menyimpan banyak catatan sekaligus', () async {
    await database.tambahBanyak([
      catatan('A', 'Basis Data', 1),
      catatan('B', 'Etika Profesi', 2),
      catatan('C', 'Kecerdasan Buatan', 3),
    ]);
    expect(await database.ambilSemua(), hasLength(3));
  });
}
