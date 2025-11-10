import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import './gemini_service.dart';
import './file_service.dart';
import '../models/quiz.dart';
import 'quiz_screen.dart';
import 'dart:async';

class GenerateQuizScreen extends StatefulWidget {
  final String? initialCourseContent;

  const GenerateQuizScreen({
    super.key,
    this.initialCourseContent,
  });

  @override
  State<GenerateQuizScreen> createState() => _GenerateQuizScreenState();
}

class _GenerateQuizScreenState extends State<GenerateQuizScreen> with TickerProviderStateMixin {
  final TextEditingController _courseContentController = TextEditingController();
  final TextEditingController _questionCountController = TextEditingController(text: '5');
  final GeminiService _geminiService = GeminiService();
  bool _isGenerating = false;
  String? _selectedFileName;
  bool _isUploading = false;
  String? _uploadStatus;
  bool _useFileUpload = true;

  double _loadingProgress = 0.0;
  String _loadingMessage = 'Initialisation...';
  Timer? _progressTimer;

  late AnimationController _pulseController;
  late AnimationController _rotateController;
  late AnimationController _progressController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _rotateAnimation;

  // Color Palette
  static const Color primaryRed = Color(0xFFE53935);
  static const Color backgroundWhite = Color(0xFFFFFFFF);
  static const Color textDark = Color(0xFF212121);
  static const Color neutralGray = Color(0xFFF5F5F5);

  @override
  void initState() {
    super.initState();
    if (widget.initialCourseContent != null) {
      _courseContentController.text = widget.initialCourseContent!;
    }

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);

