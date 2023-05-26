// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "./ShackledStructs.sol";

library ShackledUtils {
    string internal constant TABLE =
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /** @dev Flatten 3d tris array into 2d verts */
    function flattenTris(int256[3][3][] memory tris)
        internal
        pure
        returns (int256[3][] memory)
    {
        /// initialize a dynamic in-memory array
        int256[3][] memory flattened = new int256[3][](3 * tris.length);

        for (uint256 i = 0; i < tris.length; i++) {
            /// tris.length == N
            // add values to specific index, as cannot push to array in memory
            flattened[(i * 3) + 0] = tris[i][0];
            flattened[(i * 3) + 1] = tris[i][1];
            flattened[(i * 3) + 2] = tris[i][2];
        }
        return flattened;
    }

    /** @dev Unflatten 2d verts array into 3d tries (inverse of flattenTris function) */
    function unflattenVertsToTris(int256[3][] memory verts)
        internal
        pure
        returns (int256[3][3][] memory)
    {
        /// initialize an array with length = 1/3 length of verts
        int256[3][3][] memory tris = new int256[3][3][](verts.length / 3);

        for (uint256 i = 0; i < verts.length; i += 3) {
            tris[i / 3] = [verts[i], verts[i + 1], verts[i + 2]];
        }
        return tris;
    }

    /** @dev clip an array to a certain length (to trim empty tail slots) */
    function clipArray12ToLength(int256[12][] memory arr, uint256 desiredLen)
        internal
        pure
        returns (int256[12][] memory)
    {
        uint256 nToCull = arr.length - desiredLen;
        assembly {
            mstore(arr, sub(mload(arr), nToCull))
        }
        return arr;
    }

    /** @dev convert an unsigned int to a string */
    function uint2str(uint256 _i)
        internal
        pure
        returns (string memory _uintAsString)
    {
        if (_i == 0) {
            return "0";
        }
        uint256 j = _i;
        uint256 len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint256 k = len;
        while (_i != 0) {
            k = k - 1;
            uint8 temp = (48 + uint8(_i - (_i / 10) * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }

    /** @dev get the hex encoding of various powers of 2 (canvas size options) */
    function getHex(uint256 _i) internal pure returns (bytes memory _hex) {
        if (_i == 8) {
            return hex"08_00_00_00";
        } else if (_i == 16) {
            return hex"10_00_00_00";
        } else if (_i == 32) {
            return hex"20_00_00_00";
        } else if (_i == 64) {
            return hex"40_00_00_00";
        } else if (_i == 128) {
            return hex"80_00_00_00";
        } else if (_i == 256) {
            return hex"00_01_00_00";
        } else if (_i == 512) {
            return hex"00_02_00_00";
        }
    }

    /** @dev create an svg container for a bitmap (for display on svg-only platforms) */
    function getSVGContainer(
        string memory encodedBitmap,
        int256 canvasDim,
        uint256 outputHeight,
        uint256 outputWidth
    ) internal view returns (string memory) {
        uint256 canvasDimUnsigned = uint256(canvasDim);
        // construct some elements in memory prior to return string to avoid stack too deep
        bytes memory imgSize = abi.encodePacked(
            "width='",
            ShackledUtils.uint2str(canvasDimUnsigned),
            "' height='",
            ShackledUtils.uint2str(canvasDimUnsigned),
            "'"
        );
        bytes memory canvasSize = abi.encodePacked(
            "width='",
            ShackledUtils.uint2str(outputWidth),
            "' height='",
            ShackledUtils.uint2str(outputHeight),
            "'"
        );
        bytes memory scaleStartTag = abi.encodePacked(
            "<g transform='scale(",
            ShackledUtils.uint2str(outputWidth / canvasDimUnsigned),
            ")'>"
        );

        return
            string(
                abi.encodePacked(
                    "data:image/svg+xml;base64,",
                    Base64.encode(
                        abi.encodePacked(
                            "<svg xmlns='http://www.w3.org/2000/svg' xmlns:xlink='http://www.w3.org/1999/xlink' ",
                            "shape-rendering='crispEdges' ",
                            canvasSize,
                            ">",
                            scaleStartTag,
                            "<image ",
                            imgSize,
                            " style='image-rendering: pixelated; image-rendering: crisp-edges;' ",
                            "href='",
                            encodedBitmap,
                            "'/></g></svg>"
                        )
                    )
                )
            );
    }

    /** @dev converts raw metadata into */
    function getAttributes(ShackledStructs.Metadata memory metadata)
        internal
        pure
        returns (bytes memory)
    {
        return
            abi.encodePacked(
                "{",
                '"Structure": "',
                metadata.geomSpec,
                '", "Chroma": "',
                metadata.colorScheme,
                '", "Pseudosymmetry": "',
                metadata.pseudoSymmetry,
                '", "Wireframe": "',
                metadata.wireframe,
                '", "Inversion": "',
                metadata.inversion,
                '", "Prisms": "',
                uint2str(metadata.nPrisms),
                '"}'
            );
    }

    /** @dev create and encode the token's metadata */
    function getEncodedMetadata(
        string memory image,
        ShackledStructs.Metadata memory metadata,
        uint256 tokenId
    ) internal view returns (string memory) {
        /// get attributes and description here to avoid stack too deep
        string
            memory description = '"description": "Shackled is the first general-purpose 3D renderer'
            " running on the Ethereum blockchain."
            ' Each piece represents a leap forward in on-chain computer graphics, and the collection itself is an NFT first."';
        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        bytes(
                            string(
                                abi.encodePacked(
                                    '{"name": "Shackled Genesis #',
                                    uint2str(tokenId),
                                    '", ',
                                    description,
                                    ', "attributes":',
                                    getAttributes(metadata),
                                    ', "image":"',
                                    image,
                                    '"}'
                                )
                            )
                        )
                    )
                )
            );
    }

    // fragment =
    // [ canvas_x, canvas_y, depth, col_x, col_y, col_z, normal_x, normal_y, normal_z, world_x, world_y, world_z ],
    /** @dev get an encoded 2d bitmap by combining the object and background fragments */
    function getEncodedBitmap(
        int256[12][] memory fragments,
        int256[5][] memory background,
        int256 canvasDim,
        bool invert
    ) internal view returns (string memory) {
        uint256 canvasDimUnsigned = uint256(canvasDim);
        bytes memory fileHeader = abi.encodePacked(
            hex"42_4d", // BM
            hex"36_04_00_00", // size of the bitmap file in bytes (14 (file header) + 40 (info header) + size of raw data (1024))
            hex"00_00_00_00", // 2x2 bytes reserved
            hex"36_00_00_00" // offset of pixels in bytes
        );
        bytes memory infoHeader = abi.encodePacked(
            hex"28_00_00_00", // size of the header in bytes (40)
            getHex(canvasDimUnsigned), // width in pixels 32
            getHex(canvasDimUnsigned), // height in pixels 32
            hex"01_00", // number of color plans (must be 1)
            hex"18_00", // number of bits per pixel (24)
            hex"00_00_00_00", // type of compression (none)
            hex"00_04_00_00", // size of the raw bitmap data (1024)
            hex"C4_0E_00_00", // horizontal resolution
            hex"C4_0E_00_00", // vertical resolution
            hex"00_00_00_00", // number of used colours
            hex"05_00_00_00" // number of important colours
        );
        bytes memory headers = abi.encodePacked(fileHeader, infoHeader);

        /// create a container for the bitmap's bytes
        bytes memory bytesArray = new bytes(3 * canvasDimUnsigned**2);

        /// write the background first so it is behind the fragments
        bytesArray = writeBackgroundToBytesArray(
            background,
            bytesArray,
            canvasDimUnsigned,
            invert
        );
        bytesArray = writeFragmentsToBytesArray(
            fragments,
            bytesArray,
            canvasDimUnsigned,
            invert
        );

        return
            string(
                abi.encodePacked(
                    "data:image/bmp;base64,",
                    Base64.encode(BytesUtils.MergeBytes(headers, bytesArray))
                )
            );
    }

    /** @dev write the fragments to the bytes array */
    function writeFragmentsToBytesArray(
        int256[12][] memory fragments,
        bytes memory bytesArray,
        uint256 canvasDimUnsigned,
        bool invert
    ) internal pure returns (bytes memory) {
        /// loop through each fragment
        /// and write it's color into bytesArray in its canvas equivelant position
        for (uint256 i = 0; i < fragments.length; i++) {
            /// check if x and y are both greater than 0
            if (
                uint256(fragments[i][0]) >= 0 && uint256(fragments[i][1]) >= 0
            ) {
                /// calculating the starting bytesArray ix for this fragment's colors
                uint256 flatIx = ((canvasDimUnsigned -
                    uint256(fragments[i][1]) -
                    1) *
                    canvasDimUnsigned +
                    (canvasDimUnsigned - uint256(fragments[i][0]) - 1)) * 3;

                /// red
                uint256 r = fragments[i][3] > 255
                    ? 255
                    : uint256(fragments[i][3]);

                /// green
                uint256 g = fragments[i][4] > 255
                    ? 255
                    : uint256(fragments[i][4]);

                /// blue
                uint256 b = fragments[i][5] > 255
                    ? 255
                    : uint256(fragments[i][5]);

                if (invert) {
                    r = 255 - r;
                    g = 255 - g;
                    b = 255 - b;
                }

                bytesArray[flatIx + 0] = bytes1(uint8(b));
                bytesArray[flatIx + 1] = bytes1(uint8(g));
                bytesArray[flatIx + 2] = bytes1(uint8(r));
            }
        }
        return bytesArray;
    }

    /** @dev write the fragments to the bytes array 
    using a separate function from above to account for variable input size
    */
    function writeBackgroundToBytesArray(
        int256[5][] memory background,
        bytes memory bytesArray,
        uint256 canvasDimUnsigned,
        bool invert
    ) internal pure returns (bytes memory) {
        /// loop through each fragment
        /// and write it's color into bytesArray in its canvas equivelant position
        for (uint256 i = 0; i < background.length; i++) {
            /// check if x and y are both greater than 0
            if (
                uint256(background[i][0]) >= 0 && uint256(background[i][1]) >= 0
            ) {
                /// calculating the starting bytesArray ix for this fragment's colors
                uint256 flatIx = (uint256(background[i][1]) *
                    canvasDimUnsigned +
                    uint256(background[i][0])) * 3;

                // red
                uint256 r = background[i][2] > 255
                    ? 255
                    : uint256(background[i][2]);

                /// green
                uint256 g = background[i][3] > 255
                    ? 255
                    : uint256(background[i][3]);

                // blue
                uint256 b = background[i][4] > 255
                    ? 255
                    : uint256(background[i][4]);

                if (invert) {
                    r = 255 - r;
                    g = 255 - g;
                    b = 255 - b;
                }

                bytesArray[flatIx + 0] = bytes1(uint8(b));
                bytesArray[flatIx + 1] = bytes1(uint8(g));
                bytesArray[flatIx + 2] = bytes1(uint8(r));
            }
        }
        return bytesArray;
    }
}

