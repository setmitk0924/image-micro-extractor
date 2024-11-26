import 'dart:typed_data';

class CommunicationLayer {
  static List<int>? _compressedData;
  static int? _width;
  static int? _height;
  static int? _blockSize;

  static void setMacroBlockData({
    required List<int> compressedData,
    required int width,
    required int height,
    required int blockSize,
  }) {
    _compressedData = compressedData;
    _width = width;
    _height = height;
    _blockSize = blockSize;
    
    // Print statistics
    print('Communication Layer received macro block data:');
    print('Image dimensions: ${_width}x${_height}');
    print('Block size: ${_blockSize}x${_blockSize}');
    print('Number of blocks: ${(_width! ~/ blockSize) * (_height! ~/ blockSize)}');
    print('Compressed data size: ${_compressedData!.length} bytes');
  }

  static List<int>? getCompressedData() {
    return _compressedData;
  }

  static Map<String, dynamic>? getMetadata() {
    if (_width == null || _height == null || _blockSize == null) {
      return null;
    }

    return {
      'width': _width,
      'height': _height,
      'blockSize': _blockSize,
      'blocksX': _width! ~/ _blockSize!,
      'blocksY': _height! ~/ _blockSize!,
      'compressionRatio': (_width! * _height!) / (_compressedData?.length ?? 1),
    };
  }

  static void clear() {
    _compressedData = null;
    _width = null;
    _height = null;
    _blockSize = null;
  }
}
