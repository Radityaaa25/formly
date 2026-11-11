import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

import '../theme/app_colors.dart';
import '../services/pose/pose_frame.dart';

typedef PoseFrameCallback = void Function(PoseFrame frame);

class PoseCamera extends StatefulWidget {
  const PoseCamera({
    super.key,
    required this.lensDirection,
    required this.onPose,
    this.child,
    this.dim = 0.2,
  });

  final CameraLensDirection lensDirection;
  final PoseFrameCallback onPose;
  final Widget? child;
  final double dim;

  @override
  State<PoseCamera> createState() => _PoseCameraState();
}

class _PoseCameraState extends State<PoseCamera> with WidgetsBindingObserver {
  CameraController? _controller;
  CameraDescription? _description;
  PoseDetector? _detector;
  bool _failed = false;
  bool _processing = false;
  bool _streaming = false;
  int _errorCount = 0;
  DateTime _lastProcess = DateTime.fromMillisecondsSinceEpoch(0);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _detector = PoseDetector(
      options: PoseDetectorOptions(
        mode: PoseDetectionMode.stream,
        model: PoseDetectionModel.base,
      ),
    );
    _setup();
  }

  @override
  void didUpdateWidget(covariant PoseCamera oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.lensDirection != widget.lensDirection) {
      _disposeCamera();
      _setup();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = _controller;
    if (controller == null) return;
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      _disposeCamera();
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
      final desired = widget.lensDirection;
      final description = cameras.firstWhere(
        (camera) => camera.lensDirection == desired,
        orElse: () => cameras.firstWhere(
          (camera) => camera.lensDirection == CameraLensDirection.back,
          orElse: () => cameras.first,
        ),
      );
      // CameraX mengembalikan NV21 yang sudah rapi (1 plane) di Android.
      // Sebelumnya yuv420 dikonversi manual tanpa menghormati row/pixel stride
      // sehingga buffer NV21 rusak dan ML Kit tidak pernah menemukan pose.
      final imageFormatGroup = defaultTargetPlatform == TargetPlatform.android
          ? ImageFormatGroup.nv21
          : ImageFormatGroup.bgra8888;
      late CameraController controller;
      try {
        controller = CameraController(
          description,
          ResolutionPreset.medium,
          enableAudio: false,
          imageFormatGroup: imageFormatGroup,
        );
        await controller.initialize();
      } catch (_) {
        if (defaultTargetPlatform != TargetPlatform.android ||
            imageFormatGroup != ImageFormatGroup.nv21) {
          rethrow;
        }
        controller = CameraController(
          description,
          ResolutionPreset.medium,
          enableAudio: false,
          imageFormatGroup: ImageFormatGroup.yuv420,
        );
        await controller.initialize();
      }
      if (!mounted) {
        await controller.dispose();
        return;
      }
      _controller = controller;
      _description = description;
      _failed = false;
      setState(() {});
      await _startStream(controller);
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  Future<void> _startStream(CameraController controller) async {
    if (_streaming) return;
    try {
      await controller.startImageStream(_onImage);
      _streaming = true;
    } catch (_) {
      // Kamera mungkin tidak mendukung image stream; preview tetap tampil.
    }
  }

  Future<void> _disposeCamera() async {
    final controller = _controller;
    _controller = null;
    _description = null;
    if (controller != null) {
      try {
        if (_streaming) await controller.stopImageStream();
      } catch (_) {
        // diabaikan
      }
      _streaming = false;
      try {
        await controller.dispose();
      } catch (_) {
        // diabaikan
      }
    }
    if (mounted) setState(() {});
  }

  Future<void> _onImage(CameraImage image) async {
    if (!mounted || _processing) return;
    final now = DateTime.now();
    if (now.difference(_lastProcess).inMilliseconds < 70) return;
    _lastProcess = now;
    _processing = true;

    try {
      final controller = _controller;
      final description = _description;
      final detector = _detector;
      if (controller == null || description == null || detector == null) {
        return;
      }

      final brightness = _averageBrightness(image);
      final inputImage = _toInputImage(image, controller, description);
      if (inputImage == null) return;

      final poses = await detector.processImage(inputImage);
      if (!mounted) return;
      _errorCount = 0;
      if (poses.isNotEmpty) {
        final pose = poses.first;
        widget.onPose(
          PoseFrame.fromPose(
            pose,
            brightness,
            Size(image.width.toDouble(), image.height.toDouble()),
          ),
        );
      } else {
        widget.onPose(
          PoseFrame(
            landmarks: const {},
            brightness: brightness,
            imageSize: Size(image.width.toDouble(), image.height.toDouble()),
          ),
        );
      }
    } catch (error) {
      _errorCount++;
      if (_errorCount <= 5) {
        debugPrint('PoseCamera: gagal memproses frame ($_errorCount): $error');
      }
    } finally {
      _processing = false;
    }
  }

  double _averageBrightness(CameraImage image) {
    try {
      final bytes = image.planes.first.bytes;
      if (bytes.isEmpty) return 0;
      var sum = 0;
      var count = 0;
      final step = bytes.length > 20000 ? (bytes.length ~/ 20000) : 1;
      for (var i = 0; i < bytes.length; i += step) {
        sum += bytes[i];
        count++;
      }
      return count == 0 ? 0 : sum / count;
    } catch (_) {
      return 0;
    }
  }

  InputImage? _toInputImage(
    CameraImage image,
    CameraController controller,
    CameraDescription description,
  ) {
    final rotation = _rotationFor(controller, description);
    final format = image.format.group;

    if (format == ImageFormatGroup.nv21) {
      final bytes = image.planes.first.bytes;
      return InputImage.fromBytes(
        bytes: bytes,
        metadata: InputImageMetadata(
          size: Size(image.width.toDouble(), image.height.toDouble()),
          rotation: rotation,
          format: InputImageFormat.nv21,
          bytesPerRow: image.planes.first.bytesPerRow,
        ),
      );
    }

    if (format == ImageFormatGroup.yuv420) {
      final nv21 = _yuv420ToNv21(image);
      return InputImage.fromBytes(
        bytes: nv21,
        metadata: InputImageMetadata(
          size: Size(image.width.toDouble(), image.height.toDouble()),
          rotation: rotation,
          format: InputImageFormat.nv21,
          bytesPerRow: image.planes.first.bytesPerRow,
        ),
      );
    }

    if (format == ImageFormatGroup.bgra8888) {
      final bytes = image.planes.first.bytes;
      return InputImage.fromBytes(
        bytes: bytes,
        metadata: InputImageMetadata(
          size: Size(image.width.toDouble(), image.height.toDouble()),
          rotation: rotation,
          format: InputImageFormat.bgra8888,
          bytesPerRow: image.planes.first.bytesPerRow,
        ),
      );
    }

    return null;
  }

  Uint8List _yuv420ToNv21(CameraImage image) {
    final yPlane = image.planes[0];
    final uPlane = image.planes[1];
    final vPlane = image.planes[2];
    final width = image.width;
    final height = image.height;

    final ySize = width * height;
    final nv21 = Uint8List(ySize + ySize ~/ 2);

    final yRowStride = yPlane.bytesPerRow;
    final yPixelStride = yPlane.bytesPerPixel ?? 1;
    var dst = 0;
    for (var row = 0; row < height; row++) {
      final rowStart = row * yRowStride;
      for (var col = 0; col < width; col++) {
        final index = rowStart + col * yPixelStride;
        if (index < yPlane.bytes.length) {
          nv21[dst] = yPlane.bytes[index];
        }
        dst++;
      }
    }

    final uvRowStride = uPlane.bytesPerRow;
    final uPixelStride = uPlane.bytesPerPixel ?? 1;
    final vPixelStride = vPlane.bytesPerPixel ?? 1;
    final uvHeight = height ~/ 2;
    final uvWidth = width ~/ 2;
    for (var row = 0; row < uvHeight; row++) {
      final uRowStart = row * uvRowStride;
      final vRowStart = row * vPlane.bytesPerRow;
      for (var col = 0; col < uvWidth; col++) {
        final uIndex = uRowStart + col * uPixelStride;
        final vIndex = vRowStart + col * vPixelStride;
        // NV21 = Y + interleaved VU
        nv21[dst++] = vIndex < vPlane.bytes.length ? vPlane.bytes[vIndex] : 128;
        nv21[dst++] = uIndex < uPlane.bytes.length ? uPlane.bytes[uIndex] : 128;
      }
    }
    return nv21;
  }

  InputImageRotation _rotationFor(
    CameraController controller,
    CameraDescription description,
  ) {
    final sensor = description.sensorOrientation;
    int orientationDegrees;
    switch (controller.value.deviceOrientation) {
      case DeviceOrientation.portraitUp:
        orientationDegrees = 0;
        break;
      case DeviceOrientation.landscapeLeft:
        orientationDegrees = 90;
        break;
      case DeviceOrientation.portraitDown:
        orientationDegrees = 180;
        break;
      case DeviceOrientation.landscapeRight:
        orientationDegrees = 270;
        break;
    }

    int rotation;
    if (description.lensDirection == CameraLensDirection.front) {
      rotation = (sensor + orientationDegrees) % 360;
    } else {
      rotation = (sensor - orientationDegrees + 360) % 360;
    }

    return InputImageRotationValue.fromRawValue(rotation) ??
        InputImageRotation.rotation0deg;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _disposeCamera();
    _detector?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    final ready = controller != null && controller.value.isInitialized;
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
        if (ready) _buildPreview(controller),
        if (_failed)
          const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                'Kamera tidak tersedia atau izin ditolak.',
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
