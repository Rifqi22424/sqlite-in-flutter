# NusaCatat — Sesi 12: Database SQLite

Contoh aplikasi untuk mata kuliah **Pemrograman Perangkat Mobile (IF31033)**, Universitas Nusa Putra.

NusaCatat adalah aplikasi catatan kuliah yang bekerja **tanpa internet**. Semua catatan disimpan di database SQLite di dalam HP, jadi tetap ada setelah aplikasi ditutup atau HP dimatikan.

| Fitur di layar | Perintah SQL | Method sqflite |
|---|---|---|
| Tambah catatan | `INSERT` | `db.insert(...)` |
| Daftar catatan, yang disematkan di atas | `SELECT ... ORDER BY` | `db.query(..., orderBy: ...)` |
| Filter per mata kuliah | `SELECT ... WHERE` | `db.query(..., where: 'mata_kuliah = ?', whereArgs: [...])` |
| Ubah catatan, sematkan | `UPDATE ... WHERE id = ?` | `db.update(...)` |
| Geser untuk menghapus | `DELETE ... WHERE id = ?` | `db.delete(...)` |
| Isi 3 catatan contoh | 3 × `INSERT` sekaligus | `db.batch()` |

Database ini sudah **versi 2**: versi 1 belum punya kolom `disematkan`. Kolom itu ditambahkan dengan migrasi `onUpgrade`, tanpa menghapus catatan lama.

## Menjalankan

```bash
flutter pub get
flutter run
```

Jalankan di emulator Android atau HP. `sqflite` **tidak** berjalan di Chrome (web).

```bash
flutter test
```

18 test berjalan di laptop tanpa HP: SQLite memakai `sqflite_common_ffi`, di memori atau di file sementara.

## Struktur folder

```
lib/
├── main.dart
├── app.dart
├── config/dependencies.dart            # Provider: satu CatatanDatabase untuk seluruh aplikasi
├── domain/models/catatan.dart          # satu baris tabel (toMap / fromMap)
├── data/services/catatan_database.dart # SQLite: openDatabase, onCreate, onUpgrade, CRUD, batch
└── ui/catatan/
    ├── catatan_view_model.dart         # tulis ke database, lalu muat ulang
    ├── catatan_screen.dart             # filter, daftar, sematkan, geser untuk hapus
    ├── catatan_form_screen.dart        # formulir tambah / ubah
    └── catatan_page.dart               # membuat ViewModel dari Provider
test/
├── data/
│   ├── catatan_database_test.dart      # CRUD, WHERE, ORDER BY, batch
│   └── migrasi_test.dart               # versi 1 -> versi 2
└── ui/
    ├── catatan_view_model_test.dart
    └── catatan_screen_test.dart        # widget test dengan SQLite di memori
```

## Resep SQLite 3 langkah

Setiap method di `CatatanDatabase` ditulis dengan urutan yang sama:

| Langkah | Kode |
|---|---|
| 1. Buka database | `final db = await _buka();` |
| 2. Jalankan perintah | `db.insert(...)`, `db.query(...)`, `db.update(...)`, `db.delete(...)` |
| 3. Ubah hasilnya menjadi objek (hanya saat membaca) | `rows.map((row) => Catatan.fromMap(row)).toList()` |

## Langkah praktik

### Langkah 1 — Siapkan proyek dan package

```bash
git clone https://github.com/Rifqi22424/sqlite-in-flutter.git
cd sqlite-in-flutter
flutter pub get
```

Untuk proyek baru, package-nya ditambah dengan:

```bash
flutter pub add sqflite path
flutter pub add --dev sqflite_common_ffi
```

**Cek:** `flutter test` menampilkan `All tests passed!`.

### Langkah 2 — Model `Catatan` dengan `toMap` dan `fromMap`

Buka `lib/domain/models/catatan.dart`. Nama key di `toMap()` harus sama persis dengan nama kolom tabel. SQLite tidak punya tipe tanggal dan boolean, jadi `DateTime` disimpan sebagai teks dan `bool` sebagai angka 0/1.

**Cek:** `flutter test test/data/catatan_database_test.dart` → test "toMap lalu fromMap" lulus.

