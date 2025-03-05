import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('cards.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
      onOpen: (db) async {
        final result = await db.query('folders');
        if (result.isEmpty) {
          _insertTestFolders(db);
        }
      },
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute(''' 
      CREATE TABLE folders (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        timestamp TEXT NOT NULL
      );
    ''');

    await db.execute(''' 
      CREATE TABLE cards (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        suit TEXT NOT NULL,
        imageUrl TEXT NOT NULL,
        folderId INTEGER,
        FOREIGN KEY (folderId) REFERENCES folders (id) ON DELETE CASCADE
      );
    ''');

    await _insertTestFolders(db);
    await _insertStandardCards(db);
  }

  Future<void> _insertTestFolders(Database db) async {
    final folderData = [
      {'name': 'Hearts', 'timestamp': DateTime.now().toIso8601String()},
      {'name': 'Spades', 'timestamp': DateTime.now().toIso8601String()},
      {'name': 'Diamonds', 'timestamp': DateTime.now().toIso8601String()},
      {'name': 'Clubs', 'timestamp': DateTime.now().toIso8601String()},
    ];

    for (var folder in folderData) {
      await db.insert('folders', folder);
    }
  }

  Future<void> _insertStandardCards(Database db) async {
    final result = await db.query('folders');
    for (var folder in result) {
      final folderId = folder['id'];

      final suits = ['Hearts', 'Spades', 'Diamonds', 'Clubs'];
      final cardNames = [
        'Ace', '2', '3', '4', '5', '6', '7', '8', '9', '10', 'Jack', 'Queen', 'King'
      ];

      for (var suit in suits) {
        for (var i = 0; i < cardNames.length; i++) {
          final cardName = cardNames[i];
          final imageUrl = 'https://via.placeholder.com/150?text=$cardName+of+$suit';
          await db.insert('cards', {
            'name': cardName,
            'suit': suit,
            'imageUrl': imageUrl,
            'folderId': folderId,
          });
        }
      }
    }
  }
}
