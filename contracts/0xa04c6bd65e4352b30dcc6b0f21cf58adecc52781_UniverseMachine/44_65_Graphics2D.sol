// SPDX-License-Identifier: UNLICENSED
/* Copyright (c) 2021 Kohi Art Community, Inc. All rights reserved. */

pragma solidity ^0.8.13;

import "./Vector2.sol";
import "./Fix64V1.sol";
import "./AntiAlias.sol";
import "./SubpixelScale.sol";
import "./RectangleInt.sol";
import "./Matrix.sol";
import "./ScanlineData.sol";
import "./ClippingData.sol";
import "./CellData.sol";
import "./Clipping.sol";
import "./PixelClipping.sol";
import "./ColorMath.sol";
import "./ApplyTransform.sol";
import "./ScanlineRasterizer.sol";

struct Graphics2D {
    AntiAlias aa;
    SubpixelScale ss;
    ScanlineData scanlineData;
    ClippingData clippingData;
    CellData cellData;
    uint8[] buffer;
    uint32 width;
    uint32 height;
}

library Graphics2DMethods {
    int32 public constant OrderB = 0;
    int32 public constant OrderG = 1;
    int32 public constant OrderR = 2;
    int32 public constant OrderA = 3;

    function create(uint32 width, uint32 height)
        external
        pure
        returns (Graphics2D memory g)
    {
        g.width = width;
        g.height = height;

        g.aa = AntiAliasMethods.create(8);
        g.ss = SubpixelScaleMethods.create(8);
        g.scanlineData = ScanlineDataMethods.create(g.aa);
        g.clippingData = ClippingDataMethods.create(width, height, g.ss);
        g.cellData = CellDataMethods.create();
        g.buffer = new uint8[](width * 4 * height);
    }

    function clear(Graphics2D memory g, uint32 color)
        internal
        pure
    {
        int32 scale = int32(g.ss.scale);

        RectangleInt memory clippingRect = RectangleInt(
            g.clippingData.clipBox.left / scale,
            g.clippingData.clipBox.bottom / scale,
            g.clippingData.clipBox.right / scale,
            g.clippingData.clipBox.top / scale
        );

        for (int32 y = clippingRect.bottom; y < clippingRect.top; y++) {
            int32 bufferOffset = getBufferOffsetXy(g, clippingRect.left, y);

            for (int32 x = 0; x < clippingRect.right - clippingRect.left; x++) {
                g.buffer[uint32(bufferOffset + OrderB)] = uint8(color >> 0);
                g.buffer[uint32(bufferOffset + OrderG)] = uint8(color >> 8);
                g.buffer[uint32(bufferOffset + OrderR)] = uint8(color >> 16);
                g.buffer[uint32(bufferOffset + OrderA)] = uint8(color >> 24);
                bufferOffset += 4;
            }
        }
    }

    function renderWithTransform(
        Graphics2D memory g,
        VertexData[] memory vertices,
        uint32 color,
        Matrix memory transform,
        bool blend
    ) internal pure {
        if (!MatrixMethods.isIdentity(transform)) {
            vertices = ApplyTransform.applyTransform(vertices, transform);
        }
        render_impl(g, vertices, color, blend);
    }

    function render(
        Graphics2D memory g,
        VertexData[] memory vertices,
        uint32 color,
        bool blend
    ) internal pure {
        render_impl(g, vertices, color, blend);
    }

    function render_impl(
        Graphics2D memory g,
        VertexData[] memory vertices,
        uint32 color,
        bool blend
    ) private pure {
        reset(g.scanlineData, g.cellData);
        addPath(g, vertices);
        if(g.cellData.used != 23) {
            revert ("pre-fail");
        }
        if (g.buffer.length != 0) {
            g = ScanlineRasterizer.renderSolid(g, color, blend);
        }
        if(g.cellData.used != 24) {
            revert ("post-fail");
        }
    }

    function getBufferOffsetY(Graphics2D memory g, int32 y)
        internal
        pure
        returns (int32)
    {
        return y * int32(g.width) * 4;
    }

    function getBufferOffsetXy(
        Graphics2D memory g,
        int32 x,
        int32 y
    ) internal pure returns (int32) {
        if (x < 0 || x >= int32(g.width) || y < 0 || y >= int32(g.height))
            return -1;
        return y * int32(g.width) * 4 + x * 4;
    }

    function copyPixels(
        uint8[] memory buffer,
        int32 bufferOffset,
        uint32 sourceColor,
        int32 count,
        PixelClipping memory clipping
    ) internal pure {
        int32 i = 0;
        do {
            if (
                clipping.area.length > 0 &&
                !PixelClippingMethods.isPointInPolygon(
                    clipping,
                    clipping.x + i,
                    clipping.y
                )
            ) {
                i++;
                bufferOffset += 4;
                continue;
            }

            buffer[uint32(bufferOffset + OrderR)] = uint8(sourceColor >> 16);
            buffer[uint32(bufferOffset + OrderG)] = uint8(sourceColor >> 8);
            buffer[uint32(bufferOffset + OrderB)] = uint8(sourceColor >> 0);
            buffer[uint32(bufferOffset + OrderA)] = uint8(sourceColor >> 24);
            bufferOffset += 4;
            i++;
        } while (--count != 0);
    }

    function blendPixel(
        uint8[] memory buffer,
        int32 bufferOffset,
        uint32 sourceColor,
        PixelClipping memory clipping
    ) internal pure {
        if (bufferOffset == -1) return;

        if (
            clipping.area.length > 0 &&
            !PixelClippingMethods.isPointInPolygon(
                clipping,
                clipping.x,
                clipping.y
            )
        ) {
            return;
        }

        {
            uint8 sr = uint8(sourceColor >> 16);
            uint8 sg = uint8(sourceColor >> 8);
            uint8 sb = uint8(sourceColor >> 0);
            uint8 sa = uint8(sourceColor >> 24);

            unchecked
            {
                if (sourceColor >> 24 == 255)
                {
                    buffer[uint32(bufferOffset + OrderR)] = sr;
                    buffer[uint32(bufferOffset + OrderG)] = sg;
                    buffer[uint32(bufferOffset + OrderB)] = sb;
                    buffer[uint32(bufferOffset + OrderA)] = sa;
                }
                else
                {
                    int32 r = int32(uint32(buffer[uint32(bufferOffset + OrderR)]));
                    int32 g = int32(uint32(buffer[uint32(bufferOffset + OrderG)]));
                    int32 b = int32(uint32(buffer[uint32(bufferOffset + OrderB)]));
                    int32 a = int32(uint32(buffer[uint32(bufferOffset + OrderA)]));

                    buffer[uint32(bufferOffset + OrderR)] = uint8(uint32(((int32(uint32(sr)) - r) * int32(uint32(sa)) + (r << 8)) >> 8));
                    buffer[uint32(bufferOffset + OrderG)] = uint8(uint32(((int32(uint32(sg)) - g) * int32(uint32(sa)) + (g << 8)) >> 8));
                    buffer[uint32(bufferOffset + OrderB)] = uint8(uint32(((int32(uint32(sb)) - b) * int32(uint32(sa)) + (b << 8)) >> 8));
                    buffer[uint32(bufferOffset + OrderA)] = uint8(uint32(int32(uint32(sa)) + a - ((int32(uint32(sa)) * a + 255) >> 8)));
                }
            }
        }
    }

    function addPath(Graphics2D memory g, VertexData[] memory vertices)
        private
        pure
    {
        if (g.cellData.sorted) {
            reset(g.scanlineData, g.cellData);
        }

        for (uint32 i = 0; i < vertices.length; i++) {
            VertexData memory vertex = vertices[i];
            if (vertex.command == Command.Stop) break;

            Command command = vertex.command;

            if (command == Command.MoveTo) {
                if (g.cellData.sorted) reset(g.scanlineData, g.cellData);
                closePolygon(g);
                g.scanlineData.startX = ClippingDataMethods.upscale(vertex.position.x, g.ss);
                g.scanlineData.startY = ClippingDataMethods.upscale(vertex.position.y, g.ss);
                Clipping.moveToClip(g.scanlineData.startX, g.scanlineData.startY, g.clippingData);
                g.scanlineData.status = ScanlineStatus.MoveTo;
            } else {
                if (command != Command.Stop && command != Command.EndPoly) {
                    Clipping.lineToClip(g, ClippingDataMethods.upscale(vertex.position.x, g.ss), ClippingDataMethods.upscale(vertex.position.y, g.ss));
                    g.scanlineData.status = ScanlineStatus.LineTo;
                } else {
                    if (command == Command.EndPoly) closePolygon(g);
                }
            }
        }
    }

    function closePolygon(Graphics2D memory g) internal pure {
        if (g.scanlineData.status != ScanlineStatus.LineTo) {
            return;
        }
        Clipping.lineToClip(g, g.scanlineData.startX, g.scanlineData.startY);
        g.scanlineData.status = ScanlineStatus.Closed;
    }

    function reset(ScanlineData memory scanlineData, CellData memory cellData)
        private
        pure
    {
        CellRasterizer.resetCells(cellData);
        scanlineData.status = ScanlineStatus.Initial;
    }
}

contract TestGraphics2DMethods {
    function blendPixel(
        uint8[] memory buffer,
        int32 bufferOffset,
        uint32 sourceColor,
        PixelClipping memory clipping
    ) external pure returns (uint8[] memory) {
        Graphics2DMethods.blendPixel(buffer, bufferOffset, sourceColor, clipping);
        return buffer;
    }

    function copyPixels(
        uint8[] memory buffer,
        int32 bufferOffset,
        uint32 sourceColor,
        int32 count,
        PixelClipping memory clipping
    ) external pure returns (uint8[] memory) {
        Graphics2DMethods.copyPixels(buffer, bufferOffset, sourceColor, count, clipping);
        return buffer;
    }

    function createBufferOnly(uint32 width, uint32 height)
        external
        pure
        returns (Graphics2D memory g)
    {
        g.buffer = new uint8[](width * 4 * height);
    }

    function targetColorTest(int32 alpha, uint32 sourceColor) external pure returns (uint32 targetColor) {
        targetColor = ColorMath.toColor(uint8(uint32(alpha)), 
        uint8(sourceColor >> 16), 
        uint8(sourceColor >> 8), 
        uint8(sourceColor >> 0));
    }
}