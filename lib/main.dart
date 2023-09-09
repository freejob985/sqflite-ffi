import 'package:flutter/material.dart';
import 'package:sqflite_common/sqlite_api.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  Database? _database;

  Future<void> initializeDatabase() async {
    if (_database == null) {
      sqfliteFfiInit();
      _database = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
      await _database!.execute('''
        CREATE TABLE IF NOT EXISTS people (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT,
          age INTEGER
        )
      ''');
    }
  }

  Future<int> insertPerson(Person person) async {
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

  Future<int> deletePerson(int id) async {
    await initializeDatabase();
    return await _database!.delete(
      'people',
      where: 'id = ?',
      whereArgs: [id],
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
    if (_database != null && _database!.isOpen) {
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

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  List<Person> _people = [];
  Person? _selectedPerson;

  @override
  void initState() {
    super.initState();
    _loadPeople();
  }

  void _loadPeople() async {
    final people = await _databaseHelper.getAllPeople();
    setState(() {
      _people = people;
    });
  }

  void _addPerson() async {
    final name = _nameController.text;
    final age = int.tryParse(_ageController.text) ?? 0;

    if (name.isNotEmpty && age > 0) {
      final person = Person(name: name, age: age);
      await _databaseHelper.insertPerson(person);
      _loadPeople();
      _nameController.clear();
      _ageController.clear();
    }
  }

  void _search() async {
    final query = _searchController.text;
    final results = await _databaseHelper.searchPeople(query);
    setState(() {
      _people = results;
    });
  }

  void _selectPerson(Person person) {
    setState(() {
      _selectedPerson = person;
      _nameController.text = person.name;
      _ageController.text = person.age.toString();
    });
  }

  void _updatePerson() async {
    if (_selectedPerson != null) {
      final name = _nameController.text;
      final age = int.tryParse(_ageController.text) ?? 0;

      if (name.isNotEmpty && age > 0) {
        final updatedPerson = Person(
          id: _selectedPerson!.id,
          name: name,
          age: age,
        );
        await _databaseHelper.updatePerson(updatedPerson);
        _loadPeople();
        _clearForm();
      }
    }
  }

  void _deletePerson() async {
    if (_selectedPerson != null) {
      await _databaseHelper.deletePerson(_selectedPerson!.id!);
      _loadPeople();
      _clearForm();
    }
  }

  void _clearForm() {
    setState(() {
      _selectedPerson = null;
      _nameController.clear();
      _ageController.clear();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _searchController.dispose();
    _databaseHelper.closeDatabase();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('SQLite Example'),
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(labelText: 'Name'),
                ),
                TextField(
                  controller: _ageController,
                  decoration: InputDecoration(labelText: 'Age'),
                  keyboardType: TextInputType.number,
                ),
                ElevatedButton(
                  onPressed:
                      _selectedPerson != null ? _updatePerson : _addPerson,
                  child:
                      Text(_selectedPerson != null ? 'Update' : 'Add Person'),
                ),
                if (_selectedPerson != null)
                  ElevatedButton(
                    onPressed: _deletePerson,
                    child: Text('Delete Person'),
                  ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(labelText: 'Search by Name'),
              onChanged: (_) => _search(),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _people.length,
              itemBuilder: (context, index) {
                final person = _people[index];
                return ListTile(
                  title: Text(person.name),
                  subtitle: Text('Age: ${person.age}'),
                  onTap: () => _selectPerson(person),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
