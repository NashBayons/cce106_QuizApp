import 'package:flutter/material.dart';
import 'package:quiz_app/models/question_model.dart';
import 'package:quiz_app/models/question_type.dart';
import 'package:quiz_app/services/question_service.dart';
import 'package:quiz_app/theme/app_theme.dart';

class AddQuestionPage extends StatefulWidget {
  final String quizId;
  final String? existingQuestionId;
  final String? existingQuestionText;
  final List<String>? existingOptions;
  final int? existingCorrectIndex;
  final String? existingQuestionType;
  final QuestionType initialType;
  final bool allowTypeSwitch;

  const AddQuestionPage({
    super.key,
    required this.quizId,
    this.existingQuestionId,
    this.existingQuestionText,
    this.existingOptions,
    this.existingCorrectIndex,
    this.existingQuestionType,
    this.initialType = QuestionType.multipleChoice,
    this.allowTypeSwitch = false,
  });

  @override
  State<AddQuestionPage> createState() => _AddQuestionPageState();
}

class _AddQuestionPageState extends State<AddQuestionPage> {
  final QuestionService questionService = QuestionService();
  final TextEditingController questionCtrl = TextEditingController();
  final TextEditingController identificationAnswerCtrl =
      TextEditingController();
  final _formKey = GlobalKey<FormState>();

  List<TextEditingController> optionCtrls = [];
  int correctIndex = 0;
  late QuestionType selectedType;
  bool _isLoading = false;

  bool get isEditMode => widget.existingQuestionId != null;

  @override
  void initState() {
    super.initState();
    selectedType = widget.existingQuestionType != null
        ? QuestionTypeX.fromStorage(widget.existingQuestionType!)
        : widget.initialType;
    questionCtrl.text = widget.existingQuestionText ?? '';
    correctIndex = widget.existingCorrectIndex ?? 0;
    _initializeControllers(shouldPrefill: true);
  }

  @override
  void dispose() {
    questionCtrl.dispose();
    identificationAnswerCtrl.dispose();
    for (final controller in optionCtrls) {
      controller.dispose();
    }
    super.dispose();
  }

  void _initializeControllers({bool shouldPrefill = false}) {
    for (final controller in optionCtrls) {
      controller.dispose();
    }
    optionCtrls = [];

    if (selectedType == QuestionType.multipleChoice) {
      if (shouldPrefill && widget.existingOptions != null) {
        optionCtrls = widget.existingOptions!
            .map((text) => TextEditingController(text: text))
            .toList();
      }
      if (optionCtrls.length < 4) {
        optionCtrls.addAll(
          List.generate(4 - optionCtrls.length, (_) => TextEditingController()),
        );
      }
    } else {
      optionCtrls = List.generate(4, (_) => TextEditingController());
    }

    if (selectedType == QuestionType.identification) {
      if (shouldPrefill && widget.existingOptions != null) {
        identificationAnswerCtrl.text =
            widget.existingOptions!.isNotEmpty ? widget.existingOptions!.first : '';
      } else {
        identificationAnswerCtrl.clear();
      }
    }

    if (!shouldPrefill) {
      correctIndex = 0;
    }
  }

  Future<void> _saveQuestion() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final questionText = questionCtrl.text.trim();
    if (questionText.isEmpty) {
      _showSnackBar("Please enter a question", isError: true);
      return;
    }

    List<String> options;
    if (selectedType == QuestionType.multipleChoice) {
      options = optionCtrls.map((ctrl) => ctrl.text.trim()).toList();
      if (options.any((opt) => opt.isEmpty)) {
        _showSnackBar("Please complete all answer choices", isError: true);
        return;
      }
    } else if (selectedType == QuestionType.trueFalse) {
      options = const ['True', 'False'];
    } else {
      final answer = identificationAnswerCtrl.text.trim();
      if (answer.isEmpty) {
        _showSnackBar("Please enter the correct answer", isError: true);
        return;
      }
      options = [answer];
      correctIndex = 0;
    }

    setState(() => _isLoading = true);

