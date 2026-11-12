import 'package:flutter/material.dart';

import '../../domain/models/catatan.dart';
import 'catatan_view_model.dart';

/// Formulir catatan baru atau ubah catatan.
///
/// Hasilnya dikirim kembali dengan Navigator.pop(). Layar ini tidak
/// menyentuh database; yang menyimpan adalah ViewModel.
class CatatanFormScreen extends StatefulWidget {
  const CatatanFormScreen({super.key, this.awal});

  /// Diisi saat mengubah catatan, kosong saat membuat catatan baru.
  final Catatan? awal;

  @override
  State<CatatanFormScreen> createState() => _CatatanFormScreenState();
}

class _CatatanFormScreenState extends State<CatatanFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _judul = TextEditingController(text: widget.awal?.judul);
  late final _isi = TextEditingController(text: widget.awal?.isi);
  late String _mataKuliah = widget.awal?.mataKuliah ?? Catatan.daftarMataKuliah.first;

  @override
  void dispose() {
    _judul.dispose();
    _isi.dispose();
    super.dispose();
  }

  void _simpan() {
    if (!_formKey.currentState!.validate()) return;
    final awal = widget.awal;
    final hasil = awal == null
        ? Catatan(
            judul: _judul.text.trim(),
            mataKuliah: _mataKuliah,
            isi: _isi.text.trim(),
            dibuat: DateTime.now(),
          )
        : awal.copyWith(judul: _judul.text.trim(), mataKuliah: _mataKuliah, isi: _isi.text.trim());
    Navigator.pop(context, hasil);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.awal == null ? 'Catatan Baru' : 'Ubah Catatan')),
      body: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            TextFormField(
              key: const Key('field-judul'),
              controller: _judul,
              decoration: const InputDecoration(labelText: 'Judul'),
              validator: CatatanViewModel.validasiJudul,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _mataKuliah,
              decoration: const InputDecoration(labelText: 'Mata kuliah'),
              items: [
                for (final mk in Catatan.daftarMataKuliah)
                  DropdownMenuItem(value: mk, child: Text(mk)),
              ],
              onChanged: (value) => setState(() => _mataKuliah = value!),
            ),
            const SizedBox(height: 16),
            TextFormField(
              key: const Key('field-isi'),
              controller: _isi,
              decoration: const InputDecoration(labelText: 'Isi catatan', alignLabelWithHint: true),
              minLines: 4,
              maxLines: 8,
            ),
            const SizedBox(height: 32),
            FilledButton(
              key: const Key('tombol-simpan'),
              onPressed: _simpan,
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }
}
