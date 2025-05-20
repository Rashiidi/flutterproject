class Event {
  final String id;
  final String title;
  final String description;
  final DateTime date;
  final String location;
  final String ngoId;

  Event({
    required this.id,
    required this.title,
    required this.description,
    required this.date,
    required this.location,
    required this.ngoId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'date': date.toIso8601String(),
      'location': location,
      'ngoId': ngoId,
    };
  }

  factory Event.fromMap(Map<String, dynamic> map, String docId) {
    return Event(
      id: docId,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      date: DateTime.parse(map['date']),
      location: map['location'] ?? '',
      ngoId: map['ngoId'] ?? '',
    );
  }
}