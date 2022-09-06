// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.13;

import "./IPixelRenderer.sol";
import "./BufferUtils.sol";
import "./Errors.sol";

/** @notice Pixel renderer using basic drawing instructions: fill, line, and dot. */
contract PixelRenderer is IPixelRenderer {

    struct Point2D {
        int32 x;
        int32 y;
    }

    struct Line2D {
        Point2D v0;
        Point2D v1;
        uint32 color;
    }

    function drawFrameWithOffsets(DrawFrame memory f) external pure returns (uint32[] memory buffer, uint) {       
        
        (uint32 instructionCount, uint position) = BufferUtils.readUInt32(f.position, f.buffer);
        f.position = position;
        
        for(uint32 i = 0; i < instructionCount; i++) {

            uint8 instructionType = uint8(f.buffer[f.position++]);                   

            if(instructionType == 0) {   
                uint32 color = f.colors[uint8(f.buffer[f.position++])];
                for (uint16 x = 0; x < f.frame.width; x++) {
                    for (uint16 y = 0; y < f.frame.height; y++) {
                        f.frame.buffer[f.frame.width * y + x] = color;
                    }
                }
            }
            else if(instructionType == 1)
            {                
                uint32 color = f.colors[uint8(f.buffer[f.position++])];

                int32 x0 = int8(uint8(f.buffer[f.position++]));                
                int32 y0 = int8(uint8(f.buffer[f.position++]));                
                int32 x1 = int8(uint8(f.buffer[f.position++]));
                int32 y1 = int8(uint8(f.buffer[f.position++]));

                x0 += int8(f.ox);
                y0 += int8(f.oy);
                x1 += int8(f.ox);
                y1 += int8(f.oy);

                line(f.frame, PixelRenderer.Line2D(
                    PixelRenderer.Point2D(x0, y0), 
                    PixelRenderer.Point2D(x1, y1),
                    color), f.blend);
            }
            else if(instructionType == 2)
            {   
                uint32 color = f.colors[uint8(f.buffer[f.position++])];
                
                int32 x = int8(uint8(f.buffer[f.position++]));
                int32 y = int8(uint8(f.buffer[f.position++]));
                x += int8(f.ox);
                y += int8(f.oy);

                dot(f.frame, x, y, color, f.blend);
            } else {
                revert UnsupportedDrawInstruction(instructionType);
            }
        }

        return (f.frame.buffer, f.position);
    }
    
    function getColorTable(bytes memory buffer, uint position) external pure returns(uint32[] memory colors, uint) {
        
        uint8 colorCount = uint8(buffer[position++]);
        colors = new uint32[](1 + colorCount);
        colors[0] = 0xFF000000;
        
        for(uint8 i = 0; i < colorCount; i++) {
            uint32 a = uint32(uint8(buffer[position++]));
            uint32 r = uint32(uint8(buffer[position++]));
            uint32 g = uint32(uint8(buffer[position++]));
            uint32 b = uint32(uint8(buffer[position++]));
            uint32 color = 0;
            color |= a << 24;
            color |= r << 16;
            color |= g << 8;
            color |= b << 0;

            if(color == colors[0]) {
                revert DoNotAddBlackToColorTable();
            }
             
            colors[i + 1] = color;                   
        }

        return (colors, position);
    }

    function dot(
        GIFFrame memory frame,
        int32 x,
        int32 y,
        uint32 color,
        bool blend
    ) private pure {
        uint32 p = uint32(int16(frame.width) * y + x);
        frame.buffer[p] = blend ? blendPixel(frame.buffer[p], color) : color;
    }

    function line(GIFFrame memory frame, Line2D memory f, bool blend)
        private
        pure
    {
        int256 x0 = f.v0.x;
        int256 x1 = f.v1.x;
        int256 y0 = f.v0.y;
        int256 y1 = f.v1.y;

        int256 dx = BufferUtils.abs(x1 - x0);
        int256 dy = BufferUtils.abs(y1 - y0);

        int256 err = (dx > dy ? dx : -dy) / 2;

        for (;;) {
            if (
                x0 <= int32(0) + int16(frame.width) - 1 &&
                x0 >= int32(0) &&
                y0 <= int32(0) + int16(frame.height) - 1 &&
                y0 >= int32(0)
            ) {
                uint256 p = uint256(int16(frame.width) * y0 + x0);
                frame.buffer[p] = blend ? blendPixel(frame.buffer[p], f.color) : f.color;
            }

            if (x0 == x1 && y0 == y1) break;
            int256 e2 = err;
            if (e2 > -dx) {
                err -= dy;
                x0 += x0 < x1 ? int8(1) : -1;
            }
            if (e2 < dy) {
                err += dx;
                y0 += y0 < y1 ? int8(1) : -1;
            }
        }
    }

    function blendPixel(uint32 bg, uint32 fg) private pure returns (uint32) {
        uint32 r1 = bg >> 16;
        uint32 g1 = bg >> 8;
        uint32 b1 = bg;
        
        uint32 a2 = fg >> 24;
        uint32 r2 = fg >> 16;
        uint32 g2 = fg >> 8;
        uint32 b2 = fg;
        
        uint32 alpha = (a2 & 0xFF) + 1;
        uint32 inverseAlpha = 257 - alpha;

        uint32 r = (alpha * (r2 & 0xFF) + inverseAlpha * (r1 & 0xFF)) >> 8;
        uint32 g = (alpha * (g2 & 0xFF) + inverseAlpha * (g1 & 0xFF)) >> 8;
        uint32 b = (alpha * (b2 & 0xFF) + inverseAlpha * (b1 & 0xFF)) >> 8;

        uint32 rgb = 0;
        rgb |= uint32(0xFF) << 24;
        rgb |= r << 16;
        rgb |= g << 8;
        rgb |= b;

        return rgb;
    }
}