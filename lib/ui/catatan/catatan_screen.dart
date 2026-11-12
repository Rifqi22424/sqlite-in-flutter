import 'package:flutter/material.dart';

import '../../domain/models/catatan.dart';
import 'catatan_form_screen.dart';
import 'catatan_view_model.dart';

/// Layar utama: filter mata kuliah + daftar catatan dari SQLite.
class CatatanScreen extends StatelessWidget {
  const CatatanScreen({super.key, required this.viewModel});

  final CatatanViewModel viewModel;

  Future<void> _bukaFormulir(BuildContext context, [Catatan? awal]) async {
    final Catatan? hasil = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => CatatanFormScreen(awal: awal)),
    );
    if (hasil == null) return; // pengguna menekan Kembali
    await viewModel.simpan(hasil);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('NusaCatat')),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('tombol-tambah'),
        onPressed: () => _bukaFormulir(context),
        icon: const Icon(Icons.add),
        label: const Text('Tambah'),
      ),
      body: ListenableBuilder(
        listenable: viewModel,
        builder: (context, _) {
          return Column(
            children: [
              _FilterMataKuliah(viewModel: viewModel),
              Expanded(child: _isi(context)),
            ],
          );
        },
      ),
    );
  }

  Widget _isi(BuildContext context) {
    if (viewModel.error != null) {
      return Center(child: Text('Gagal membaca database:\n${viewModel.error}'));
    }
    if (viewModel.memuat && viewModel.daftar.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (viewModel.daftar.isEmpty) {
      return _KosongView(viewModel: viewModel);
    }
    return ListView.separated(
      padding: const EdgeInsets.only(bottom: 96),
      itemCount: viewModel.daftar.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final catatan = viewModel.daftar[index];
        return Dismissible(
          key: ValueKey(catatan.id),
          direction: DismissDirection.endToStart,
          background: Container(
            color: Theme.of(context).colorScheme.errorContainer,
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 24),
            child: const Icon(Icons.delete),
          ),
          onDismissed: (_) {
            viewModel.hapus(catatan);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('"${catatan.judul}" dihapus')),
            );
          },
          child: ListTile(
            isThreeLine: true,
            title: Text(catatan.judul),
            subtitle: Text(
              '${catatan.mataKuliah} · ${formatTanggal(catatan.dibuat)}\n${catatan.isi}',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: IconButton(
              tooltip: catatan.disematkan ? 'Lepas sematan' : 'Sematkan',
              icon: catatan.disematkan
                  ? Icon(Icons.push_pin, color: Theme.of(context).colorScheme.primary)
                  : const Icon(Icons.push_pin_outlined),
              onPressed: () => viewModel.sematkan(catatan),
            ),
            onTap: () => _bukaFormulir(context, catatan),
          ),
        );
      },
    );
  }
}

class _FilterMataKuliah extends StatelessWidget {
  const _FilterMataKuliah({required this.viewModel});

  final CatatanViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    // Chip bisa digeser ke samping jika tidak muat di layar.
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Row(
        spacing: 8,
        children: [
          for (final mk in [null, ...Catatan.daftarMataKuliah])
            ChoiceChip(
              label: Text(mk ?? 'Semua'),
              selected: viewModel.filter == mk,
              onSelected: (_) => viewModel.pilihFilter(mk),
            ),
        ],
      ),
    );
  }
}

class _KosongView extends StatelessWidget {
  const _KosongView({required this.viewModel});

  final CatatanViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final semua = viewModel.filter == null;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: 16,
          children: [
            Icon(Icons.note_alt_outlined, size: 64, color: Theme.of(context).colorScheme.outline),
            Text(
              semua ? 'Belum ada catatan.' : 'Belum ada catatan untuk ${viewModel.filter}.',
              textAlign: TextAlign.center,
            ),
            if (semua)
              OutlinedButton(
                onPressed: viewModel.isiContoh,
                child: const Text('Isi 3 catatan contoh'),
              ),
          ],
        ),
      ),
    );
  }
}

/// 2026-11-12 -> "12 Nov 2026"
String formatTanggal(DateTime t) {
  const bulan = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
  return '${t.day} ${bulan[t.month - 1]} ${t.year}';
}
