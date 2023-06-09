// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title Util
/// @notice Utility functions for On-Chain pixel NFTs
/// @author ponky
library Utils {
    /// @notice divides image’s RGB values by its alpha values
    function unpremultiplyingAlpha(bytes memory pixels) internal pure {
        unchecked {
            uint pi = 0;
            assembly {
                pi := add(pi, pixels)
            }
           
            uint length = pixels.length; 
            for (uint i; i<length; i+=32) { // pixels is assumed to be 8 pixels aligned
                pi += 32;
                uint256 p;
                assembly {
                    p := mload(pi)
                }
                if (p != 0) {
                    uint pixelShift = 256;
                    do {
                        pixelShift -= 32;
                        uint256 color = (p >> pixelShift) & 0xffffffff;
                        uint256 alpha = color & 0xff;
                        if (alpha != 0 && alpha != 255) {
                            color = (((((color >> 24) & 0xff) * 255) / alpha) << 24) |
                                    (((((color >> 16) & 0xff) * 255) / alpha) << 16) |
                                    (((((color >>  8) & 0xff) * 255) / alpha) <<  8) |
                                    alpha;
                            p = (p & ~(0xffffffff << pixelShift)) | (color << pixelShift);
                        }
                    } while (pixelShift > 0);
                    

                    assembly {
                        mstore(pi, p)
                    }
                }
            }
        }
    }

    /// @notice blends the compressed image of an asset onto a 24x24 pixel image, RGB values are premultiplied by the alpha value
    function blend(bytes memory pixels, bytes memory asset) internal pure returns (bool hasAlpha) {
        unchecked {
            uint offset = uint(uint8(asset[0])); // offset to image data

            uint pi;
            {
                uint left = uint(uint8(asset[offset]));
                uint top = uint(uint8(asset[offset+1]));
                pi = (top * 24 + left) * 4;
            }
            assembly {
                pi := add(pi, pixels)
            }

            hasAlpha = (uint8(asset[offset+3]) & 1) != 0;

            uint ci = 0;
            uint ii = 0;
            uint count = 0;

            uint length = asset.length * 2;
            for (uint ai=(offset + 4 + uint(uint8(asset[offset+2])) * 4) * 2; ai<length; ai++) {
                uint i;

                if ((ai & 1) != 0) {
                    i = ii & 0xF;

                    if (i == 0xf) {
                        ai++;
                        ii = uint(uint8(asset[ai >> 1]));
                        count += (ii >> 4) + 3;
                        continue;
                    }
                }
                else {
                    ii = uint(uint8(asset[ai >> 1]));
                    i = ii >> 4;

                    if (i == 0xf) {
                        ai++;
                        count += (ii & 0xf) + 3;
                        continue;
                    }
                }

                if (ci != i) {
                    if (ci == 0) {
                        pi += count * 4;
                    }
                    else {
                        ci = offset + ci * 4 + 4;
                        if (hasAlpha) {
                            assembly {
                                let color := and(mload(add(asset, ci)), 0xffffffff)
                                let a := sub(256, and(color, 0xff))
                                for {} gt(count, 0) {count := sub(count, 1)} {
                                    pi := add(pi, 4)
                                    let p := mload(pi)
                                    p := or(and(p, 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffff00000000), add(color, or(and(shr(8, mul(and(p, 0xff00ff00), a)), 0xff00ff00), and(shr(8, mul(and(p, 0xff00ff), a)), 0xff00ff))))
                                    mstore(pi, p)
                                }
                            }
                        }
                        else {
                            assembly {
                                let color := and(mload(add(asset, ci)), 0xffffffff)
                                for {} gt(count, 0) {count := sub(count, 1)} {
                                    pi := add(pi, 4)
                                    let p := mload(pi)
                                    p := or(and(p, 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffff00000000), color)
                                    mstore(pi, p)
                                }
                            }
                        }
                    }

                    ci = i;
                    count = 0;
                }

                count++;
            }
        }
    }

    /// @notice Append strLength bytes of the left-aligned str to buffer
    function appendString(bytes memory buffer, uint256 str, uint256 strLength) internal pure {
        uint256 length = buffer.length;
        assembly {
            let shift := shl(3, sub(32, strLength))
            let strc := shl(shift, shr(shift, str))

            let bufferptr := add(buffer, add(0x20, length))
            mstore(bufferptr, strc)
            mstore(buffer, add(length, strLength))
        }
    }

    function appendString(bytes memory buffer, bytes32 str, uint256 strLength) internal pure {
        appendString(buffer, uint256(str), strLength);
    }

    /// @notice append  astring to buffer
    function appendString(bytes memory buffer, string memory str) internal pure {
        uint256 strLength = bytes(str).length;
        uint256 length = buffer.length;
        assembly {
            let strptr := add(str, 0x20)
            let bufferptr := add(buffer, add(0x20, length))

            let l := strLength
            for {} gt(l, 31) { l := sub(l, 32) } { 
                mstore(bufferptr, mload(strptr))
                strptr := add(strptr, 32)
                bufferptr := add(bufferptr, 32)
            }

            if gt(l, 0) {
                let shift := shl(3, sub(32, l))
                let strc := shl(shift, shr(shift, mload(strptr)))
                mstore(bufferptr, strc)
            }
        
            mstore(buffer, add(length, strLength))
        }        
    }

    bytes16 private constant HEX_SYMBOLS = "0123456789abcdef";

    /// @notice append an RGBA color as a hex string to buffer
    function appendColor(bytes memory buffer, uint256 color) internal pure {
        uint256 str = 0;
        unchecked {
            uint colorShift = 32;
            do {
                colorShift -= 4;
                str |= uint256(uint8(HEX_SYMBOLS[(color >> colorShift) & 0xf])) << (192 + (colorShift<<1));
            } while (colorShift > 0);
        }

        appendString(buffer, str, 8);
    }

    /// @notice append a number as a decimal value string to buffer, number must be within 32 digits
    function appendNumber(bytes memory buffer, uint256 number) internal pure {
        uint256 str = 0;
        uint256 strLength = 0;
        unchecked {
            do {
                uint256 digit = (number % 10) + 48;
                str = (str >> 8) | (digit << 248);
                number /= 10;
                strLength++;
            } while (number > 0);
        }

        appendString(buffer, str, strLength);
    }

    /// @notice convert number to a decimal value string, number must be within 32 digits
    function toString(uint256 number) internal pure returns (string memory) {
        bytes memory buffer = new bytes(32);
        assembly {
            mstore(buffer, 0) // set initial length to 0
        }
        appendNumber(buffer, number);
        return string(buffer);
    }

    /// @notice blends a premultiplied RGBA color with an RGBA background color
    function blendColor(uint256 colorBackground, uint256 colorBlend) internal pure returns (uint256) {
        unchecked {
            uint256 ai = 255 - (colorBlend & 0xff);
            return  colorBlend + (
                    (((((colorBackground >> 24) & 0xff) * ai) / 255) << 24) |
                    (((((colorBackground >> 16) & 0xff) * ai) / 255) << 16) |
                    (((((colorBackground >>  8) & 0xff) * ai) / 255) <<  8) |
                    (((((colorBackground      ) & 0xff) * ai) / 255)      ));
        }
    }

    /// @notice append a colored SVG rect shape to the buffer
    function appendSVGRect(bytes memory buffer, uint256 x, uint256 y, uint256 width, uint256 height, uint256 color) internal pure {
        appendString(buffer, bytes32('<rect x="'), 9);
        appendNumber(buffer, x);
        appendString(buffer, bytes32('" y="'), 5);
        appendNumber(buffer, y);
        appendString(buffer, bytes32('" width="'), 9);
        appendNumber(buffer, width);
        appendString(buffer, bytes32('" height="'), 10);
        appendNumber(buffer, height);
        appendString(buffer, bytes32('" shape-rendering="crispEdges'), 29);
        appendString(buffer, bytes32('" fill="#'), 9);
        appendColor(buffer, color);
        appendString(buffer, bytes32('"/>'), 3);
    }

    /// @notice convert RGBA pixel data to a pixelated SVG and store it in buffer, buffer needs to be allocated with enough space
    /// @dev macOS has artifacts when rendering adjacent translucent rectangles so tranlucent pixels are blended with the background color
    function createSVG(bytes memory buffer, bytes memory pixels, uint256 width, uint256 height, uint256 backgroundColor) internal pure {
        assembly {
            mstore(buffer, 0) // set initial length to 0
        }
        unchecked {
            Utils.appendString(buffer, '<svg xmlns="http://www.w3.org/2000/svg" version="1.1" viewBox="0 0 24 24">');
            if (backgroundColor != 0) {   
                Utils.appendSVGRect(buffer, 0, 0, width, height, backgroundColor);
            }

            uint pi = 0;
            assembly {
                pi := add(pi, pixels)
            }

            for (uint y=0; y<height; y++) {
                uint w = 0;
                uint l = 0;
                uint prevColor = 0;
                for (uint x=0; x<width; ) {
                    pi += 32;
                    uint256 p;
                    assembly {
                        p := mload(pi)
                    }
                    uint pixelShift = 256;
                    do {
                        pixelShift -= 32;
                        uint256 color = (p >> pixelShift) & 0xffffffff;
                        if (color != prevColor) {
                            if (w > 0) {
                                if ((prevColor & 0xff) != 0xff) {
                                    prevColor = blendColor(backgroundColor, prevColor);
                                }
                                Utils.appendSVGRect(buffer, l, y, w, 1, prevColor);
                                w = 0;
                            }
                            prevColor = color;
                            l = x;
                        }
                        
                        if (color != 0) {
                            w++;
                        }

                        x++;
                    } while (pixelShift > 0);
                }
                if (w > 0) {
                    if ((prevColor & 0xff) != 0xff) {
                        prevColor = blendColor(backgroundColor, prevColor);
                    }
                    Utils.appendSVGRect(buffer, l, y, w, 1, prevColor);
                }
            }
            Utils.appendString(buffer, bytes32('</svg>'), 6);
        }
    }
}