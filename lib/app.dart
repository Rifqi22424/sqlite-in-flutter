import 'package:flutter/material.dart';

import 'ui/catatan/catatan_page.dart';

class NusaCatatApp extends StatelessWidget {
  const NusaCatatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NusaCatat',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: const Color(0xFF2457C5)),
      home: const CatatanPage(),
    );
  }
}
