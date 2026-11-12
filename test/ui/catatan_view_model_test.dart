import 'package:flutter_test/flutter_test.dart';
import 'package:sesi12_database_sqlite/data/services/catatan_database.dart';
import 'package:sesi12_database_sqlite/domain/models/catatan.dart';
import 'package:sesi12_database_sqlite/ui/catatan/catatan_view_model.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

// ViewModel dites dengan database SQLite sungguhan di memori.
void main() {
  late CatatanDatabase database;
  late CatatanViewModel viewModel;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() {
    database = CatatanDatabase(path: inMemoryDatabasePath);
    viewModel = CatatanViewModel(database: database);
  });
  tearDown(() => database.close());

  Catatan baru(String judul, String mk) =>
      Catatan(judul: judul, mataKuliah: mk, isi: '-', dibuat: DateTime.now());

  test('simpan catatan baru lalu daftar dimuat ulang dari database', () async {
    await viewModel.muat();
    expect(viewModel.daftar, isEmpty);

    await viewModel.simpan(baru('Normalisasi', 'Basis Data'));

    expect(viewModel.daftar.single.judul, 'Normalisasi');
    expect(viewModel.daftar.single.id, isNotNull); // id dari SQLite
  });

  test('simpan catatan yang sudah punya id menjadi UPDATE, bukan baris baru', () async {
    await viewModel.simpan(baru('Draf', 'Basis Data'));
    final lama = viewModel.daftar.single;

    await viewModel.simpan(lama.copyWith(judul: 'Final'));

    expect(viewModel.daftar.map((c) => c.judul), ['Final']);
  });

  test('filter mata kuliah memakai WHERE', () async {
    await viewModel.isiContoh();
    expect(viewModel.daftar, hasLength(3));

    await viewModel.pilihFilter('Basis Data');
    expect(viewModel.daftar.map((c) => c.mataKuliah), ['Basis Data']);

    await viewModel.pilihFilter(null);
    expect(viewModel.daftar, hasLength(3));
  });

  test('sematkan memindahkan catatan ke paling atas', () async {
    await viewModel.isiContoh();
    final terlama = viewModel.daftar.last;

    await viewModel.sematkan(terlama);

    expect(viewModel.daftar.first.judul, terlama.judul);
    expect(viewModel.daftar.first.disematkan, isTrue);
  });

  test('hapus menghilangkan catatan dari layar dan database', () async {
    await viewModel.isiContoh();
    await viewModel.hapus(viewModel.daftar.first);

    expect(viewModel.daftar, hasLength(2));
    expect(await database.ambilSemua(), hasLength(2));
  });

  test('validasiJudul menolak isian kosong atau spasi saja', () {
    expect(CatatanViewModel.validasiJudul('   '), 'Judul wajib diisi');
    expect(CatatanViewModel.validasiJudul('Normalisasi'), isNull);
  });
}
