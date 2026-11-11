import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Menampilkan pratinjau kamera belakang sebagai latar sesi latihan.
///
/// Bila kamera tidak tersedia atau izin ditolak, widget memakai latar gradien
/// gelap sebagai fallback agar sesi tetap bisa berjalan (mode demo / simulasi).
class CameraStage extends StatefulWidget {
  const CameraStage({super.key, this.child, this.dim = 0.35});

  final Widget? child;
  final double dim;

  @override
  State<CameraStage> createState() => _CameraStageState();
}

class _CameraStageState extends State<CameraStage> with WidgetsBindingObserver {
  CameraController? _controller;
  bool _failed = false;
  bool _initializing = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _setup();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    if (state == AppLifecycleState.inactive) {
      controller.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _setup();
    }
  }

  Future<void> _setup() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        if (mounted) setState(() => _failed = true);
        return;
      }
      final back = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      final controller = CameraController(
        back,
        ResolutionPreset.medium,
        enableAudio: false,
      );
      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() {
        _controller = controller;
        _failed = false;
        _initializing = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _failed = true;
          _initializing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(0, -0.3),
              radius: 1.1,
              colors: [Color(0xFF22345C), Color(0xFF101B33), Color(0xFF080E1C)],
              stops: [0, 0.55, 1],
            ),
          ),
        ),
        if (_controller != null && _controller!.value.isInitialized)
          _buildPreview(_controller!),
        if (_failed && !_initializing)
          const Center(
            child: Padding(
              padding: EdgeInsets.only(bottom: 160),
              child: Text(
                'Kamera tidak tersedia. Mode simulasi aktif.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ),
          ),
        if (widget.dim > 0)
          IgnorePointer(
            child: ColoredBox(
              color: AppColors.cam.withValues(alpha: widget.dim),
            ),
          ),
        if (widget.child != null) widget.child!,
      ],
    );
  }

  Widget _buildPreview(CameraController controller) {
    final previewSize = controller.value.previewSize;
    return ClipRect(
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: previewSize?.height ?? controller.value.aspectRatio * 1000,
          height: previewSize?.width ?? 1000,
          child: CameraPreview(controller),
        ),
      ),
    );
  }
}
