/// Satu catatan kuliah.
///
/// Satu objek Catatan = satu BARIS di tabel `catatan`:
///
/// | id | judul           | mata_kuliah        | isi        | dibuat     | disematkan |
/// |----|-----------------|--------------------|------------|------------|------------|
/// | 1  | Widget dasar    | Pemrograman Mobile | Stateless… | 2026-11-…  | 1          |
class Catatan {
  final int? id; // null = belum disimpan. SQLite mengisinya otomatis.
  final String judul;
  final String mataKuliah;
  final String isi;
  final DateTime dibuat;
  final bool disematkan; // kolom baru di database versi 2

  const Catatan({
    this.id,
    required this.judul,
    required this.mataKuliah,
    required this.isi,
    required this.dibuat,
    this.disematkan = false,
  });

  /// Pilihan mata kuliah di formulir dan di filter.
  static const daftarMataKuliah = [
    'Pemrograman Mobile',
    'Basis Data',
    'Kecerdasan Buatan',
    'Etika Profesi',
  ];

  /// Objek -> Map. Dipakai saat MENULIS ke database.
  ///
  /// Nama key harus sama persis dengan nama kolom tabel.
  /// SQLite tidak punya tipe tanggal dan boolean, jadi keduanya diubah dulu.
  Map<String, Object?> toMap() {
    return {
      'id': id,
      'judul': judul,
      'mata_kuliah': mataKuliah,
      'isi': isi,
      'dibuat': dibuat.toIso8601String(), // DateTime -> TEXT
      'disematkan': disematkan ? 1 : 0, // bool -> INTEGER
    };
  }

  /// Map -> objek. Dipakai saat MEMBACA dari database.
  factory Catatan.fromMap(Map<String, Object?> map) {
    return Catatan(
      id: map['id'] as int,
      judul: map['judul'] as String,
      mataKuliah: map['mata_kuliah'] as String,
      isi: map['isi'] as String,
      dibuat: DateTime.parse(map['dibuat'] as String),
      disematkan: map['disematkan'] == 1,
    );
  }

  Catatan copyWith({String? judul, String? mataKuliah, String? isi, bool? disematkan}) {
    return Catatan(
      id: id,
      judul: judul ?? this.judul,
      mataKuliah: mataKuliah ?? this.mataKuliah,
      isi: isi ?? this.isi,
      dibuat: dibuat,
      disematkan: disematkan ?? this.disematkan,
    );
  }
}
