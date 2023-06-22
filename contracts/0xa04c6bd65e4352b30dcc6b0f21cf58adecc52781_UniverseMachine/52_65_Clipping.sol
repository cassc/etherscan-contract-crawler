// SPDX-License-Identifier: UNLICENSED
/* Copyright (c) 2021 Kohi Art Community, Inc. All rights reserved. */

pragma solidity ^0.8.13;

import "./Fix64V1.sol";
import "./RectangleInt.sol";
import "./SubpixelScale.sol";
import "./ClippingData.sol";
import "./CellData.sol";
import "./CellRasterizer.sol";
import "./Graphics2D.sol";

library Clipping {
    function noClippingBox(ClippingData memory clippingData) internal pure {
        clippingData.clipPoly = new Vector2[](0);
    }

    function setClippingBox(
        ClippingData memory clippingData,
        int32 left,
        int32 top,
        int32 right,
        int32 bottom,
        Matrix memory transform,
        int32 height
    ) internal pure {
        Vector2 memory tl = MatrixMethods.transform(
            transform,
            Vector2(left * Fix64V1.ONE, top * Fix64V1.ONE)
        );
        Vector2 memory tr = MatrixMethods.transform(
            transform,
            Vector2(right * Fix64V1.ONE, top * Fix64V1.ONE)
        );
        Vector2 memory br = MatrixMethods.transform(
            transform,
            Vector2(right * Fix64V1.ONE, bottom * Fix64V1.ONE)
        );
        Vector2 memory bl = MatrixMethods.transform(
            transform,
            Vector2(left * Fix64V1.ONE, bottom * Fix64V1.ONE)
        );

        clippingData.clipTransform = transform;
        clippingData.clipPoly = new Vector2[](4);
        clippingData.clipPoly[0] = Vector2(
            tl.x,
            Fix64V1.sub(height * Fix64V1.ONE, tl.y)
        );
        clippingData.clipPoly[1] = Vector2(
            tr.x,
            Fix64V1.sub(height * Fix64V1.ONE, tr.y)
        );
        clippingData.clipPoly[2] = Vector2(
            br.x,
            Fix64V1.sub(height * Fix64V1.ONE, br.y)
        );
        clippingData.clipPoly[3] = Vector2(
            bl.x,
            Fix64V1.sub(height * Fix64V1.ONE, bl.y)
        );
    }

    function moveToClip(
        int32 x1,
        int32 y1,
        ClippingData memory clippingData
    ) internal pure {
        clippingData.x1 = x1;
        clippingData.y1 = y1;
        if (clippingData.clipping) {
            clippingData.f1 = clippingFlags(x1, y1, clippingData.clipBox);        
        }
    }

    function lineToClip(
        Graphics2D memory g,
        int32 x2,
        int32 y2
    ) internal pure {
        if (g.clippingData.clipping) {
            int32 f2 = clippingFlags(x2, y2, g.clippingData.clipBox);

            if (
                (g.clippingData.f1 & 10) == (f2 & 10) &&
                (g.clippingData.f1 & 10) != 0
            ) {
                g.clippingData.x1 = x2;
                g.clippingData.y1 = y2;
                g.clippingData.f1 = f2;
                return;
            }

            int32 x1 = g.clippingData.x1;
            int32 y1 = g.clippingData.y1;
            int32 f1 = g.clippingData.f1;
            int32 y3;
            int32 y4;
            int32 f3;
            int32 f4;

            if ((((f1 & 5) << 1) | (f2 & 5)) == 0) {
                lineClipY(g, LineClipY(x1, y1, x2, y2, f1, f2));
            } else if ((((f1 & 5) << 1) | (f2 & 5)) == 1) {
                y3 =
                    y1 +
                    mulDiv(
                        (g.clippingData.clipBox.right - x1) * Fix64V1.ONE,
                        (y2 - y1) * Fix64V1.ONE,
                        (x2 - x1) * Fix64V1.ONE
                    );
                f3 = clippingFlagsY(y3, g.clippingData.clipBox);
                lineClipY(
                    g,
                    LineClipY(x1, y1, g.clippingData.clipBox.right, y3, f1, f3)
                );
                lineClipY(
                    g,
                    LineClipY(
                        g.clippingData.clipBox.right,
                        y3,
                        g.clippingData.clipBox.right,
                        y2,
                        f3,
                        f2
                    )
                );
            } else if ((((f1 & 5) << 1) | (f2 & 5)) == 2) {
                y3 =
                    y1 +
                    mulDiv(
                        (g.clippingData.clipBox.right - x1) * Fix64V1.ONE,
                        (y2 - y1) * Fix64V1.ONE,
                        (x2 - x1) * Fix64V1.ONE
                    );
                f3 = clippingFlagsY(y3, g.clippingData.clipBox);
                lineClipY(
                    g,
                    LineClipY(
                        g.clippingData.clipBox.right,
                        y1,
                        g.clippingData.clipBox.right,
                        y3,
                        f1,
                        f3
                    )
                );
                lineClipY(
                    g,
                    LineClipY(g.clippingData.clipBox.right, y3, x2, y2, f3, f2)
                );
            } else if ((((f1 & 5) << 1) | (f2 & 5)) == 3) {
                lineClipY(
                    g,
                    LineClipY(
                        g.clippingData.clipBox.right,
                        y1,
                        g.clippingData.clipBox.right,
                        y2,
                        f1,
                        f2
                    )
                );
            } else if ((((f1 & 5) << 1) | (f2 & 5)) == 4) {
                y3 =
                    y1 +
                    mulDiv(
                        (g.clippingData.clipBox.left - x1) * Fix64V1.ONE,
                        (y2 - y1) * Fix64V1.ONE,
                        (x2 - x1) * Fix64V1.ONE
                    );
                f3 = clippingFlagsY(y3, g.clippingData.clipBox);
                lineClipY(
                    g,
                    LineClipY(x1, y1, g.clippingData.clipBox.left, y3, f1, f3)
                );
                lineClipY(
                    g,
                    LineClipY(
                        g.clippingData.clipBox.left,
                        y3,
                        g.clippingData.clipBox.left,
                        y2,
                        f3,
                        f2
                    )
                );
            } else if ((((f1 & 5) << 1) | (f2 & 5)) == 6) {
                y3 =
                    y1 +
                    mulDiv(
                        (g.clippingData.clipBox.right - x1) * Fix64V1.ONE,
                        (y2 - y1) * Fix64V1.ONE,
                        (x2 - x1) * Fix64V1.ONE
                    );

                y4 =
                    y1 +
                    mulDiv(
                        (g.clippingData.clipBox.left - x1) * Fix64V1.ONE,
                        (y2 - y1) * Fix64V1.ONE,
                        (x2 - x1) * Fix64V1.ONE
                    );

                f3 = clippingFlagsY(y3, g.clippingData.clipBox);
                f4 = clippingFlagsY(y4, g.clippingData.clipBox);
                lineClipY(
                    g,
                    LineClipY(
                        g.clippingData.clipBox.right,
                        y1,
                        g.clippingData.clipBox.right,
                        y3,
                        f1,
                        f3
                    )
                );
                lineClipY(
                    g,
                    LineClipY(
                        g.clippingData.clipBox.right,
                        y3,
                        g.clippingData.clipBox.left,
                        y4,
                        f3,
                        f4
                    )
                );
                lineClipY(
                    g,
                    LineClipY(
                        g.clippingData.clipBox.left,
                        y4,
                        g.clippingData.clipBox.left,
                        y2,
                        f4,
                        f2
                    )
                );
            } else if ((((f1 & 5) << 1) | (f2 & 5)) == 8) {
                y3 =
                    y1 +
                    mulDiv(
                        (g.clippingData.clipBox.left - x1) * Fix64V1.ONE,
                        (y2 - y1) * Fix64V1.ONE,
                        (x2 - x1) * Fix64V1.ONE
                    );

                f3 = clippingFlagsY(y3, g.clippingData.clipBox);
                lineClipY(
                    g,
                    LineClipY(
                        g.clippingData.clipBox.left,
                        y1,
                        g.clippingData.clipBox.left,
                        y3,
                        f1,
                        f3
                    )
                );
                lineClipY(
                    g,
                    LineClipY(g.clippingData.clipBox.left, y3, x2, y2, f3, f2)
                );
            } else if ((((f1 & 5) << 1) | (f2 & 5)) == 9) {
                y3 =
                    y1 +
                    mulDiv(
                        (g.clippingData.clipBox.left - x1) * Fix64V1.ONE,
                        (y2 - y1) * Fix64V1.ONE,
                        (x2 - x1) * Fix64V1.ONE
                    );

                y4 =
                    y1 +
                    mulDiv(
                        (g.clippingData.clipBox.right - x1) * Fix64V1.ONE,
                        (y2 - y1) * Fix64V1.ONE,
                        (x2 - x1) * Fix64V1.ONE
                    );
                f3 = clippingFlagsY(y3, g.clippingData.clipBox);
                f4 = clippingFlagsY(y4, g.clippingData.clipBox);
                lineClipY(
                    g,
                    LineClipY(
                        g.clippingData.clipBox.left,
                        y1,
                        g.clippingData.clipBox.left,
                        y3,
                        f1,
                        f3
                    )
                );
                lineClipY(
                    g,
                    LineClipY(
                        g.clippingData.clipBox.left,
                        y3,
                        g.clippingData.clipBox.right,
                        y4,
                        f3,
                        f4
                    )
                );
                lineClipY(
                    g,
                    LineClipY(
                        g.clippingData.clipBox.right,
                        y4,
                        g.clippingData.clipBox.right,
                        y2,
                        f4,
                        f2
                    )
                );
            } else if ((((f1 & 5) << 1) | (f2 & 5)) == 12) {
                lineClipY(
                    g,
                    LineClipY(
                        g.clippingData.clipBox.left,
                        y1,
                        g.clippingData.clipBox.left,
                        y2,
                        f1,
                        f2
                    )
                );
            }

            g.clippingData.f1 = f2;
        } else {
            CellRasterizer.line(
                CellRasterizer.Line(
                    g.clippingData.x1,
                    g.clippingData.y1,
                    x2,
                    y2
                ), g.cellData, g.ss);
        }

        g.clippingData.x1 = x2;
        g.clippingData.y1 = y2;
    }

    struct LineClipY {
        int32 x1;
        int32 y1;
        int32 x2;
        int32 y2;
        int32 f1;
        int32 f2;
    }

    function lineClipY(Graphics2D memory g, LineClipY memory f) private pure {
        f.f1 &= 10;
        f.f2 &= 10;
        if ((f.f1 | f.f2) == 0) {
            CellRasterizer.line(CellRasterizer.Line(f.x1, f.y1, f.x2, f.y2), g.cellData, g.ss);
        } else {
            if (f.f1 == f.f2)
                return;

            int32 tx1 = f.x1;
            int32 ty1 = f.y1;
            int32 tx2 = f.x2;
            int32 ty2 = f.y2;

            if ((f.f1 & 8) != 0)
            {
                tx1 =
                    f.x1 +
                    mulDiv(
                        (g.clippingData.clipBox.bottom - f.y1) * Fix64V1.ONE,
                        (f.x2 - f.x1) * Fix64V1.ONE,
                        (f.y2 - f.y1) * Fix64V1.ONE
                    );

                ty1 = g.clippingData.clipBox.bottom;
            }

            if ((f.f1 & 2) != 0)
            {
                tx1 =
                    f.x1 +
                    mulDiv(
                        (g.clippingData.clipBox.top - f.y1) * Fix64V1.ONE,
                        (f.x2 - f.x1) * Fix64V1.ONE,
                        (f.y2 - f.y1) * Fix64V1.ONE
                    );

                ty1 = g.clippingData.clipBox.top;
            }

            if ((f.f2 & 8) != 0)
            {
                tx2 =
                    f.x1 +
                    mulDiv(
                        (g.clippingData.clipBox.bottom - f.y1) * Fix64V1.ONE,
                        (f.x2 - f.x1) * Fix64V1.ONE,
                        (f.y2 - f.y1) * Fix64V1.ONE
                    );

                ty2 = g.clippingData.clipBox.bottom;
            }

            if ((f.f2 & 2) != 0)
            {
                tx2 =
                    f.x1 +
                    mulDiv(
                        (g.clippingData.clipBox.top - f.y1) * Fix64V1.ONE,
                        (f.x2 - f.x1) * Fix64V1.ONE,
                        (f.y2 - f.y1) * Fix64V1.ONE
                    );

                ty2 = g.clippingData.clipBox.top;
            }

            CellRasterizer.line(CellRasterizer.Line(tx1, ty1, tx2, ty2), g.cellData, g.ss);
        }
    }

    function clippingFlags(
        int32 x,
        int32 y,
        RectangleInt memory clipBox
    ) private pure returns (int32) {
        return
            (x > clipBox.right ? int32(1) : int32(0)) |
            (y > clipBox.top ? int32(1) << 1 : int32(0)) |
            (x < clipBox.left ? int32(1) << 2 : int32(0)) |
            (y < clipBox.bottom ? int32(1) << 3 : int32(0));
    }

    function clippingFlagsY(int32 y, RectangleInt memory clipBox)
        private
        pure
        returns (int32)
    {
        return
            ((y > clipBox.top ? int32(1) : int32(0)) << 1) |
            ((y < clipBox.bottom ? int32(1) : int32(0)) << 3);
    }

    function mulDiv(
        int64 a,
        int64 b,
        int64 c
    ) private pure returns (int32) {
        int64 div = Fix64V1.div(b, c);
        int64 muldiv = Fix64V1.mul(a, div);
        return (int32)(Fix64V1.round(muldiv) / Fix64V1.ONE);
    }
}