import 'package:flutter/material.dart';

/// Stub implementation for non-web platforms.
/// Shows a simple "open PDF" button.
Widget buildPdfViewer(String url, {double height = 600}) {
  return const SizedBox.shrink();
}

bool get isPdfViewerSupported => false;
