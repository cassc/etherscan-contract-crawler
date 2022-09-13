// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import { Base64 } from "openzeppelin-contracts/contracts/utils/Base64.sol";

import "./LibString.sol";

library QRSVG {
    uint256 internal constant SIZE = 29;

    struct QRMatrix {
        uint256[SIZE][SIZE] matrix;
        uint256[SIZE][SIZE] reserved;
    }

    // For testing, will change it to pure later
    function generateQRCode(string memory url)
        internal
        pure
        returns (string memory)
    {
        // 1. Create base matrix
        QRMatrix memory qrMatrix = createBaseMatrix();

        // 2. Encode Data
        uint8[] memory encoded = encode(url);

        // 3. Generate buff
        uint256[55] memory buf = generateBuf(encoded);

        // 4. Augument ECCs
        uint256[70] memory bufWithECCs = augumentECCs(buf);

        // 5. put data into matrix
        putData(qrMatrix, bufWithECCs);

        // 6. Put format info
        putFormatInfo(qrMatrix);

        // 7. Compose SVG and convert to base64
        string memory qrCodeUri = generateQRURI(qrMatrix);

        return qrCodeUri;
    }

    function generateBuf(uint8[] memory data)
        internal
        pure
        returns (uint256[55] memory)
    {
        uint256[55] memory buf;
        uint256 dataLen = data.length;
        uint8 maxBufLen = 55;

        uint256 bits = 0;
        uint256 remaining = 8;

        (buf, bits, remaining) = pack(buf, bits, remaining, 4, 4, 0);
        (buf, bits, remaining) = pack(buf, bits, remaining, dataLen, 8, 0);

        for (uint8 i = 0; i < dataLen; ++i) {
            (buf, bits, remaining) = pack(
                buf,
                bits,
                remaining,
                data[i],
                8,
                i + 1
            );
        }

        (buf, bits, remaining) = pack(buf, bits, remaining, 0, 4, dataLen + 1);

        for (uint256 i = data.length + 2; i < maxBufLen - 1; i++) {
            buf[i] = 0xec;
            buf[i + 1] = 0x11;
        }

        return buf;
    }

    function augumentECCs(uint256[55] memory poly)
        internal
        pure
        returns (uint256[70] memory)
    {
        uint8[15] memory genpoly = [
            8,
            183,
            61,
            91,
            202,
            37,
            51,
            58,
            58,
            237,
            140,
            124,
            5,
            99,
            105
        ];

        uint256[70] memory result;
        uint256[26] memory eccs = calculateECC(poly, genpoly);

        // Put message code words
        for (uint8 i = 0; i < 55; ++i) {
            result[i] = poly[i];
        }
        // Put error correction code words
        for (uint8 i = 0; i < 15; ++i) {
            result[i + 55] = eccs[i];
        }

        return result;
    }

    function calculateECC(uint256[55] memory poly, uint8[15] memory genpoly)
        internal
        pure
        returns (uint256[26] memory)
    {
        uint256[256] memory gf256Map;
        uint256[256] memory gf256InvMap;
        uint256[70] memory modulus;
        uint8 polylen = uint8(poly.length);
        uint8 genpolylen = uint8(genpoly.length);
        uint256[26] memory result;
        uint256 gf256Value = 1;

        gf256InvMap[0] = 0;
        for (uint256 i = 0; i < 255; ++i) {
            gf256Map[i] = gf256Value;
            gf256InvMap[gf256Value] = i;
            gf256Value = (gf256Value * 2) ^ (gf256Value >= 128 ? 0x11d : 0);
        }
        gf256Map[255] = 1;

        for (uint8 i = 0; i < 55; i++) {
            modulus[i] = poly[i];
        }

        for (uint8 i = 55; i < 70; ++i) {
            modulus[i] = 0;
        }

        for (uint8 i = 0; i < polylen; ) {
            uint256 idx = modulus[i++];
            if (idx > 0) {
                uint256 quotient = gf256InvMap[idx];
                for (uint8 j = 0; j < genpolylen; ++j) {
                    modulus[i + j] ^= gf256Map[(quotient + genpoly[j]) % 255];
                }
            }
        }

        for (uint8 i = 0; i < modulus.length - polylen; i++) {
            result[i] = modulus[polylen + i];
        }

        return result;
    }

    function pack(
        uint256[55] memory buf,
        uint256 bits,
        uint256 remaining,
        uint256 x,
        uint256 n,
        uint256 index
    )
        internal
        pure
        returns (
            uint256[55] memory,
            uint256,
            uint256
        )
    {
        uint256[55] memory newBuf = buf;
        uint256 newBits = bits;
        uint256 newRemaining = remaining;

        if (n >= remaining) {
            newBuf[index] = bits | (x >> (n -= remaining));
            newBits = 0;
            newRemaining = 8;
        }
        if (n > 0) {
            newBits |= (x & ((1 << n) - 1)) << (newRemaining -= n);
        }

        return (newBuf, newBits, newRemaining);
    }

    function encode(string memory str) internal pure returns (uint8[] memory) {
        bytes memory byteString = bytes(str);
        uint8[] memory encodedArr = new uint8[](byteString.length);

        for (uint8 i = 0; i < encodedArr.length; i++) {
            encodedArr[i] = uint8(byteString[i]);
        }

        return encodedArr;
    }

    // Creating finder patterns, timing pattern and alignment patterns
    function createBaseMatrix() internal pure returns (QRMatrix memory) {
        QRMatrix memory qrMatrix;
        uint8[2] memory aligns = [4, 20];

        // Top-Left finder pattern
        blit(
            qrMatrix,
            0,
            0,
            9,
            9,
            [0x7f, 0x41, 0x5d, 0x5d, 0x5d, 0x41, 0x17f, 0x00, 0x40]
        );

        // Top-Right finder pattern
        blit(
            qrMatrix,
            SIZE - 8,
            0,
            8,
            9,
            [0x100, 0x7f, 0x41, 0x5d, 0x5d, 0x5d, 0x41, 0x7f, 0x00]
        );

        // Bottom-Right finder pattern
        blit(
            qrMatrix,
            0,
            SIZE - 8,
            9,
            8,
            [
                uint16(0xfe),
                uint16(0x82),
                uint16(0xba),
                uint16(0xba),
                uint16(0xba),
                uint16(0x82),
                uint16(0xfe),
                uint16(0x00),
                uint16(0x00)
            ]
        );

        // Timing pattern
        for (uint256 i = 9; i < SIZE - 8; ++i) {
            qrMatrix.matrix[6][i] = qrMatrix.matrix[i][6] = ~i & 1;
            qrMatrix.reserved[6][i] = qrMatrix.reserved[i][6] = 1;
        }

        // alignment patterns
        for (uint8 i = 0; i < 2; ++i) {
            uint8 minj = i == 0 || i == 1 ? 1 : 0;
            uint8 maxj = i == 0 ? 1 : 2;
            for (uint8 j = minj; j < maxj; ++j) {
                blit(
                    qrMatrix,
                    aligns[i],
                    aligns[j],
                    5,
                    5,
                    [
                        uint16(0x1f),
                        uint16(0x11),
                        uint16(0x15),
                        uint16(0x11),
                        uint16(0x1f),
                        uint16(0x00),
                        uint16(0x00),
                        uint16(0x00),
                        uint16(0x00)
                    ]
                );
            }
        }

        return qrMatrix;
    }

    function blit(
        QRMatrix memory qrMatrix,
        uint256 y,
        uint256 x,
        uint256 h,
        uint256 w,
        uint16[9] memory data
    ) internal pure {
        for (uint256 i = 0; i < h; ++i) {
            for (uint256 j = 0; j < w; ++j) {
                qrMatrix.matrix[y + i][x + j] = (data[i] >> j) & 1;
                qrMatrix.reserved[y + i][x + j] = 1;
            }
        }
    }

    function putFormatInfo(QRMatrix memory qrMatrix) internal pure {
        uint8[15] memory infoA = [
            0,
            1,
            2,
            3,
            4,
            5,
            7,
            8,
            22,
            23,
            24,
            25,
            26,
            27,
            28
        ];

        uint8[15] memory infoB = [
            28,
            27,
            26,
            25,
            24,
            23,
            22,
            21,
            7,
            5,
            4,
            3,
            2,
            1,
            0
        ];

        for (uint8 i = 0; i < 15; ++i) {
            uint8 r = infoA[i];
            uint8 c = infoB[i];
            qrMatrix.matrix[r][8] = qrMatrix.matrix[8][c] = (32170 >> i) & 1;
            // we don't have to mark those bits reserved; always done
            // in makebasematrix above.
        }
    }

    function putData(QRMatrix memory qrMatrix, uint256[70] memory data)
        internal
        pure
        returns (QRMatrix memory)
    {
        uint256 k = 0;
        int8 dir = -1;

        // i will go below 0
        for (int256 i = int256(SIZE - 1); i >= 0; i = i - 2) {
            // skip the entire timing pattern column
            if (i == 6) {
                --i;
            }
            int256 jj = dir < 0 ? int256(SIZE - 1) : int256(0);
            for (uint256 j = 0; j < SIZE; j++) {
                // ii  will go below 0
                for (int256 ii = int256(i); ii > int256(i) - 2; ii--) {
                    // uint256(jj) and uint256(ii) will never underflow here
                    if (
                        qrMatrix.reserved[uint256(jj)][uint256(ii)] == 0 &&
                        k >> 3 < 70
                    ) {
                        qrMatrix.matrix[uint256(jj)][uint256(ii)] =
                            ((data[k >> 3] >> (~k & 7)) & 1) ^
                            (ii % 3 == 0 ? 1 : 0);
                        ++k;
                    }
                }

                if (dir == -1) {
                    // jj will go below 0 at end of loop
                    jj = jj - 1;
                } else {
                    jj = jj + 1;
                }
            }

            dir = -dir;
        }

        return qrMatrix;
    }

    function generateQRURI(QRMatrix memory qrMatrix)
        internal
        pure
        returns (string memory)
    {
        // using stroke width = 1 to draw will get 0.5 px out of bound, so we shift y + 1 and shift viewBox + 0.5
        bytes memory qrSvg = abi.encodePacked(
            '<svg version="1.1" xmlns="http://www.w3.org/2000/svg" width="100%" height="100%" viewBox="0 0.5 29 29"><path d="'
        );

        for (uint256 row = 0; row < SIZE; row += 1) {
            uint256 startY = row + 1;
            uint256 blackBlockCount;
            uint256 startX;
            for (uint256 col = 0; col < SIZE; col += 1) {
                if (qrMatrix.matrix[row][col] == 1) {
                    // Record the first black block coordinate in a consecutive black blocks
                    if (blackBlockCount == 0) {
                        startX = col;
                    }
                    blackBlockCount++;
                }
                // Draw svg when meets the white block after some black block
                else if (blackBlockCount > 0) {
                    qrSvg = abi.encodePacked(
                        qrSvg,
                        "M",
                        LibString.toString(startX),
                        ",",
                        LibString.toString(startY),
                        "l",
                        LibString.toString(blackBlockCount),
                        ",0 "
                    );
                    blackBlockCount = 0;
                }
            }
            // Draw if end of the line is reached and the last block is black
            if (blackBlockCount > 0) {
                qrSvg = abi.encodePacked(
                    qrSvg,
                    "M",
                    LibString.toString(startX),
                    ",",
                    LibString.toString(startY),
                    "l",
                    LibString.toString(blackBlockCount),
                    ",0 "
                );
            }
        }

        qrSvg = abi.encodePacked(
            qrSvg,
            '" stroke="white" stroke-width="1" fill="none"/></svg>'
        );

        return
            string(
                abi.encodePacked(
                    "data:image/svg+xml;base64,",
                    Base64.encode(qrSvg)
                )
            );
    }
}