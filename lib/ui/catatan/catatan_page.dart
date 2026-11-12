import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'catatan_screen.dart';
import 'catatan_view_model.dart';

/// Membuat CatatanViewModel dari database di Provider,
/// membaca catatan dari SQLite, lalu menampilkan layar.
class CatatanPage extends StatefulWidget {
  const CatatanPage({super.key});

  @override
  State<CatatanPage> createState() => _CatatanPageState();
}

class _CatatanPageState extends State<CatatanPage> {
  late final CatatanViewModel _viewModel = CatatanViewModel(database: context.read())..muat();

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => CatatanScreen(viewModel: _viewModel);
}
