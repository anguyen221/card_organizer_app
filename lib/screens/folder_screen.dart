import 'package:flutter/material.dart';
import '../models/folder.dart';
import '../models/card.dart';
import '../database_helper.dart';
import '../screens/card_screen.dart';

class FolderScreen extends StatefulWidget {
  @override
  _FolderScreenState createState() => _FolderScreenState();
}

class _FolderScreenState extends State<FolderScreen> {
  String _sortBy = 'name';
  String _searchQuery = '';
  late Future<List<Folder>> _folders;

  @override
  void initState() {
    super.initState();
    _folders = _fetchFolders();
  }

  Future<List<Folder>> _fetchFolders() async {
    final db = await DatabaseHelper.instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'folders',
      where: 'name LIKE ?',
      whereArgs: ['%$_searchQuery%'],
      orderBy: _sortBy == 'name' ? 'name ASC' : 'timestamp DESC',
    );
    return List.generate(maps.length, (i) {
      return Folder.fromMap(maps[i]);
    });
  }

  Future<CardModel> _fetchFirstCard(int folderId) async {
    final db = await DatabaseHelper.instance.database;
    final List<Map<String, dynamic>> cardMaps = await db.query(
      'cards',
      where: 'folderId = ?',
      whereArgs: [folderId],
      orderBy: 'id ASC',
      limit: 1,
    );
    return cardMaps.isNotEmpty ? CardModel.fromMap(cardMaps.first) : CardModel(name: 'No card', suit: '', imageUrl: '', folderId: folderId);
  }

  Future<int> _fetchCardCount(int folderId) async {
    final db = await DatabaseHelper.instance.database;
    final count = await db.query(
      'cards',
      where: 'folderId = ?',
      whereArgs: [folderId],
    );
    return count.length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Folders'),
        actions: [
          DropdownButton<String>(
            value: _sortBy,
            onChanged: (String? newValue) {
              setState(() {
                _sortBy = newValue!;
                _folders = _fetchFolders();
              });
            },
            items: <String>['name', 'timestamp']
                .map<DropdownMenuItem<String>>((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              onChanged: (query) {
                setState(() {
                  _searchQuery = query;
                  _folders = _fetchFolders();
                });
              },
              decoration: InputDecoration(
                hintText: 'Search Folders...',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Folder>>(
              future: _folders,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(child: Text('No folders available.'));
                }
                return ListView(
                  children: snapshot.data!.map((folder) {
                    return FutureBuilder<CardModel>(
                      future: _fetchFirstCard(folder.id!),
                      builder: (context, cardSnapshot) {
                        if (cardSnapshot.connectionState == ConnectionState.waiting) {
                          return ListTile(
                            title: Text(folder.name),
                            subtitle: Text('Loading first card...'),
                          );
                        }
                        if (!cardSnapshot.hasData) {
                          return ListTile(
                            title: Text(folder.name),
                            subtitle: Text('No first card available'),
                          );
                        }
                        return FutureBuilder<int>(
                          future: _fetchCardCount(folder.id!),
                          builder: (context, countSnapshot) {
                            if (countSnapshot.connectionState == ConnectionState.waiting) {
                              return ListTile(
                                title: Text(folder.name),
                                subtitle: Text('Loading card count...'),
                              );
                            }
                            final cardCount = countSnapshot.data ?? 0;
                            return ListTile(
                              leading: Image.network(
                                cardSnapshot.data!.imageUrl,
                                width: 50,
                                height: 50,
                                fit: BoxFit.cover,
                              ),
                              title: Text(folder.name),
                              subtitle: Text('$cardCount Cards'),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => CardScreen(folderId: folder.id!),
                                  ),
                                );
                              },
                            );
                          },
                        );
                      },
                    );
                  }).toList(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
