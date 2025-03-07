import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:logging/logging.dart';

final log = Logger('DatabaseHelper');

void setupLogging() {
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    log.warning('${record.level.name}: ${record.time}: ${record.message}');
  });
}

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    
    final dbPath = await getDatabasesPath();
    await deleteDatabase(join(dbPath, 'cards.db'));  

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

    await db.transaction((txn) async {
      for (var folder in folderData) {
        await txn.insert('folders', folder);
      }
    });
  }

  Future<void> _insertStandardCards(Database db) async {
    final result = await db.query('folders');

    for (var folder in result) {
      final folderId = folder['id'];
      final folderName = folder['name'];

      List<String> suitsForFolder = [];
      if (folderName == 'Hearts') {
        suitsForFolder = ['Hearts'];
      } else if (folderName == 'Spades') {
        suitsForFolder = ['Spades'];
      } else if (folderName == 'Diamonds') {
        suitsForFolder = ['Diamonds'];
      } else if (folderName == 'Clubs') {
        suitsForFolder = ['Clubs'];
      }

      for (var suit in suitsForFolder) {
        final cardNames = [
          'Ace', '2', '3', '4', '5', '6', '7', '8', '9', '10', 'Jack', 'Queen', 'King'
        ];

      for (var cardName in cardNames) {
        String imageUrl = '';

        if (suit == 'Hearts') {
          imageUrl = 'https://upload.wikimedia.org/wikipedia/commons/thumb/a/a0/Naipe_copas.png/240px-Naipe_copas.png';
        } else if (suit == 'Spades') {
          imageUrl = 'https://upload.wikimedia.org/wikipedia/commons/thumb/5/5b/SuitSpades.svg/240px-SuitSpades.svg.png';
        } else if (suit == 'Diamonds') {
          imageUrl = 'https://upload.wikimedia.org/wikipedia/commons/thumb/d/db/SuitDiamonds.svg/240px-SuitDiamonds.svg.png';
        } else if (suit == 'Clubs') {
          imageUrl = 'https://upload.wikimedia.org/wikipedia/commons/thumb/8/8a/SuitClubs.svg/240px-SuitClubs.svg.png';
        }

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

  Future<int?> addCardToFolder(String name, String suit, String imageUrl, int folderId) async {
    final db = await database;

    List<Map<String, dynamic>> countResult = await db.query(
      'cards',
      where: "folderId = ?",
      whereArgs: [folderId],
    );

    int cardCount = countResult.length;

    if (cardCount >= 6) {
      log.warning("This folder can only hold 6 cards.");
      return null;
    }

    if (cardCount + 1 < 3) {
      log.warning("You need at least 3 cards in this folder.");
    }

    return await db.insert('cards', {
      "name": name,
      "suit": suit,
      "imageUrl": imageUrl,
      "folderId": folderId,
    });
  }

  Future<List<Map<String, dynamic>>> getCardsInFolder(int folderId) async {
    final db = await database;
    return await db.query('cards', where: "folderId = ?", whereArgs: [folderId]);
  }

  Future<int> updateCardFolder(int cardId, int newFolderId) async {
    final db = await database;

    List<Map<String, dynamic>> countResult = await db.query(
      'cards',
      where: "folderId = ?",
      whereArgs: [newFolderId],
    );

    int cardCount = countResult.length;

    if (cardCount >= 6) {
      log.warning("This folder can only hold 6 cards.");
      return 0;
    }

    return await db.update(
      'cards',
      {"folderId": newFolderId},
      where: "id = ?",
      whereArgs: [cardId],
    );
  }

  Future<int> deleteCard(int cardId) async {
    final db = await database;
    return await db.delete('cards', where: "id = ?", whereArgs: [cardId]);
  }
}