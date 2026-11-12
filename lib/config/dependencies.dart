import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import '../data/services/catatan_database.dart';

/// Objek lapisan data, dibuat SATU KALI untuk seluruh aplikasi.
/// Satu aplikasi cukup membuka satu koneksi database.
List<SingleChildWidget> get providers => [
      Provider(
        create: (context) => CatatanDatabase(),
        dispose: (context, database) => database.close(),
      ),
    ];
