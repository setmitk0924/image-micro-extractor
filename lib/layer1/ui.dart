import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../layer2/image_processing.dart';
import '../layer3/communication.dart';
import 'package:flutter/services.dart' show rootBundle;

class ImageSelectorWidget extends StatefulWidget {
  @override
  _ImageSelectorWidgetState createState() => _ImageSelectorWidgetState();
}

class _ImageSelectorWidgetState extends State<ImageSelectorWidget> {
  Uint8List? _imageData;
  Uint8List? _extractedPixelData;
  Uint8List? _macroBlockData;
  String? _errorMessage;
  Map<String, dynamic>? _compressionStats;

  Future<void> _selectImage() async {
    try {
      setState(() {
        _errorMessage = null;
        _extractedPixelData = null;
        _macroBlockData = null;
        _compressionStats = null;
      });
      
      FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.image);
      
      if (result != null) {
        final file = result.files.single;
        
        final bytes = file.bytes!;
        setState(() {
          _imageData = bytes;
          print('Selected image data length: ${_imageData!.length}');
        });
        
        // Process image and get results
        final processedData = await ImageProcessing.extractPixelData(_imageData!);
        setState(() {
          _extractedPixelData = processedData.extractedPixelData;
          _macroBlockData = processedData.macroBlockData;
          _compressionStats = CommunicationLayer.getMetadata();
          print('Extracted pixel data length: ${_extractedPixelData?.length}');
          print('Macro block data length: ${_macroBlockData?.length}');
        });
        
        ImageProcessing.processImage(file.name);
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error selecting image: ${e.toString()}';
        print(_errorMessage);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (_imageData == null || _errorMessage != null)
            ElevatedButton(
              onPressed: _selectImage,
              child: Text('Select Image'),
            ),
          SizedBox(height: 20),
          if (_errorMessage != null)
            Padding(
              padding: EdgeInsets.all(8.0),
              child: Text(
                _errorMessage!,
                style: TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
            ),
          if (_imageData != null) ...[
            Text('Original Image:', style: TextStyle(fontWeight: FontWeight.bold)),
            Image.memory(
              _imageData!,
              fit: BoxFit.contain,
              width: double.infinity,
              height: 300,
            ),
          ] else
            Text('No image selected.'),
          SizedBox(height: 20),
          if (_extractedPixelData != null) ...[
            Text('Extracted Pixel Data Image:', style: TextStyle(fontWeight: FontWeight.bold)),
            Image.memory(
              _extractedPixelData!,
              fit: BoxFit.contain,
              width: double.infinity,
              height: 300,
            ),
          ],
          SizedBox(height: 20),
          if (_macroBlockData != null) ...[
            Text('Macro Block Image (${ImageProcessing.MACRO_BLOCK_SIZE}x${ImageProcessing.MACRO_BLOCK_SIZE} blocks):',
                style: TextStyle(fontWeight: FontWeight.bold)),
            if (_compressionStats != null)
              Padding(
                padding: EdgeInsets.all(8.0),
                child: Column(
                  children: [
                    Text('Image Size: ${_compressionStats!['width']}x${_compressionStats!['height']} pixels'),
                    Text('Blocks: ${_compressionStats!['blocksX']}x${_compressionStats!['blocksY']}'),
                    Text('Compression Ratio: ${_compressionStats!['compressionRatio'].toStringAsFixed(2)}:1'),
                  ],
                ),
              ),
            Image.memory(
              _macroBlockData!,
              fit: BoxFit.contain,
              width: double.infinity,
              height: 300,
            ),
          ] else if (_imageData != null && _errorMessage == null)
            CircularProgressIndicator(),
        ],
      ),
    );
  }
}
