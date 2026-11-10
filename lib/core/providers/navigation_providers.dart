import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Main tab (Beranda, Persiapan, Keuangan, Laporan, Profil)
final mainTabProvider = StateProvider<int>((ref) => 0);

/// Sub-tab Persiapan (Vendor, Checklist, Lamaran, Seserahan, Pengingat)
final prepTabProvider = StateProvider<int>((ref) => 0);

/// Sub-tab Keuangan (Anggaran, Transaksi, Cicilan)
final financeTabProvider = StateProvider<int>((ref) => 0);