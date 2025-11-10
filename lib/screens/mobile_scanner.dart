import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../db/database_helper.dart';
import '../models/salle.dart';

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> with SingleTickerProviderStateMixin {
  late MobileScannerController cameraController;
  bool _isProcessing = false;
  bool _scanCompleted = false;
  bool _isTorchOn = false;
  late AnimationController _animationController;
  late Animation<double> _scanLineAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize camera controller
    cameraController = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      facing: CameraFacing.back,
    );

    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _scanLineAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    cameraController.dispose();
    super.dispose();
  }

  void _toggleTorch() async {
    await cameraController.toggleTorch();
    setState(() {
      _isTorchOn = !_isTorchOn;
    });
  }

  void _onDetect(BarcodeCapture capture) async {
    if (_isProcessing || _scanCompleted) return;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final String? code = barcodes.first.rawValue;
    if (code == null || code.isEmpty) return;

    print('🔍 QR Code detected: $code'); // Debug

    // Check if it's a valid salle QR code (format: SALLE:id:numero:batiment)
    if (!code.startsWith('SALLE:')) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('⚠️ Invalid QR code. Please scan a room QR code.'),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
      setState(() => _isProcessing = false);
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final parts = code.split(':');
      print('📦 Parts: $parts'); // Debug

      if (parts.length < 4) throw Exception('Invalid QR code format');

      final salleId = int.parse(parts[1]);
      print('🔑 Room ID: $salleId'); // Debug

      final db = DatabaseHelper.instance;

      // Get the salle
      final salle = await db.getSalleById(salleId);
      if (salle == null) {
        throw Exception('Room not found in database');
      }

      print('✅ Room found: ${salle.numero}'); // Debug

      // Show warning dialog
      if (mounted) {
        final confirm = await _showWarningDialog(salle);

        if (confirm == true) {
          await _markRoomAsFull(salle);
        } else {
          setState(() {
            _isProcessing = false;
          });
        }
      }
    } catch (e) {
      print('❌ Error: $e'); // Debug
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }

  Future<bool?> _showWarningDialog(Salle salle) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.warning_rounded,
                color: Colors.orange,
                size: 32,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Warning!',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                ),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'You are about to mark this room as FULL:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.meeting_room_rounded,
                            color: Colors.teal.shade600, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Room ${salle.numero}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.apartment_rounded,
                            color: Colors.grey.shade600, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            salle.batiment,
                            style: TextStyle(
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.category_rounded,
                            color: Colors.grey.shade600, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            salle.type,
                            style: TextStyle(
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    Row(
                      children: [
                        const Text(
                          'Current Capacity:',
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${salle.capacite}',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.teal.shade600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Text(
                          'New Capacity:',
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          '0',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Text(
                          '(FULL)',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.withOpacity(0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.orange, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'This will set the room capacity to 0, indicating the room is full.',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.orange,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Mark as Full',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _markRoomAsFull(Salle salle) async {
    if (!mounted) return;

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Padding(
          padding: EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.teal),
                strokeWidth: 3,
              ),
              SizedBox(height: 20),
              Text(
                'Updating room status...',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    await Future.delayed(const Duration(milliseconds: 800));

    try {
      final db = DatabaseHelper.instance;
      final updatedSalle = Salle(
        id: salle.id,
        numero: salle.numero,
        capacite: 0,
        type: salle.type,
        batiment: salle.batiment,
      );

      await db.updateSalle(updatedSalle);

      if (mounted) {
        Navigator.pop(context); // Close loading
        Navigator.pop(context, true); // Close scanner

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        '✅ Room marked as FULL!',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        'Room ${salle.numero} - ${salle.batiment}',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            showCloseIcon: true,
          ),
        );
      }

      setState(() {
        _scanCompleted = true;
        _isProcessing = false;
      });
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Failed to update: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text(
          'Scan Room QR Code',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.teal.shade600,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(_isTorchOn ? Icons.flash_on : Icons.flash_off),
            onPressed: _toggleTorch,
            tooltip: 'Toggle Flash',
          ),
          IconButton(
            icon: const Icon(Icons.flip_camera_ios_rounded),
            onPressed: () => cameraController.switchCamera(),
            tooltip: 'Switch Camera',
          ),
        ],
      ),
      body: Stack(
        children: [
          // Camera view
          MobileScanner(
            controller: cameraController,
            onDetect: _onDetect,
          ),

          // Scanning overlay
          if (!_isProcessing)
            CustomPaint(
              painter: ScannerOverlay(),
              child: const SizedBox.expand(),
            ),

          // Animated scan line
          if (!_isProcessing)
            AnimatedBuilder(
              animation: _scanLineAnimation,
              builder: (context, child) {
                return Positioned(
                  top: MediaQuery.of(context).size.height * 0.25 +
                      (MediaQuery.of(context).size.height * 0.5 * _scanLineAnimation.value),
                  left: MediaQuery.of(context).size.width * 0.1,
                  right: MediaQuery.of(context).size.width * 0.1,
                  child: Container(
                    height: 2,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          Colors.teal.shade400,
                          Colors.transparent,
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.teal.withOpacity(0.5),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

          // Instructions
          Positioned(
            top: 20,
            left: 0,
            right: 0,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 32),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.teal.withOpacity(0.5)),
              ),
              child: const Column(
                children: [
                  Icon(
                    Icons.qr_code_scanner_rounded,
                    color: Colors.white,
                    size: 32,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Position QR code inside the frame',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'The room will be marked as full',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Processing indicator
          if (_isProcessing)
            Container(
              color: Colors.black.withOpacity(0.7),
              child: Center(
                child: Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.teal),
                          strokeWidth: 4,
                        ),
                        SizedBox(height: 20),
                        Text(
                          'Processing QR Code...',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class ScannerOverlay extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withOpacity(0.6)
      ..style = PaintingStyle.fill;

    final scanAreaSize = size.width * 0.8;
    final left = (size.width - scanAreaSize) / 2;
    final top = size.height * 0.25;

    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(left, top, scanAreaSize, scanAreaSize),
          const Radius.circular(24),
        ),
      )
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(path, paint);

    final cornerPaint = Paint()
      ..color = Colors.teal
      ..strokeWidth = 5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final cornerLength = 40.0;

    // Top-left
    canvas.drawLine(Offset(left, top + cornerLength), Offset(left, top), cornerPaint);
    canvas.drawLine(Offset(left, top), Offset(left + cornerLength, top), cornerPaint);

    // Top-right
    canvas.drawLine(
      Offset(left + scanAreaSize - cornerLength, top),
      Offset(left + scanAreaSize, top),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(left + scanAreaSize, top),
      Offset(left + scanAreaSize, top + cornerLength),
      cornerPaint,
    );

    // Bottom-left
    canvas.drawLine(
      Offset(left, top + scanAreaSize - cornerLength),
      Offset(left, top + scanAreaSize),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(left, top + scanAreaSize),
      Offset(left + cornerLength, top + scanAreaSize),
      cornerPaint,
    );

    // Bottom-right
    canvas.drawLine(
      Offset(left + scanAreaSize, top + scanAreaSize - cornerLength),
      Offset(left + scanAreaSize, top + scanAreaSize),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(left + scanAreaSize - cornerLength, top + scanAreaSize),
      Offset(left + scanAreaSize, top + scanAreaSize),
      cornerPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}