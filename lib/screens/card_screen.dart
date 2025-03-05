import 'package:flutter/material.dart';
import '../models/card.dart';
import '../database_helper.dart';

class CardScreen extends StatefulWidget {
  final int folderId;

  CardScreen({required this.folderId});

  @override
  _CardScreenState createState() => _CardScreenState();
}

class _CardScreenState extends State<CardScreen> {
  late Future<List<CardModel>> _cards;

  @override
  void initState() {
    super.initState();
    _cards = _fetchCards();
  }

  Future<List<CardModel>> _fetchCards() async {
    final db = await DatabaseHelper.instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'cards',
      where: 'folderId = ?',
      whereArgs: [widget.folderId],
    );
    return List.generate(maps.length, (i) {
      return CardModel.fromMap(maps[i]);
    });
  }

  Future<void> _addCard() async {
    final db = await DatabaseHelper.instance.database;
    final card = CardModel(
      name: 'New Card',
      suit: 'Spades',
      imageUrl: 'https://via.placeholder.com/150',
      folderId: widget.folderId,
    );
    await db.insert('cards', card.toMap());
    setState(() {
      _cards = _fetchCards();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Cards'),
      ),
      body: Column(
        children: [
          ElevatedButton(
            onPressed: _addCard,
            child: Text('Add New Card'),
          ),
          Expanded(
            child: FutureBuilder<List<CardModel>>(
              future: _cards,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(child: Text('No cards available.'));
                }
                return ListView(
                  children: snapshot.data!.map((card) {
                    return ListTile(
                      title: Text(card.name),
                      subtitle: Text('${card.suit} - ${card.imageUrl}'),
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
