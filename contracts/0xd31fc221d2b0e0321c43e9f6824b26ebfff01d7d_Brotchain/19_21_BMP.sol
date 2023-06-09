// SPDX-License-Identifier: MIT
// Copyright 2021 Arran Schlosberg / Twitter @divergence_art
pragma solidity >=0.8.0 <0.9.0;

import "base64-sol/base64.sol";

/**
 * @dev 8-bit BMP encoding with arbitrary colour palettes.
 */
contract BMP {
    using Base64 for string;

    /**
     * @dev Returns an 8-bit grayscale palette for bitmap images.
     */
    function grayscale() public pure returns (bytes memory) {
        bytes memory palette = new bytes(768);
        // TODO: investigate a way around using ++ += or + on a bytes1 without
        // having to use a placeholder int8 for incrementing!
        uint8 j;
        bytes1 b;
        for (uint16 i = 0; i < 768; i += 3) {
            b = bytes1(j);
            palette[i  ] = b;
            palette[i+1] = b;
            palette[i+2] = b;
            // The last increment would revert if checked.
            unchecked { j++; }
        }
        return palette;
    }

    /**
     * @dev Returns an 8-bit BMP encoding of the pixels.
     *
     * Spec: https://www.digicamsoft.com/bmp/bmp.html
     *
     * Layout description with offsets:
     * http://www.ece.ualberta.ca/~elliott/ee552/studentAppNotes/2003_w/misc/bmp_file_format/bmp_file_format.htm
     *
     * N.B. Everything is little-endian, hence the assembly for masking and
     * shifting.
     */
    function bmp(bytes memory pixels, uint32 width, uint32 height, bytes memory palette) public pure returns (bytes memory) {
        require(width * height == pixels.length, "Invalid dimensions");
        require(palette.length == 768, "256 colours required");

        // 14 bytes for BITMAPFILEHEADER + 40 for BITMAPINFOHEADER + 1024 for palette
        bytes memory buf = new bytes(1078);

        // BITMAPFILEHEADER
        buf[0] = 0x42; buf[1] = 0x4d; // bfType = BM
        
        uint32 size = 1078 + uint32(pixels.length);
        // bfSize; bytes in the entire buffer
        uint32 b;
        for (uint i = 2; i < 6; i++) {
            assembly {
                b := and(size, 0xff)
                size := shr(8, size)
            }
            buf[i] = bytes1(uint8(b));
        }

        // Next 4 bytes are bfReserved1 & 2; both = 0 = initial value

        // bfOffBits; bytes from beginning of file to pixels = 14 + 40 + 1024
        // (see size above)
        buf[0x0a] = 0x36;
        buf[0x0b] = 0x04;

        // BITMAPINFOHEADER
        // biSize; bytes in this struct = 40
        buf[0x0e] = 0x28;

        // biWidth / biHeight
        for (uint i = 0x12; i < 0x16; i++) {
            assembly {
                b := and(width, 0xff)
                width := shr(8, width)
            }
            buf[i] = bytes1(uint8(b));
        }
        for (uint i = 0x16; i < 0x1a; i++) {
            assembly {
                b := and(height, 0xff)
                height := shr(8, height)
            }
            buf[i] = bytes1(uint8(b));
        }

        // biPlanes
        buf[0x1a] = 0x01;
        // biBitCount
        buf[0x1c] = 0x08;

        // I've decided to use raw pixels instead of run-length encoding for
        // compression as these aren't being stored. It's therefore simpler to
        // avoid the extra computation. Therefore biSize can be 0. Similarly
        // there's no point checking exactly which colours are used, so
        // biClrUsed and biClrImportant can be 0 to indicate all colours. This
        // is therefore the end of BITMAPINFOHEADER. Simples.

        uint j = 54;
        for (uint i = 0; i < 768; i += 3) {
            // RGBQUAD is in reverse order and the 4th byte is unused.
            buf[j  ] = palette[i+2];
            buf[j+1] = palette[i+1];
            buf[j+2] = palette[i  ];
            j += 4;
        }

        return abi.encodePacked(buf, pixels);
    }

    /**
     * @dev Returns the buffer, presumably from bmp(), as a base64 data URI.
     */
    function bmpDataURI(bytes memory bmpBuf) public pure returns (string memory) {
        return string(abi.encodePacked(
            'data:image/bmp;base64,',
            Base64.encode(bmpBuf)
        ));
    }

    /**
     * @dev Scale pixels by repetition along both axes.
     */
    function scalePixels(bytes memory pixels, uint32 width, uint32 height, uint32 scale) public pure returns (bytes memory) {
        require(width * height == pixels.length, "Invalid dimensions");
        bytes memory scaled = new bytes(pixels.length * scale * scale);

        // Indices in each of the original and scaled buffers, respectively. The
        // scaled-buffer index is always incremented. The original index is
        // incremented only after scaling x-wise by scale times, then reversed
        // at the end of the width to allow for y-wise scaling.
        uint32 origIdx;
        uint32 scaleIdx;
        for (uint32 y = 0; y < height; y++) {
            for (uint32 yScale = 0; yScale < scale; yScale++) {
                for (uint32 x = 0; x < width; x++) {
                    for (uint32 xScale = 0; xScale < scale; xScale++) {
                        scaled[scaleIdx] = pixels[origIdx];
                        scaleIdx++;
                    }
                    origIdx++;
                }
                // Rewind to copy the row again.
                origIdx -= width;
            }
            // Don't just copy the first row.
            origIdx += width;
        }

        return scaled;
    }

}