/// [MIT License]
/// @title Base64
/// @notice Provides a function for encoding some bytes in base64
/// @author Brecht Devos <[email protected]>
library Base64 {
    bytes internal constant TABLE =
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /// @notice Encodes some bytes to the base64 representation
    function encode(bytes memory data) internal view returns (string memory) {
        uint256 len = data.length;
        if (len == 0) return "";

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((len + 2) / 3);

        // Add some extra buffer at the end
        bytes memory result = new bytes(encodedLen + 32);

        bytes memory table = TABLE;

        assembly {
            let tablePtr := add(table, 1)
            let resultPtr := add(result, 32)

            for {
                let i := 0
            } lt(i, len) {

            } {
                i := add(i, 3)
                let input := and(mload(add(data, i)), 0xffffff)

                let out := mload(add(tablePtr, and(shr(18, input), 0x3F)))
                out := shl(8, out)
                out := add(
                    out,
                    and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF)
                )
                out := shl(8, out)
                out := add(
                    out,
                    and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF)
                )
                out := shl(8, out)
                out := add(
                    out,
                    and(mload(add(tablePtr, and(input, 0x3F))), 0xFF)
                )
                out := shl(224, out)

                mstore(resultPtr, out)

                resultPtr := add(resultPtr, 4)
            }

            switch mod(len, 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }

            mstore(result, encodedLen)
        }

        return string(result);
    }
}