### Langkah 3 — Buka database dan buat tabel

Buka `lib/data/services/catatan_database.dart`, method `_buka()`. `openDatabase(lokasi, version: 2, onCreate: ...)` membuat file `nusacatat.db` dan menjalankan `CREATE TABLE catatan(...)` **hanya sekali**, saat file belum ada.

**Cek:** jalankan aplikasi. Layar menampilkan "Belum ada catatan." tanpa error `no such table`.

### Langkah 4 — CRUD dengan resep 3 langkah

| Operasi | Method | Perintah sqflite |
|---|---|---|
| Create | `tambah(catatan)` | `db.insert('catatan', catatan.toMap())` |
| Read | `ambilSemua()` | `db.query('catatan', orderBy: 'disematkan DESC, dibuat DESC')` |
| Update | `ubah(catatan)` | `db.update('catatan', catatan.toMap(), where: 'id = ?', whereArgs: [catatan.id])` |
| Delete | `hapus(id)` | `db.delete('catatan', where: 'id = ?', whereArgs: [id])` |

Selalu pakai `where: 'id = ?'` + `whereArgs`, jangan menyambung string. Tanpa `where`, update/delete mengenai **semua** baris.

**Cek:** tekan **Tambah**, simpan satu catatan. Hentikan aplikasi (tombol stop, bukan hot reload), jalankan lagi. Catatannya masih ada.

### Langkah 5 — Hubungkan ke layar

`CatatanViewModel` memakai satu pola untuk setiap aksi: **tulis ke database, lalu muat ulang daftar**.

- Chip mata kuliah memanggil `ambilSemua(mataKuliah: ...)` (WHERE).
- Ikon pin memanggil `ubah(...)` dengan `disematkan` dibalik (UPDATE).
- Menggeser item ke kiri memanggil `hapus(id)` (DELETE).
- Tombol **Isi 3 catatan contoh** memakai `batch`.

**Cek:** isi catatan contoh, pilih chip **Basis Data**. Hanya catatan Basis Data yang tampil. Kembali ke **Semua**, sematkan catatan paling bawah: catatan itu pindah ke paling atas.

### Langkah 6 — Migrasi database ke versi 2

Baca `_migrasi()` dan `test/data/migrasi_test.dart`. Test membuat database versi 1 (tanpa kolom `disematkan`), menyimpan satu catatan, lalu membukanya dengan `CatatanDatabase` versi 2.

Matikan sementara baris `onUpgrade: _migrasi,` (beri `//`), lalu:

```bash
flutter test test/data/migrasi_test.dart
```

**Cek:** test gagal dengan `no such column: disematkan`. Inilah yang terjadi di HP pengguna lama jika migrasi lupa ditulis. Kembalikan barisnya, test hijau lagi.

## Troubleshooting

| Masalah | Penyebab | Solusi |
|---|---|---|
| `MissingPluginException` | Package baru, aplikasi hanya di-hot reload | Stop, lalu `flutter run` ulang |
| `no such table: catatan` | Tabel ditambah setelah file database sudah ada; `onCreate` tidak jalan lagi | Naikkan `version` dan buat tabel di `onUpgrade`; saat belajar boleh uninstall aplikasi |
| `no such column: disematkan` | Kolom baru hanya ditulis di `CREATE TABLE`, tanpa `onUpgrade` | Tambah `ALTER TABLE ... ADD COLUMN` di `onUpgrade` |
| `type 'Null' is not a subtype of type 'String'` | Nama key di `fromMap` beda dengan nama kolom | Samakan nama key dan kolom (`mata_kuliah`, bukan `mataKuliah`) |
| Semua catatan ikut berubah atau terhapus | `update`/`delete` tanpa `where` | Selalu tulis `where: 'id = ?', whereArgs: [id]` |
| `databaseFactory not initialized` saat `flutter test` | Test di laptop belum memakai FFI | `sqfliteFfiInit(); databaseFactory = databaseFactoryFfi;` di `setUpAll` |

> Versi package: `sqflite 2.4.2+1` adalah versi terbaru yang cocok dengan Flutter 3.41. Versi 2.4.4 ke atas membutuhkan Flutter 3.44.
