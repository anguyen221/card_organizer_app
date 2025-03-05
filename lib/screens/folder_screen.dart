import 'package:flutter/material.dart';
import '../models/folder.dart';
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
                    return ListTile(
                      title: Text(folder.name),
                      subtitle: Text('Created: ${folder.timestamp}'),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CardScreen(folderId: folder.id!),
                          ),
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
