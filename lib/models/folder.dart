class Folder {
  final int? id;
  final String name;
  final String timestamp;

  Folder({this.id, required this.name, required this.timestamp});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'timestamp': timestamp,
    };
  }

  factory Folder.fromMap(Map<String, dynamic> map) {
    return Folder(
      id: map['id'],
      name: map['name'],
      timestamp: map['timestamp'],
    );
  }
}