class QuestionModel {
  String id;
  String quizId;
  String question;
  List<String> options;
  int correctIndex;
  String questionType;

  QuestionModel({
    this.id = '',
    required this.quizId,
    required this.question,
    required this.options,
    required this.correctIndex,
    this.questionType = 'multiple_choice',
  });

  factory QuestionModel.fromMap(String id, Map<String, dynamic> data) {
    return QuestionModel(
      id: id,
      quizId: data['quizId'] ?? '',
      question: data['question'] ?? '',
      options: List<String>.from(data['options'] ?? []),
      correctIndex: data['correctIndex'] ?? 0,
      questionType: data['questionType'] ?? 'multiple_choice',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'quizId': quizId,
      'question': question,
      'options': options,
      'correctIndex': correctIndex,
      'questionType': questionType,
    };
  }
}
