// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.20;

import {Adler32} from './Adler32.sol';
import {CRC32} from './CRC32.sol';

/**
 * @title PNG
 * @dev PNG is a contract for generating PNG images from raw image data in Solidity.
 * It includes functions for encoding and decoding PNG images, as well as for
 * calculating Adler32 and CRC32 checksums.
 *
 * This contract is based on the PNG specification:
 *
 * http://www.libpng.org/pub/png/spec/1.2/PNG-Contents.html
 *
 * It supports only 8 bit images and supports RGB or RGBA color formats.
 * It uses compression method 0, filter method 0, and interlace method 0.
 */
contract PNG {
  using Adler32 for bytes;
  using CRC32 for bytes;

  /**
   * The PNG signature is a fixed eight-byte sequence:
   * 89 50 4e 47 0d 0a 1a 0a
   */
  bytes public constant PNG_SIGNATURE = hex'89504e470d0a1a0a';

  /**
   * The IEND chunk marks the end of the PNG datastream.
   * It contains no data.
   *
   * The IEND chunk must appear last.
   * It is an error to place any data after the IEND chunk.
   *
   * The IEND chunk is always equal to 12 bytes
   * 00 00 00 00 49 45 4e 44 ae 42 60 82
   */
  bytes public constant IEND = hex'0000000049454e44ae426082';

  /**
   * @notice Encodes a PNG image from raw image data
   * @param data Raw image data
   * @param width  The width of the image, in pixels
   * @param height The height of the image, in pixels
   * @param alpha  Whether the image has an alpha channel
   * @return PNG image
   */
  function encodePNG(bytes memory data, uint width, uint height, bool alpha) public pure returns (bytes memory) {
    unchecked {
      // Determine the width of each pixel
      uint pixelWidth = (alpha) ? 4 : 3;

      // Check that the length of the data is correct
      require(data.length == pixelWidth * width * height, 'Invalid image data length');

      // Create the IHDR chunk
      bytes memory chunkIHDR = encodeIHDR(width, height, alpha);

      // Create the IDAT chunk
      bytes memory chunkIDAT = encodeIDAT(data, width, height, alpha);

      // Concatenate the chunks into a single bytes array.
      return abi.encodePacked(PNG_SIGNATURE, chunkIHDR, chunkIDAT, IEND);
    }
  }

  /**
   * @dev Generates an IHDR chunk for a PNG image with the given width and height.
   * This function generates an IHDR chunk according to the PNG specification
   * (http://libpng.org/pub/png/spec/1.2/PNG-Chunks.html#C.IHDR).
   *
   * @param width The width of the image.
   * @param height The height of the image.
   * @param alpha Whether the image has alpha transparency.
   * @return A bytes memory array containing the IDAT chunk data.
   */
  function encodeIHDR(uint width, uint height, bool alpha) public pure returns (bytes memory) {
    // Create the IHDR chunk
    // The IHDR chunk length is 13 bytes (0x0000000d in hex)
    // The IHDR type 49 48 44 52 (IHDR)
    //
    // The IHDR chunk data consists of the following fields:
    // 4 bytes: width
    // 4 bytes: height
    // 1 byte: bit depth (8)
    // 1 byte: color type (2 for RGB, 6 for RGBA)
    // 1 byte: compression method (0)
    // 1 byte: filter method (0)
    // 1 byte: interlace method (0)
    //
    // 4 bytes: CRC32 checksum
    bytes memory chunkIHDR = hex'0000000d494844520000000000000000080200000000000000';
    // Set the width and height of the image in the chunk data
    chunkIHDR[8] = bytes1(uint8(width >> 24));
    chunkIHDR[9] = bytes1(uint8(width >> 16));
    chunkIHDR[10] = bytes1(uint8(width >> 8));
    chunkIHDR[11] = bytes1(uint8(width));
    chunkIHDR[12] = bytes1(uint8(height >> 24));
    chunkIHDR[13] = bytes1(uint8(height >> 16));
    chunkIHDR[14] = bytes1(uint8(height >> 8));
    chunkIHDR[15] = bytes1(uint8(height));

    // Set the color type of the image in the chunk data
    if (alpha) {
      // truecolor image with alpha channel
      chunkIHDR[17] = hex'06';
    } else {
      // truecolor image without alpha channel
      chunkIHDR[17] = hex'02';
    }

    // Calculate and set the CRC32 checksum of the chunk
    uint32 checksum = chunkIHDR.crc32(4, 21);
    chunkIHDR[21] = bytes1(uint8(checksum >> 24));
    chunkIHDR[22] = bytes1(uint8(checksum >> 16));
    chunkIHDR[23] = bytes1(uint8(checksum >> 8));
    chunkIHDR[24] = bytes1(uint8(checksum));

    return chunkIHDR;
  }

  /**
   * @dev Interlaces a given bytes array of image data.
   * @param data The bytes array of image data.
   * @param width The width of the image, in pixels.
   * @param height The height of the image, in pixels.
   * @param alpha Whether the image has an alpha channel.
   * @return The interlaced bytes array.
   */
  function interlace(bytes memory data, uint width, uint height, bool alpha) internal pure returns (bytes memory) {
    unchecked {
      uint pixelWidth = alpha ? 4 : 3;

      // IDAT chunk
      // The IDAT chunk contains the actual image data.
      // The layout and total size of this raw data are determined by the fields of IHDR.
      // The filtered data is then compressed using the method specified by the IHDR chunk.

      // Since our image has no filtering,
      // the filter type byte for each scanline would be 0x00 (no filtering).
      // Interlacing method 0 is used, so pixels are stored sequentially from left to right,
      // and scanlines sequentially from top to bottom (no interlacing).
      uint rowWidth = pixelWidth * width;
      uint rowWidthPadded = rowWidth + 1;
      // Declare a bytes array to hold the interlaced data.
      bytes memory interlacedData = new bytes(rowWidthPadded * height);

      // Loop over the scanlines.
      for (uint row = 0; row < height; row++) {
        // Calculate the starting index for the current scanline.
        uint startIndex = rowWidthPadded * row;

        // Set the filter type byte for the current scanline.
        interlacedData[startIndex] = 0x00; // Filter type 0 (no filtering)

        // Copy the scanline data into the interlaced data array.
        // No filtering is used, so the scanline data starts at index 1.
        for (uint j = 0; j < rowWidth; j++) {
          interlacedData[startIndex + 1 + j] = data[row * rowWidth + j];
        }
      }
      return interlacedData;
    }
  }

  /**
   * @dev Generates a zlib-compressed version of the given image data using the Deflate algorithm.
   * This function generates a zlib-compressed version of the given image data using the Deflate algorithm,
   * as specified in the PNG specification (http://www.libpng.org/pub/png/spec/1.2/PNG-Compression.html).
   * The resulting data is suitable for storage in an IDAT chunk of a PNG file.
   *
   * @param data The image data to be compressed.
   * @param width The width of the image, in pixels.
   * @param height The height of the image, in pixels.
   * @param alpha Whether the image has alpha transparency.
   * @return A bytes array containing the zlib-compressed image data.
   */
  function zlibCompressDeflate(
    bytes memory data,
    uint width,
    uint height,
    bool alpha
  ) internal pure returns (bytes memory) {
    unchecked {
      // Generate Deflate-compressed data
      bytes memory deflateCompressedData = interlace(data, width, height, alpha);

      // Calculate Adler-32 checksum of Deflate-compressed data
      uint32 blockAdler32 = deflateCompressedData.adler32(0, deflateCompressedData.length);

      // zlib block header (BFINAL = 1, BTYPE = 0)
      bytes memory zlibBlockHeader = hex'01';

      // LEN is the length of the data
      bytes32 len = bytes32(deflateCompressedData.length);

      // Generate zlib-compressed data
      bytes memory result = abi.encodePacked(
        // zlib header
        // CM = 8 (deflate), CINFO = 7 (32K window size)
        hex'78',
        // FCHECK = 0 (no check)
        // FDICT = 0 (no preset dictionary)
        // FLEVEL = 0 (fastest compression)
        hex'01',
        // block header (BFINAL = 1, BTYPE = 0)
        zlibBlockHeader,
        // LEN (2 bytes) (length of the data)
        len[31],
        len[30],
        // NLEN (2 bytes) (one's complement of LEN)
        ~len[31],
        ~len[30],
        // Deflate-compressed data
        deflateCompressedData,
        // block footer (adler32 checksum)
        blockAdler32
      );

      return result;
    }
  }

  /**
   * @dev Generates an IDAT chunk for a PNG image with the given width and height.
   * This function generates an IDAT chunk according to the PNG specification
   * (http://www.libpng.org/pub/png/spec/1.2/PNG-Filters.html).
   *
   * @param data The filtered image data.
   * @param width The width of the image.
   * @param height The height of the image.
   * @param alpha Whether the image has alpha transparency.
   * @return A bytes memory array containing the IDAT chunk data.
   */
  function encodeIDAT(bytes memory data, uint width, uint height, bool alpha) internal pure returns (bytes memory) {
    unchecked {
      // The IDAT data is compressed using the deflate algorithm.
      bytes memory compressed = zlibCompressDeflate(data, width, height, alpha);
      // The compressed data stream is then stored in the IDAT chunk.
      bytes memory typedata = abi.encodePacked(
        hex'49444154', // Chunk type: "IDAT" in ASCII
        compressed
      );

      // CRC calculated from the chunk type and chunk data
      uint32 crc = typedata.crc32(0, typedata.length);

      // Append the CRC32 checksum to the end of the chunk
      return abi.encodePacked(uint32(compressed.length), typedata, crc);
    }
  }
}