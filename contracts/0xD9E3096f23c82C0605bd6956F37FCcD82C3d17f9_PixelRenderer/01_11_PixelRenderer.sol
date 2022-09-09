// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.13;

import "../BufferUtils.sol";

import "./IPixelRenderer.sol";
import "./Errors.sol";
import "./AlphaBlend.sol";

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

    function drawFrameWithOffsets(DrawFrame memory f)
        external
        pure
        returns (uint32[] memory buffer, uint256)
    {
        (uint32 instructionCount, uint256 position) = BufferUtils.readUInt32(
            f.position,
            f.buffer
        );
        f.position = position;

        for (uint32 i = 0; i < instructionCount; i++) {
            uint8 instructionType = uint8(f.buffer[f.position++]);

            if (instructionType == 0) {
                uint32 color = f.colors[uint8(f.buffer[f.position++])];
                for (uint16 x = 0; x < f.frame.width; x++) {
                    for (uint16 y = 0; y < f.frame.height; y++) {
                        f.frame.buffer[f.frame.width * y + x] = color;
                    }
                }
            } else if (instructionType == 1) {
                uint32 color = f.colors[uint8(f.buffer[f.position++])];

                int32 x0 = int8(uint8(f.buffer[f.position++]));
                int32 y0 = int8(uint8(f.buffer[f.position++]));
                int32 x1 = int8(uint8(f.buffer[f.position++]));
                int32 y1 = int8(uint8(f.buffer[f.position++]));

                x0 += int8(f.ox);
                y0 += int8(f.oy);
                x1 += int8(f.ox);
                y1 += int8(f.oy);

                line(
                    f.frame,
                    PixelRenderer.Line2D(
                        PixelRenderer.Point2D(x0, y0),
                        PixelRenderer.Point2D(x1, y1),
                        color
                    ),
                    f.blend
                );
            } else if (instructionType == 2) {
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

    function getColorTable(bytes memory buffer, uint256 position)
        external
        pure
        returns (uint32[] memory colors, uint256)
    {
        uint8 colorCount = uint8(buffer[position++]);
        colors = new uint32[](1 + colorCount);
        colors[0] = 0xFF000000;

        for (uint8 i = 0; i < colorCount; i++) {
            uint32 a = uint32(uint8(buffer[position++]));
            uint32 r = uint32(uint8(buffer[position++]));
            uint32 g = uint32(uint8(buffer[position++]));
            uint32 b = uint32(uint8(buffer[position++]));
            uint32 color = 0;
            color |= a << 24;
            color |= r << 16;
            color |= g << 8;
            color |= b << 0;

            if (color == colors[0]) {
                revert DoNotAddBlackToColorTable();
            }

            colors[i + 1] = color;
        }

        return (colors, position);
    }

    function dot(
        AnimationFrame memory frame,
        int32 x,
        int32 y,
        uint32 color,
        AlphaBlend.Type blend
    ) private pure {
        uint32 p = uint32(int16(frame.width) * y + x);
        frame.buffer[p] = blendPixel(frame.buffer[p], color, blend);
    }

    function line(
        AnimationFrame memory frame,
        Line2D memory f,
        AlphaBlend.Type blend
    ) private pure {
        int256 x0 = f.v0.x;
        int256 x1 = f.v1.x;
        int256 y0 = f.v0.y;
        int256 y1 = f.v1.y;

        int256 dx = abs(x1 - x0);
        int256 dy = abs(y1 - y0);

        int256 err = (dx > dy ? dx : -dy) / 2;

        for (;;) {
            if (
                x0 <= int32(0) + int16(frame.width) - 1 &&
                x0 >= int32(0) &&
                y0 <= int32(0) + int16(frame.height) - 1 &&
                y0 >= int32(0)
            ) {
                uint256 p = uint256(int16(frame.width) * y0 + x0);
                frame.buffer[p] = blendPixel(frame.buffer[p], f.color, blend);
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

    function blendPixel(
        uint32 bg,
        uint32 fg,
        AlphaBlend.Type blend
    ) private pure returns (uint32) {
        if (blend == AlphaBlend.Type.Default) {
            return AlphaBlend.alpha_composite_default(bg, fg);
        } else if (blend == AlphaBlend.Type.Accurate) {
            return AlphaBlend.alpha_composite_accurate(bg, fg);
        } else if (blend == AlphaBlend.Type.Fast) {
            return AlphaBlend.alpha_composite_fast(bg, fg);
        } else if (blend == AlphaBlend.Type.Pillow) {
            return AlphaBlend.alpha_composite_pillow(bg, fg);
        }
        return fg;
    }

    function abs(int256 x) internal pure returns (int256) {
        return x >= 0 ? x : -x;
    }
}