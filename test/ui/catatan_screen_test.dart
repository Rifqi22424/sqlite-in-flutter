import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sesi12_database_sqlite/data/services/catatan_database.dart';
import 'package:sesi12_database_sqlite/ui/catatan/catatan_form_screen.dart';
import 'package:sesi12_database_sqlite/ui/catatan/catatan_screen.dart';
import 'package:sesi12_database_sqlite/ui/catatan/catatan_view_model.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

// WIDGET TEST dengan database SQLite di memori.
//
// sqflite FFI melakukan I/O sungguhan, sedangkan widget test memakai
// "waktu palsu". Karena itu setiap kali menunggu database kita memakai
// tester.runAsync(...) lalu pump() untuk menggambar ulang layar.
void main() {
  late CatatanDatabase database;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() => database = CatatanDatabase(path: inMemoryDatabasePath));
  tearDown(() => database.close());

  Future<void> tungguDatabase(WidgetTester tester) async {
    for (var i = 0; i < 5; i++) {
      await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 50)));
      await tester.pump();
    }
  }

  testWidgets('database kosong: tombol contoh mengisi 3 catatan', (tester) async {
    final viewModel = CatatanViewModel(database: database);
    await tester.runAsync(viewModel.muat);
    await tester.pumpWidget(MaterialApp(home: CatatanScreen(viewModel: viewModel)));

    expect(find.text('Belum ada catatan.'), findsOneWidget);

    await tester.tap(find.text('Isi 3 catatan contoh'));
    await tungguDatabase(tester);

    expect(find.text('Persiapan presentasi'), findsOneWidget);
    expect(find.byType(ListTile), findsNWidgets(3));
  });

  testWidgets('menggeser catatan menghapusnya dari database', (tester) async {
    final viewModel = CatatanViewModel(database: database);
    await tester.runAsync(viewModel.isiContoh);
    await tester.pumpWidget(MaterialApp(home: CatatanScreen(viewModel: viewModel)));

    await tester.drag(find.text('Persiapan presentasi'), const Offset(-500, 0));
    await tester.pumpAndSettle();
    await tungguDatabase(tester);

    expect(find.text('Persiapan presentasi'), findsNothing);
    final sisa = await tester.runAsync(database.ambilSemua);
    expect(sisa, hasLength(2));
  });

  testWidgets('formulir menolak judul kosong', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: CatatanFormScreen()));

    await tester.tap(find.byKey(const Key('tombol-simpan')));
    await tester.pump();

    expect(find.text('Judul wajib diisi'), findsOneWidget);
  });
}
