class QuestionModel {
  String id;
  String quizId;
  String question;
  List<String> options;
  int correctIndex;
  String questionType;
  String? questionImageUrl;  // Optional image for the question
  List<String?>? optionImageUrls;  // Optional images for each option

  QuestionModel({
    this.id = '',
    required this.quizId,
    required this.question,
    required this.options,
    required this.correctIndex,
    this.questionType = 'multiple_choice',
    this.questionImageUrl,
    this.optionImageUrls,
  });

  factory QuestionModel.fromMap(String id, Map<String, dynamic> data) {
    return QuestionModel(
      id: id,
      quizId: data['quizId'] ?? '',
      question: data['question'] ?? '',
      options: List<String>.from(data['options'] ?? []),
      correctIndex: data['correctIndex'] ?? 0,
      questionType: data['questionType'] ?? 'multiple_choice',
      questionImageUrl: data['questionImageUrl'],
      optionImageUrls: data['optionImageUrls'] != null
          ? List<String?>.from(data['optionImageUrls'])
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'quizId': quizId,
      'question': question,
      'options': options,
      'correctIndex': correctIndex,
      'questionType': questionType,
    };
    
    // Only include image fields if they have values
    if (questionImageUrl != null) {
      map['questionImageUrl'] = questionImageUrl!;
    }
    if (optionImageUrls != null) {
      map['optionImageUrls'] = optionImageUrls!;
    }
    
    return map;
  }
}
