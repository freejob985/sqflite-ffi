import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common/sqlite_api.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  Database? _database;

  Future<void> initializeDatabase() async {
    if (_database == null) {
      _database = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
      // إنشاء جدول الأشخاص إذا لم يكن موجودًا
      await _database?.execute('''
        CREATE TABLE IF NOT EXISTS people (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT,
          age INTEGER
        )
      ''');
    }
  }

  Future<int?> insertPerson(Person person) async {
    await initializeDatabase();
    return await _database!.insert('people', person.toMap());
  }

  Future<int> updatePerson(Person person) async {
    await initializeDatabase();
    return await _database!.update(
      'people',
      person.toMap(),
      where: 'id = ?',
      whereArgs: [person.id],
    );
  }

  Future<List<Person>> getAllPeople() async {
    await initializeDatabase();
    final List<Map<String, dynamic>> maps = await _database!.query('people');
    return List.generate(maps.length, (i) {
      return Person(
        id: maps[i]['id'],
        name: maps[i]['name'],
        age: maps[i]['age'],
      );
    });
  }

  Future<List<Person>> searchPeople(String query) async {
    await initializeDatabase();
    final List<Map<String, dynamic>> maps = await _database!.query(
      'people',
      where: 'name LIKE ?',
      whereArgs: ['%$query%'],
    );
    return List.generate(maps.length, (i) {
      return Person(
        id: maps[i]['id'],
        name: maps[i]['name'],
        age: maps[i]['age'],
      );
    });
  }

  Future<void> closeDatabase() async {
    if (_database!.isOpen) {
      await _database!.close();
    }
  }
}

class Person {
  final int? id;
  final String name;
  final int age;

  Person({
    this.id,
    required this.name,
    required this.age,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'age': age,
    };
  }
}