    try {
      final question = QuestionModel(
        id: widget.existingQuestionId ?? '',
        quizId: widget.quizId,
        question: questionText,
        options: options,
        correctIndex: correctIndex,
        questionType: selectedType.storageValue,
      );

      if (widget.existingQuestionId == null) {
        await questionService.addQuestion(widget.quizId, question);
        if (mounted) {
          _showSnackBar("Question added. You can add another.", isError: false);
          _resetFormForNextQuestion();
        }
      } else {
        await questionService.updateQuestion(
          widget.quizId,
          widget.existingQuestionId!,
          question.toMap(),
        );
        if (mounted) {
          _showSnackBar("Question updated!", isError: false);
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar("Error saving question. Please try again.", isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _resetFormForNextQuestion() {
    setState(() {
      questionCtrl.clear();
      identificationAnswerCtrl.clear();
      for (final controller in optionCtrls) {
        controller.clear();
      }
      correctIndex = 0;
    });
  }

  void _switchType(QuestionType type) {
    if (!widget.allowTypeSwitch || selectedType == type) return;
    setState(() {
      selectedType = type;
      _initializeControllers();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back),
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      'Question Builder',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    if (!isEditMode)
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Done'),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildInfoCard(),
                if (widget.allowTypeSwitch) ...[
                  const SizedBox(height: 16),
                  _buildTypeSelector(),
                ],
                const SizedBox(height: 24),
                Text(
                  'Question',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: questionCtrl,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Type the question here...',
                    filled: true,
                    fillColor: AppTheme.surfaceColor,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Question is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                _buildTypeSpecificFields(),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _saveQuestion,
                    icon: _isLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Icon(isEditMode ? Icons.save : Icons.add),
                    label: Text(
                      isEditMode ? 'Save Changes' : 'Save Question',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: AppTheme.primaryColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              selectedType.icon,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  selectedType.label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  selectedType.description,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeSelector() {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: QuestionType.values.map((type) {
        final isActive = selectedType == type;
        return ChoiceChip(
          selected: isActive,
          label: Text(type.label),
          avatar: Icon(type.icon, size: 18),
          labelStyle: TextStyle(
            color: isActive ? Colors.white : AppTheme.textPrimary,
            fontWeight: FontWeight.w600,
          ),
          selectedColor: AppTheme.primaryColor,
          backgroundColor: Colors.white,
          onSelected: (_) => _switchType(type),
        );
      }).toList(),
    );
  }

  Widget _buildTypeSpecificFields() {
    switch (selectedType) {
      case QuestionType.multipleChoice:
        return _buildMultipleChoiceFields();
      case QuestionType.trueFalse:
        return _buildTrueFalseFields();
      case QuestionType.identification:
        return _buildIdentificationFields();
    }
  }

  Widget _buildMultipleChoiceFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Provide up to 4 answer choices and mark the correct one.',
          style: TextStyle(color: Color(0xFF6B7280)),
        ),
        const SizedBox(height: 16),
        ...List.generate(optionCtrls.length, (index) {
          final isCorrect = correctIndex == index;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isCorrect ? AppTheme.primaryColor : AppTheme.borderColor,
                  width: isCorrect ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => setState(() => correctIndex = index),
                    child: Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isCorrect
                              ? AppTheme.primaryColor
                              : AppTheme.textSecondary,
                        ),
                        color:
                            isCorrect ? AppTheme.primaryColor : Colors.transparent,
                      ),
                      child: isCorrect
                          ? const Icon(Icons.check, size: 14, color: Colors.white)
                          : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: optionCtrls[index],
                      decoration: InputDecoration(
                        hintText: 'Answer option ${index + 1}',
                        border: InputBorder.none,
                      ),
                      textCapitalization: TextCapitalization.sentences,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Required';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildTrueFalseFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select whether the statement is True or False.',
          style: TextStyle(color: Color(0xFF6B7280)),
        ),
        const SizedBox(height: 16),
        Row(
          children: List.generate(2, (index) {
            final labels = ['True', 'False'];
            final isSelected = correctIndex == index;
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => correctIndex = index),
                child: Container(
                  margin: EdgeInsets.only(left: index == 0 ? 0 : 12),
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTheme.primaryColor
                        : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected
                          ? AppTheme.primaryColor
                          : AppTheme.borderColor,
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        index == 0 ? Icons.check_circle : Icons.cancel,
                        color: isSelected ? Colors.white : AppTheme.textSecondary,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        labels[index],
                        style: TextStyle(
                          color: isSelected ? Colors.white : AppTheme.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildIdentificationFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Learners will type the answer. Provide the correct word or short phrase.',
          style: TextStyle(color: Color(0xFF6B7280)),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: identificationAnswerCtrl,
          decoration: InputDecoration(
            hintText: 'Correct answer',
            filled: true,
            fillColor: Colors.white,
          ),
          textCapitalization: TextCapitalization.sentences,
          validator: (value) {
            if (selectedType == QuestionType.identification &&
                (value == null || value.trim().isEmpty)) {
              return 'Answer is required';
            }
            return null;
          },
        ),
        const SizedBox(height: 8),
        Text(
          'Tip: Keep answers short. Learner input will be matched ignoring case and extra spaces.',
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: AppTheme.textSecondary),
        ),
      ],
    );
  }

  void _showSnackBar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle,
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: isError ? AppTheme.errorColor : AppTheme.accentColor,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        duration: Duration(seconds: isError ? 3 : 2),
      ),
    );
  }
}
