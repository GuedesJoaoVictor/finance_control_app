import 'package:finance_control/core/database/app_database.dart';
import 'package:finance_control/core/models/user.dart';

class UserDAO {
  static const String table = 'users';

  Future<int> insert(User user) async {
    final db = await AppDatabase().database;
    return await db.insert(table, user.toMap());
  }

  Future<User?> getUser(String email, String password) async {
    final db = await AppDatabase().database;
    final result = await db.query(
      table,
      where: 'email = ? AND password = ?',
      whereArgs: [email, password],
    );
    return result.isNotEmpty ? User.fromMap(result.first) : null;
  }
}
