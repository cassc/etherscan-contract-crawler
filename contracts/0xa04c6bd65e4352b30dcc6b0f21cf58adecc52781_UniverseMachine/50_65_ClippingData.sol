// SPDX-License-Identifier: UNLICENSED
/* Copyright (c) 2021 Kohi Art Community, Inc. All rights reserved. */

pragma solidity ^0.8.13;

import "./Matrix.sol";
import "./RectangleInt.sol";
import "./SubpixelScale.sol";

struct ClippingData {
    int32 f1;
    int32 x1;
    int32 y1;
    Matrix clipTransform;
    Vector2[] clipPoly;
    RectangleInt clipBox;
    bool clipping;
}

library ClippingDataMethods {
    function create(
        uint32 width,
        uint32 height,
        SubpixelScale memory ss
    ) internal pure returns (ClippingData memory clippingData) {
        clippingData.x1 = 0;
        clippingData.y1 = 0;
        clippingData.f1 = 0;
        clippingData.clipBox = RectangleInt(
            0,
            0,
            upscale(int64(int32(width) * Fix64V1.ONE), ss),
            upscale(int64(int32(height) * Fix64V1.ONE), ss)
        );
        RectangleIntMethods.normalize(clippingData.clipBox);
        clippingData.clipping = true;
    }

    function upscale(int64 v, SubpixelScale memory ss)
        internal
        pure
        returns (int32)
    {
        return
            int32(
                Fix64V1.round(Fix64V1.mul(v, int32(ss.scale) * Fix64V1.ONE)) /
                    Fix64V1.ONE
            );
    }
}

contract TestClippingDataMethods {
    function create(
        uint32 width,
        uint32 height,
        SubpixelScale memory ss
    ) external pure returns (ClippingData memory clippingData) {
        return ClippingDataMethods.create(width, height, ss);
    }
}