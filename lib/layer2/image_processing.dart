import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:image/image.dart' as img;
import '../layer3/communication.dart';

class ProcessedImageData {
  final Uint8List extractedPixelData;
  final Uint8List macroBlockData;

  ProcessedImageData(this.extractedPixelData, this.macroBlockData);
}

class ImageProcessing {
  static const int MACRO_BLOCK_SIZE = 32;

  static void processImage(String? imagePath) {
    if (imagePath != null) {
      print('Processing image at path: $imagePath');
    }
  }

  static Future<ProcessedImageData> extractPixelData(Uint8List imageData) async {
    try {
      // First try decoding with the image package
      img.Image? image = img.decodeImage(imageData);
      
      if (image == null) {
        // If that fails, try decoding with multiple formats explicitly
        if (img.JpegDecoder().isValidFile(imageData)) {
          image = img.JpegDecoder().decodeImage(imageData);
        } else if (img.PngDecoder().isValidFile(imageData)) {
          image = img.PngDecoder().decodeImage(imageData);
        } else if (img.GifDecoder().isValidFile(imageData)) {
          image = img.GifDecoder().decodeImage(imageData);
        } else if (img.BmpDecoder().isValidFile(imageData)) {
          image = img.BmpDecoder().decodeImage(imageData);
        }
      }

      if (image == null) {
        print('Failed to decode image with any supported format.');
        throw Exception('Unable to decode image');
      }

      print('Image decoded successfully. Width: ${image.width}, Height: ${image.height}');

      // Create extracted pixel image (raw pixels)
      final extractedImage = img.Image(image.width, image.height);
      for (int y = 0; y < image.height; y++) {
        for (int x = 0; x < image.width; x++) {
          final pixel = image.getPixel(x, y);
          extractedImage.setPixel(x, y, pixel);
        }
      }

      // Process image in macro blocks
      final macroBlockImage = processMacroBlocks(image);
      
      // Get compressed data and send to communication layer
      final compressedData = getCompressedData(macroBlockImage);
      CommunicationLayer.setMacroBlockData(
        compressedData: compressedData,
        width: image.width,
        height: image.height,
        blockSize: MACRO_BLOCK_SIZE,
      );
      
      // Convert both images to PNG format
      final extractedPngData = img.encodePng(extractedImage);
      final macroBlockPngData = img.encodePng(macroBlockImage);

      return ProcessedImageData(
        Uint8List.fromList(extractedPngData),
        Uint8List.fromList(macroBlockPngData)
      );
    } catch (e) {
      print('Error processing image: $e');
      CommunicationLayer.clear(); // Clear communication layer on error
      rethrow;
    }
  }

  static img.Image processMacroBlocks(img.Image sourceImage) {
    final int width = sourceImage.width;
    final int height = sourceImage.height;
    
    // Calculate number of macro blocks in each dimension
    final int numBlocksX = (width + MACRO_BLOCK_SIZE - 1) ~/ MACRO_BLOCK_SIZE;
    final int numBlocksY = (height + MACRO_BLOCK_SIZE - 1) ~/ MACRO_BLOCK_SIZE;
    
    // Create a new image for the macro block result
    final img.Image resultImage = img.Image(
      numBlocksX * MACRO_BLOCK_SIZE, 
      numBlocksY * MACRO_BLOCK_SIZE
    );

    // Process each macro block
    for (int blockY = 0; blockY < numBlocksY; blockY++) {
      for (int blockX = 0; blockX < numBlocksX; blockX++) {
        // Calculate block boundaries
        final int startX = blockX * MACRO_BLOCK_SIZE;
        final int startY = blockY * MACRO_BLOCK_SIZE;
        final int endX = (startX + MACRO_BLOCK_SIZE).clamp(0, width);
        final int endY = (startY + MACRO_BLOCK_SIZE).clamp(0, height);

        // Calculate average color for the block
        int totalR = 0, totalG = 0, totalB = 0, totalA = 0;
        int pixelCount = 0;

        for (int y = startY; y < endY; y++) {
          for (int x = startX; x < endX; x++) {
            if (x < width && y < height) {
              final pixel = sourceImage.getPixel(x, y);
              totalR += img.getRed(pixel);
              totalG += img.getGreen(pixel);
              totalB += img.getBlue(pixel);
              totalA += img.getAlpha(pixel);
              pixelCount++;
            }
          }
        }

        // Calculate average color
        final avgR = (totalR / pixelCount).round();
        final avgG = (totalG / pixelCount).round();
        final avgB = (totalB / pixelCount).round();
        final avgA = (totalA / pixelCount).round();

        // Fill the macro block with the average color
        final avgColor = img.getColor(avgR, avgG, avgB, avgA);
        for (int y = startY; y < startY + MACRO_BLOCK_SIZE; y++) {
          for (int x = startX; x < startX + MACRO_BLOCK_SIZE; x++) {
            if (x < resultImage.width && y < resultImage.height) {
              resultImage.setPixel(x, y, avgColor);
            }
          }
        }
      }
    }

    return resultImage;
  }

  static List<int> getCompressedData(img.Image processedImage) {
    final int numBlocksX = processedImage.width ~/ MACRO_BLOCK_SIZE;
    final int numBlocksY = processedImage.height ~/ MACRO_BLOCK_SIZE;
    final List<int> compressedData = [];

    for (int blockY = 0; blockY < numBlocksY; blockY++) {
      for (int blockX = 0; blockX < numBlocksX; blockX++) {
        final pixel = processedImage.getPixel(
          blockX * MACRO_BLOCK_SIZE,
          blockY * MACRO_BLOCK_SIZE
        );
        compressedData.addAll([
          img.getRed(pixel),
          img.getGreen(pixel),
          img.getBlue(pixel),
          img.getAlpha(pixel)
        ]);
      }
    }

    return compressedData;
  }
}

