// SPDX-License-Identifier: UNLICENSED
/* Copyright (c) 2021 Kohi Art Community, Inc. All rights reserved. */

pragma solidity ^0.8.13;

import "./Fix64V1.sol";

library ColorMath {
    function toColor(
        uint8 a,
        uint8 r,
        uint8 g,
        uint8 b
    ) internal pure returns (uint32) {
        uint32 c;
        c |= uint32(a) << 24;
        c |= uint32(r) << 16;
        c |= uint32(g) << 8;
        c |= uint32(b) << 0;
        return c & 0xffffffff;
    }

    function lerp(
        uint32 s,
        uint32 t,
        int64 k
    ) internal pure returns (uint32) {
        int64 bk = Fix64V1.sub(Fix64V1.ONE, k);

        int64 a = Fix64V1.add(
            Fix64V1.mul(int64(uint64((uint8)(s >> 24))) * Fix64V1.ONE, bk),
            Fix64V1.mul(int64(uint64((uint8)(t >> 24))) * Fix64V1.ONE, k)
        );
        int64 r = Fix64V1.add(
            Fix64V1.mul(int64(uint64((uint8)(s >> 16))) * Fix64V1.ONE, bk),
            Fix64V1.mul(int64(uint64((uint8)(t >> 16))) * Fix64V1.ONE, k)
        );
        int64 g = Fix64V1.add(
            Fix64V1.mul(int64(uint64((uint8)(s >> 8))) * Fix64V1.ONE, bk),
            Fix64V1.mul(int64(uint64((uint8)(t >> 8))) * Fix64V1.ONE, k)
        );
        int64 b = Fix64V1.add(
            Fix64V1.mul(int64(uint64((uint8)(s >> 0))) * Fix64V1.ONE, bk),
            Fix64V1.mul(int64(uint64((uint8)(t >> 0))) * Fix64V1.ONE, k)
        );

        int32 ra = (int32(a / Fix64V1.ONE) << 24);
        int32 rr = (int32(r / Fix64V1.ONE) << 16);
        int32 rg = (int32(g / Fix64V1.ONE) << 8);
        int32 rb = (int32(b / Fix64V1.ONE));

        int32 x = ra | rr | rg | rb;
        return uint32(x) & 0xffffffff;
    }

    function tint(uint32 targetColor, uint32 tintColor)
        internal
        pure
        returns (uint32 newColor)
    {
        uint8 a = (uint8)(targetColor >> 24);
        uint8 r = (uint8)(targetColor >> 16);
        uint8 g = (uint8)(targetColor >> 8);
        uint8 b = (uint8)(targetColor >> 0);

        if (a != 0 && r == 0 && g == 0 && b == 0) {
            return targetColor;
        }

        uint8 tr = (uint8)(tintColor >> 16);
        uint8 tg = (uint8)(tintColor >> 8);
        uint8 tb = (uint8)(tintColor >> 0);

        uint32 tinted = toColor(a, tr, tg, tb);
        return tinted;
    }
}

contract TestColorMath {
    function toColor(
        uint8 a,
        uint8 r,
        uint8 g,
        uint8 b
    ) external pure returns (uint32) {
        return ColorMath.toColor(a, r, g, b);
    }

    function lerp(
        uint32 s,
        uint32 t,
        int64 k
    ) external pure returns (uint32) {
        return ColorMath.lerp(s, t, k);
    }

    function tint(uint32 targetColor, uint32 tintColor)
        external
        pure
        returns (uint32 newColor)
    {
        return ColorMath.tint(targetColor, tintColor);
    }
}