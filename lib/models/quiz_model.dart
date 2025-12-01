class QuizModel {
  String id;
  String title;
  String desc;
  String ownerId;
  DateTime createdAt;

  QuizModel({
    this.id = '',
    required this.title,
    required this.desc,
    required this.ownerId,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': desc,
      'ownerId': ownerId,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory QuizModel.fromJson(String id, Map<String, dynamic> json) {
    return QuizModel(
      id: id,
      title: json['title'],
      desc: json['description'],
      ownerId: json['ownerId'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}