    _rotateController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    )..repeat();

    _progressController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _rotateAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _rotateController, curve: Curves.linear),
    );
  }

  void _startProgressSimulation() {
    _loadingProgress = 0.0;
    _loadingMessage = 'Analyse du contenu...';

    _progressTimer = Timer.periodic(const Duration(milliseconds: 300), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() {
        if (_loadingProgress < 0.25) {
          _loadingProgress += 0.03;
          _loadingMessage = 'Analyse du contenu...';
        } else if (_loadingProgress < 0.50) {
          _loadingProgress += 0.02;
          _loadingMessage = 'Extraction des concepts clés...';
        } else if (_loadingProgress < 0.75) {
          _loadingProgress += 0.015;
          _loadingMessage = 'Génération des questions...';
        } else if (_loadingProgress < 0.90) {
          _loadingProgress += 0.01;
          _loadingMessage = 'Création des réponses...';
        } else if (_loadingProgress < 0.95) {
          _loadingProgress += 0.005;
          _loadingMessage = 'Finalisation du quiz...';
        }

        if (_loadingProgress >= 0.95) {
          _loadingProgress = 0.95;
        }
      });
    });
  }

  void _completeProgress() {
    _progressTimer?.cancel();
    if (mounted) {
      setState(() {
        _loadingProgress = 1.0;
        _loadingMessage = 'Quiz prêt!';
      });
    }
  }

  Future<void> _uploadFile() async {
    setState(() {
      _isUploading = true;
      _uploadStatus = 'Sélection du fichier...';
    });

    try {
      setState(() => _uploadStatus = 'Lecture du fichier...');
      final content = await FileService.pickAndReadFile();

      if (content != null && content.isNotEmpty) {
        setState(() {
          _courseContentController.text = content;
          _uploadStatus = 'Fichier uploadé avec succès!';
        });

        FilePickerResult? result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['pdf', 'doc', 'docx', 'txt'],
          allowMultiple: false,
        );

        if (result != null) {
          setState(() {
            _selectedFileName = result.files.single.name;
          });
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.check_circle_rounded, color: backgroundWhite),
                  SizedBox(width: 12),
                  Text('Fichier uploadé avec succès', style: TextStyle(fontWeight: FontWeight.w600)),
                ],
              ),
              backgroundColor: Colors.green.shade600,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      setState(() => _uploadStatus = null);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline_rounded, color: backgroundWhite),
                const SizedBox(width: 12),
                Expanded(child: Text('Erreur: $e', style: const TextStyle(fontWeight: FontWeight.w600))),
              ],
            ),
            backgroundColor: primaryRed,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      setState(() {
        _isUploading = false;
        _uploadStatus = null;
      });
    }
  }

  Future<void> _generateQuiz() async {
    if (_courseContentController.text.isEmpty) {
      _showErrorSnackBar('Veuillez uploader un fichier ou entrer le contenu du cours');
      return;
    }

    final questionCount = int.tryParse(_questionCountController.text) ?? 5;
    if (questionCount < 1 || questionCount > 20) {
      _showErrorSnackBar('Le nombre de questions doit être entre 1 et 20');
      return;
    }

    setState(() => _isGenerating = true);
    _startProgressSimulation();

    try {
      final questions = await _geminiService.generateQuiz(
        courseContent: _courseContentController.text,
        numberOfQuestions: questionCount,
        courseName: "Quiz",
      );

      _completeProgress();
      await Future.delayed(const Duration(milliseconds: 500));

      if (!mounted) return;

      final quiz = Quiz(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        courseName: "Quiz",
        questions: questions,
        createdAt: DateTime.now(),
        totalQuestions: questions.length,
      );

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => QuizScreen(quiz: quiz),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Erreur: $e');
      }
    } finally {
      _progressTimer?.cancel();
      if (mounted) {
        setState(() => _isGenerating = false);
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline_rounded, color: backgroundWhite),
            const SizedBox(width: 12),
            Expanded(child: Text(message, style: const TextStyle(fontWeight: FontWeight.w600))),
          ],
        ),
        backgroundColor: primaryRed,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _clearContent() {
    setState(() {
      _courseContentController.clear();
      _selectedFileName = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: neutralGray,
      appBar: AppBar(
        title: const Text(
          'Créer un Quiz',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: backgroundWhite,
          ),
        ),
        backgroundColor: primaryRed,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: backgroundWhite),
      ),
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Hero Header Card
                  Container(
                    decoration: BoxDecoration(
                      color: backgroundWhite,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: primaryRed.withOpacity(0.15),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: primaryRed,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: primaryRed.withOpacity(0.3),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.auto_awesome_rounded,
                              color: backgroundWhite,
                              size: 32,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Générateur de Quiz',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: textDark,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Créez un quiz intelligent en quelques secondes',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Number of Questions Card
                  _buildCard(
                    icon: Icons.format_list_numbered_rounded,
                    title: 'Nombre de Questions',
                    child: TextField(
                      controller: _questionCountController,
                      decoration: InputDecoration(
                        hintText: 'Entre 1 et 20',
                        hintStyle: TextStyle(color: Colors.grey.shade400),
                        prefixIcon: Container(
                          margin: const EdgeInsets.all(12),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: primaryRed,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.question_answer_rounded,
                            color: backgroundWhite,
                            size: 20,
                          ),
                        ),
                        filled: true,
                        fillColor: neutralGray,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: primaryRed, width: 2),
                        ),
                      ),
                      keyboardType: TextInputType.number,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Input Method Toggle
                  _buildCard(
                    icon: Icons.tune_rounded,
                    title: 'Source du Contenu',
                    child: Container(
                      decoration: BoxDecoration(
                        color: neutralGray,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.all(4),
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildToggleButton(
                              isSelected: _useFileUpload,
                              icon: Icons.upload_file_rounded,
                              label: 'Fichier',
                              onTap: () => setState(() => _useFileUpload = true),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: _buildToggleButton(
                              isSelected: !_useFileUpload,
                              icon: Icons.text_fields_rounded,
                              label: 'Texte',
                              onTap: () => setState(() => _useFileUpload = false),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // File Upload or Manual Input
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: _useFileUpload
                        ? _buildFileUploadSection()
                        : _buildManualInputSection(),
                  ),

                  const SizedBox(height: 28),

                  // Generate Button
                  Container(
                    height: 56,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: primaryRed.withOpacity(0.3),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: _isGenerating ? null : _generateQuiz,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryRed,
                        foregroundColor: backgroundWhite,
                        disabledBackgroundColor: Colors.grey.shade300,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.rocket_launch_rounded, size: 24),
                          SizedBox(width: 12),
                          Text(
                            'Générer le Quiz',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Tips Card
                  Container(
                    decoration: BoxDecoration(
                      color: backgroundWhite,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: primaryRed.withOpacity(0.2), width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: primaryRed.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.tips_and_updates_rounded,
                                color: primaryRed,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'Conseils Pratiques',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: textDark,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildTipItem('📄', 'Fichiers TXT pour meilleurs résultats'),
                        _buildTipItem('🎯', '5-10 questions = quiz équilibré'),
                        _buildTipItem('📚', 'Quiz basé sur concepts principaux'),
                        _buildTipItem('💡', 'Plus de détails = meilleur quiz'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),

          // Enhanced Loading Overlay with Progress
          if (_isGenerating)
            Container(
              color: Colors.black.withOpacity(0.95),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Animated Icon
                    ScaleTransition(
                      scale: _pulseAnimation,
                      child: Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: primaryRed,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: primaryRed.withOpacity(0.5),
                              blurRadius: 60,
                              spreadRadius: 20,
                            ),
                          ],
                        ),
                        child: RotationTransition(
                          turns: _rotateAnimation,
                          child: const Icon(
                            Icons.auto_awesome_rounded,
                            size: 56,
                            color: backgroundWhite,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 48),

                    // Progress Circle
                    SizedBox(
                      width: 120,
                      height: 120,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            width: 120,
                            height: 120,
                            child: CircularProgressIndicator(
                              value: _loadingProgress,
                              strokeWidth: 8,
                              backgroundColor: Colors.white.withOpacity(0.1),
                              valueColor: const AlwaysStoppedAnimation<Color>(primaryRed),
                            ),
                          ),
                          Text(
                            '${(_loadingProgress * 100).toInt()}%',
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: backgroundWhite,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Loading Message
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 500),
                      child: Text(
                        _loadingMessage,
                        key: ValueKey<String>(_loadingMessage),
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: backgroundWhite,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'L\'IA travaille sur votre contenu...',
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 40),

                    // Progress Bar
                    Container(
                      width: 280,
                      height: 6,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: LinearProgressIndicator(
                          value: _loadingProgress,
                          backgroundColor: Colors.transparent,
                          valueColor: const AlwaysStoppedAnimation<Color>(primaryRed),
                          minHeight: 6,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFileUploadSection() {
    return _buildCard(
      icon: Icons.cloud_upload_rounded,
      title: 'Upload de Fichier',
      child: Column(
        children: [
          if (_selectedFileName != null) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.shade300, width: 1.5),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      color: backgroundWhite,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _selectedFileName!,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: textDark,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${_courseContentController.text.length} caractères',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: _clearContent,
                    color: Colors.grey.shade600,
                    splashRadius: 20,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: _isUploading ? null : _uploadFile,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryRed,
                foregroundColor: backgroundWhite,
                disabledBackgroundColor: Colors.grey.shade300,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              icon: _isUploading
                  ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(backgroundWhite),
                ),
              )
                  : const Icon(Icons.add_circle_outline_rounded, size: 22),
              label: Text(
                _isUploading ? 'Upload en cours...' : 'Choisir un Fichier',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.info_outline_rounded, size: 16, color: Colors.grey.shade500),
              const SizedBox(width: 6),
              Text(
                'PDF, DOC, DOCX, TXT',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildManualInputSection() {
    return _buildCard(
      icon: Icons.edit_note_rounded,
      title: 'Saisie Manuelle',
      child: TextField(
        controller: _courseContentController,
        maxLines: 8,
        decoration: InputDecoration(
          hintText: 'Collez ou écrivez le contenu du cours ici...',
          hintStyle: TextStyle(color: Colors.grey.shade400),
          filled: true,
          fillColor: neutralGray,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: primaryRed, width: 2),
          ),
          contentPadding: const EdgeInsets.all(16),
        ),
        style: const TextStyle(fontSize: 14, height: 1.5),
      ),
    );
  }

  Widget _buildCard({
    required IconData icon,
    required String title,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundWhite,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: primaryRed,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: backgroundWhite, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildToggleButton({
    required bool isSelected,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? primaryRed : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isSelected
              ? [
            BoxShadow(
              color: primaryRed.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ]
              : null,
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? backgroundWhite : Colors.grey.shade600,
              size: 26,
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: isSelected ? backgroundWhite : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTipItem(String emoji, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w500,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _courseContentController.dispose();
    _questionCountController.dispose();
    _pulseController.dispose();
    _rotateController.dispose();
    _progressController.dispose();
    _progressTimer?.cancel();
    super.dispose();
  }
}