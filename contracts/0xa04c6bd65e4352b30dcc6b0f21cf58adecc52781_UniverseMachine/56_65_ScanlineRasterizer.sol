// SPDX-License-Identifier: UNLICENSED
/* Copyright (c) 2021 Kohi Art Community, Inc. All rights reserved. */

pragma solidity ^0.8.13;

import "./SubpixelScale.sol";
import "./ScanlineData.sol";
import "./ClippingData.sol";
import "./CellData.sol";
import "./Graphics2D.sol";
import "./CellRasterizer.sol";
import "./ColorMath.sol";
import "./PixelClipping.sol";

library ScanlineRasterizer {
    function renderSolid(
        Graphics2D memory g,
        uint32 color,
        bool blend
    ) external pure returns (Graphics2D memory) {       
        
        if (rewindScanlines(g)) {
            resetScanline(g.cellData.minX, g.cellData.maxX, g.scanlineData);
            while (sweepScanline(g)) {

                int32 y = g.scanlineData.y;
                int32 spanCount = g.scanlineData.spanIndex;
                ScanlineSpan memory scanlineSpan = begin(g.scanlineData);
                
                uint8[] memory covers = g.scanlineData.covers;
                for (;;) {
                    int32 x = scanlineSpan.x;
                    if (scanlineSpan.length > 0) {
                        blendSolidHorizontalSpan(
                            g,
                            BlendSolidHorizontalSpan(
                                x,
                                y,
                                scanlineSpan.length,
                                color,
                                covers,
                                scanlineSpan.coverIndex,
                                blend
                            )
                        );
                    } else {                       

                        int32 x2 = x - scanlineSpan.length - 1;
                        blendHorizontalLine(
                            g,
                            BlendHorizontalLine(
                                x,
                                y,
                                x2,
                                color,
                                covers[uint32(scanlineSpan.coverIndex)],
                                blend
                            )
                        );
                    }

                    if (--spanCount == 0) break;
                    scanlineSpan = getNextScanlineSpan(g.scanlineData);                    
                }
            }
        }
        
        return g;
    }

    function sweepScanline(Graphics2D memory g) private pure returns (bool) {
        for (;;) {
            if (g.scanlineData.scanY > g.cellData.maxY) return false;

            resetSpans(g.scanlineData);
            int32 cellCount = g
                .cellData
                .sortedY[uint32(g.scanlineData.scanY - g.cellData.minY)]
                .count;

            (Cell[] memory cells, int32 offset) = scanlineCells(
                g.scanlineData.scanY,
                g.cellData
            );
            int32 cover = 0;

            while (cellCount != 0) {
                Cell memory current = cells[uint32(offset)];
                int32 x = current.x;
                int32 area = current.area;
                int32 alpha;

                cover += current.cover;

                while (--cellCount != 0) {
                    offset++;
                    current = cells[uint32(offset)];
                    if (current.x != x) break;

                    area += current.area;
                    cover += current.cover;
                }

                if (area != 0) {
                    alpha = calculateAlpha(
                        g,
                        (cover << (g.ss.value + 1)) - area
                    );
                    if (alpha != 0) {
                        addCell(g.scanlineData, x, alpha);
                    }
                    x++;
                }

                if (cellCount != 0 && current.x > x) {
                    alpha = calculateAlpha(g, cover << (g.ss.value + 1));
                    if (alpha != 0) {
                        addSpan(g.scanlineData, x, current.x - x, alpha);
                    }
                }
            }

            if (g.scanlineData.spanIndex != 0) break;
            ++g.scanlineData.scanY;
        }

        g.scanlineData.y = g.scanlineData.scanY;
        ++g.scanlineData.scanY;
        return true;
    }

    function calculateAlpha(Graphics2D memory g, int32 area)
        private
        pure
        returns (int32)
    {
        int32 cover = area >> (g.ss.value * 2 + 1 - g.aa.value);
        if (cover < 0) cover = -cover;
        if (cover > int32(g.aa.mask)) cover = int32(g.aa.mask);
        return g.scanlineData.gamma[uint32(cover)];
    }

    function addSpan(
        ScanlineData memory scanlineData,
        int32 x,
        int32 len,
        int32 cover
    ) private pure {
        if (
            x == scanlineData.lastX + 1 &&
            scanlineData.spans[uint32(scanlineData.spanIndex)].length < 0 &&
            cover ==
            scanlineData.spans[uint32(scanlineData.spanIndex)].coverIndex
        ) {
            scanlineData.spans[uint32(scanlineData.spanIndex)].length -= int16(
                len
            );
        } else {
            scanlineData.covers[uint32(scanlineData.coverIndex)] = uint8(
                uint32(cover)
            );
            scanlineData.spanIndex++;
            scanlineData
                .spans[uint32(scanlineData.spanIndex)]
                .coverIndex = scanlineData.coverIndex++;
            scanlineData.spans[uint32(scanlineData.spanIndex)].x = int16(x);
            scanlineData.spans[uint32(scanlineData.spanIndex)].length = int16(
                -len
            );
        }

        scanlineData.lastX = x + len - 1;
    }

    function addCell(
        ScanlineData memory scanlineData,
        int32 x,
        int32 cover
    ) private pure {
        scanlineData.covers[uint32(scanlineData.coverIndex)] = uint8(
            uint32(cover)
        );
        if (
            x == scanlineData.lastX + 1 &&
            scanlineData.spans[uint32(scanlineData.spanIndex)].length > 0
        ) {
            scanlineData.spans[uint32(scanlineData.spanIndex)].length++;
        } else {
            scanlineData.spanIndex++;
            scanlineData
                .spans[uint32(scanlineData.spanIndex)]
                .coverIndex = scanlineData.coverIndex;
            scanlineData.spans[uint32(scanlineData.spanIndex)].x = int16(x);
            scanlineData.spans[uint32(scanlineData.spanIndex)].length = 1;
        }

        scanlineData.lastX = x;
        scanlineData.coverIndex++;
    }

    function resetSpans(ScanlineData memory scanlineData) private pure {
        scanlineData.lastX = 0x7FFFFFF0;
        scanlineData.coverIndex = 0;
        scanlineData.spanIndex = 0;
        scanlineData.spans[uint32(scanlineData.spanIndex)].length = 0;
    }

    function begin(ScanlineData memory scanlineData)
        private
        pure
        returns (ScanlineSpan memory)
    {
        scanlineData.current = 1;
        return getNextScanlineSpan(scanlineData);
    }

    function resetScanline(
        int32 minX,
        int32 maxX,
        ScanlineData memory scanlineData
    ) private pure {
        int32 maxLength = maxX - minX + 3;
        if (maxLength > int256(scanlineData.spans.length)) {
            scanlineData.spans = new ScanlineSpan[](uint32(maxLength));
            scanlineData.covers = new uint8[](uint32(maxLength));
        }
        scanlineData.lastX = 0x7FFFFFF0;
        scanlineData.coverIndex = 0;
        scanlineData.spanIndex = 0;
        scanlineData.spans[uint32(scanlineData.spanIndex)].length = 0;
    }

    function getNextScanlineSpan(ScanlineData memory scanlineData)
        private
        pure
        returns (ScanlineSpan memory)
    {
        scanlineData.current++;
        return scanlineData.spans[uint32(scanlineData.current - 1)];
    }

    function scanlineCells(int32 y, CellData memory cellData)
        private
        pure
        returns (Cell[] memory cells, int32 offset)
    {
        cells = cellData.sortedCells;
        offset = cellData.sortedY[uint32(y - cellData.minY)].start;
    }

    function rewindScanlines(Graphics2D memory g) private pure returns (bool) {
        Graphics2DMethods.closePolygon(g);
        CellRasterizer.sortCells(g.cellData);
        if (g.cellData.used == 0) return false;
        g.scanlineData.scanY = g.cellData.minY;
        return true;
    }

    struct BlendSolidHorizontalSpan {
        int32 x;
        int32 y;
        int32 len;
        uint32 sourceColor;
        uint8[] covers;
        int32 coversIndex;
        bool blend;
    }

    function blendSolidHorizontalSpan(
        Graphics2D memory g,
        BlendSolidHorizontalSpan memory f
    ) private pure {

        int32 colorAlpha = (int32)(f.sourceColor >> 24);

        if (colorAlpha != 0) {
            unchecked {
                int32 bufferOffset = Graphics2DMethods.getBufferOffsetXy(
                    g,
                    f.x,
                    f.y
                );
                if (bufferOffset == -1) return;

                int32 i = 0;
                do {
                    int32 alpha = !f.blend ? colorAlpha : (colorAlpha * int32(uint32(f.covers[uint32(f.coversIndex)] + 1))) >> 8;

                    if (alpha == 255)
                        Graphics2DMethods.copyPixels(
                            g.buffer,
                            bufferOffset,
                            f.sourceColor,
                            1,
                            g.clippingData.clipPoly.length == 0
                                ? PixelClipping(new Vector2[](0), 0, 0)
                                : PixelClipping(
                                    g.clippingData.clipPoly,
                                    f.x + i,
                                    f.y
                                )
                        );
                    else {

                        uint32 targetColor = ColorMath.toColor(uint8(uint32(alpha)), 
                            uint8(f.sourceColor >> 16), 
                            uint8(f.sourceColor >> 8), 
                            uint8(f.sourceColor >> 0));

                        Graphics2DMethods.blendPixel(
                            g.buffer,
                            bufferOffset,
                            targetColor,
                            g.clippingData.clipPoly.length == 0
                                ? PixelClipping(new Vector2[](0), 0, 0)
                                : PixelClipping(
                                    g.clippingData.clipPoly,
                                    f.x + i,
                                    f.y
                                )
                        );
                    }

                    bufferOffset += 4;
                    f.coversIndex++;
                    i++;
                } while (--f.len != 0);
            }
        }
    }

    struct BlendHorizontalLine {
        int32 x1;
        int32 y;
        int32 x2;
        uint32 sourceColor;
        uint8 cover;
        bool blend;
    }

    function blendHorizontalLine(
        Graphics2D memory g,
        BlendHorizontalLine memory f
    ) private pure {
        int32 colorAlpha = (int32)(f.sourceColor >> 24);
        if (colorAlpha != 0) {

            int32 len = f.x2 - f.x1 + 1;
            int32 bufferOffset = Graphics2DMethods.getBufferOffsetXy(g, f.x1, f.y);            
            int32 alpha = !f.blend ? colorAlpha : (colorAlpha * int32(uint32(f.cover)) + 1) >> 8;

            if (alpha == 255) {
                Graphics2DMethods.copyPixels(
                    g.buffer,
                    bufferOffset,
                    f.sourceColor,
                    len,
                    g.clippingData.clipPoly.length == 0
                        ? PixelClipping(new Vector2[](0), 0, 0)
                        : PixelClipping(g.clippingData.clipPoly, f.x1, f.y)
                );
            } else {
                int32 i = 0;
                
                uint32 targetColor = ColorMath.toColor(uint8(uint32(alpha)), 
                uint8(f.sourceColor >> 16), 
                uint8(f.sourceColor >> 8), 
                uint8(f.sourceColor >> 0));

                do {
                    Graphics2DMethods.blendPixel(
                        g.buffer,
                        bufferOffset,
                        targetColor,
                        g.clippingData.clipPoly.length == 0
                            ? PixelClipping(new Vector2[](0), 0, 0)
                            : PixelClipping(
                                g.clippingData.clipPoly,
                                f.x1 + i,
                                f.y
                            )
                    );

                    bufferOffset += 4;
                    i++;
                } while (--len != 0);
            }
        }
    }
}