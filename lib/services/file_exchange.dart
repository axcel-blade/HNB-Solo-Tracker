import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';

class FileExchange {
  const FileExchange();

  Future<String?> pickText(List<String> extensions) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: extensions,
      withData: true,
    );
    if (result == null || result.files.isEmpty) return null;
    final bytes = result.files.single.bytes;
    if (bytes == null) return null;
    return utf8.decode(bytes, allowMalformed: true);
  }

  Future<bool> saveText({
    required String filename,
    required String contents,
    required String extension,
  }) async {
    final bytes = Uint8List.fromList(utf8.encode(contents));
    final savedPath = await FilePicker.platform.saveFile(
      dialogTitle: 'Save file',
      fileName: filename,
      bytes: bytes,
      type: FileType.custom,
      allowedExtensions: [extension],
    );
    if (kIsWeb) return true;
    return savedPath != null;
  }
}