library BytesUtils {
    function char(bytes1 b) internal view returns (bytes1 c) {
        if (uint8(b) < 10) return bytes1(uint8(b) + 0x30);
        else return bytes1(uint8(b) + 0x57);
    }

    function bytes32string(bytes32 b32)
        internal
        view
        returns (string memory out)
    {
        bytes memory s = new bytes(64);
        for (uint32 i = 0; i < 32; i++) {
            bytes1 b = bytes1(b32[i]);
            bytes1 hi = bytes1(uint8(b) / 16);
            bytes1 lo = bytes1(uint8(b) - 16 * uint8(hi));
            s[i * 2] = char(hi);
            s[i * 2 + 1] = char(lo);
        }
        out = string(s);
    }

    function hach(string memory value) internal view returns (string memory) {
        return bytes32string(sha256(abi.encodePacked(value)));
    }

    function MergeBytes(bytes memory a, bytes memory b)
        internal
        pure
        returns (bytes memory c)
    {
        // Store the length of the first array
        uint256 alen = a.length;
        // Store the length of BOTH arrays
        uint256 totallen = alen + b.length;
        // Count the loops required for array a (sets of 32 bytes)
        uint256 loopsa = (a.length + 31) / 32;
        // Count the loops required for array b (sets of 32 bytes)
        uint256 loopsb = (b.length + 31) / 32;
        assembly {
            let m := mload(0x40)
            // Load the length of both arrays to the head of the new bytes array
            mstore(m, totallen)
            // Add the contents of a to the array
            for {
                let i := 0
            } lt(i, loopsa) {
                i := add(1, i)
            } {
                mstore(
                    add(m, mul(32, add(1, i))),
                    mload(add(a, mul(32, add(1, i))))
                )
            }
            // Add the contents of b to the array
            for {
                let i := 0
            } lt(i, loopsb) {
                i := add(1, i)
            } {
                mstore(
                    add(m, add(mul(32, add(1, i)), alen)),
                    mload(add(b, mul(32, add(1, i))))
                )
            }
            mstore(0x40, add(m, add(32, totallen)))
            c := m
        }
    }
}