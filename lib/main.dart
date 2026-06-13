import 'dart:io';

import 'package:finance_control/app_widget.dart';
import 'package:finance_control/core/database/app_database.dart';
import 'package:flutter/material.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Platform.isLinux || Platform.isWindows) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  await AppDatabase().database;

  runApp(const MyApp());
}
