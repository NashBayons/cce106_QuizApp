import 'package:flutter/material.dart';
import 'package:quiz_app/theme/app_theme.dart';

enum QuestionType {
  multipleChoice,
  trueFalse,
  identification,
}

extension QuestionTypeX on QuestionType {
  String get label {
    switch (this) {
      case QuestionType.multipleChoice:
        return 'Multiple Choice';
      case QuestionType.trueFalse:
        return 'True or False';
      case QuestionType.identification:
        return 'Identification';
    }
  }

  String get description {
    switch (this) {
      case QuestionType.multipleChoice:
        return 'Learners pick the best answer from several choices.';
      case QuestionType.trueFalse:
        return 'Learners decide if the statement is true or false.';
      case QuestionType.identification:
        return 'Learners type the correct word, term, or short answer.';
    }
  }

  IconData get icon {
    switch (this) {
      case QuestionType.multipleChoice:
        return Icons.list_alt_rounded;
      case QuestionType.trueFalse:
        return Icons.toggle_on;
      case QuestionType.identification:
        return Icons.edit_note;
    }
  }

  Color get color {
    switch (this) {
      case QuestionType.multipleChoice:
        return AppTheme.primaryColor;
      case QuestionType.trueFalse:
        return AppTheme.accentColor;
      case QuestionType.identification:
        return AppTheme.secondaryColor;
    }
  }

  String get storageValue {
    switch (this) {
      case QuestionType.multipleChoice:
        return 'multiple_choice';
      case QuestionType.trueFalse:
        return 'true_false';
      case QuestionType.identification:
        return 'identification';
    }
  }

  static QuestionType fromStorage(String value) {
    switch (value) {
      case 'true_false':
        return QuestionType.trueFalse;
      case 'identification':
        return QuestionType.identification;
      case 'multiple_choice':
      default:
        return QuestionType.multipleChoice;
    }
  }
}

