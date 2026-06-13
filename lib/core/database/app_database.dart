import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  static final AppDatabase _instance = AppDatabase._internal();
  static Database? _db;

  factory AppDatabase() => _instance;

  AppDatabase._internal();

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDatabase();
    print('Database initialized!');
    return _db!;
  }

  Future<Database> _initDatabase() async {
    final path = join(await getDatabasesPath(), 'database.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: (db, verison) async {
        await db.execute('''
          CREATE TABLE users (
            id SERIAL PRIMARY KEY,
            uuid CHAR(36) UNIQUE,
            cpf VARCHAR(255) UNIQUE,
            name VARCHAR(255),
            email VARCHAR(255) UNIQUE,
            password VARCHAR(255)
        ''');
      },
    );
  }
}
