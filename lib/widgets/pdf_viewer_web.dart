// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:ui_web' as ui;
import 'package:flutter/material.dart';

/// Web implementation: renders the PDF inside a native <iframe> via HtmlElementView.
Widget buildPdfViewer(String url, {double height = 600}) {
  final viewType = 'pdf-iframe-${url.hashCode}';

  try {
    ui.platformViewRegistry.registerViewFactory(viewType, (int viewId) {
      final googleDocsUrl =
          'https://docs.google.com/viewer?url=${Uri.encodeComponent(url)}&embedded=true';
      final iframe = html.IFrameElement()
        ..src = googleDocsUrl
        ..style.border = 'none'
        ..style.width = '100%'
        ..style.height = '100%'
        ..allow = 'fullscreen';
      return iframe;
    });
  } catch (_) {
    // Factory already registered — safe to ignore.
  }

  return SizedBox(
    height: height,
    child: HtmlElementView(viewType: viewType),
  );
}

bool get isPdfViewerSupported => true;
