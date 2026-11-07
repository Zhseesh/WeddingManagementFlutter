import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'app/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Muat data locale untuk DateFormat('...', 'id_ID')
  await initializeDateFormatting('id_ID');
  runApp(
    const ProviderScope(
      child: WeddingApp(),
    ),
  );
}