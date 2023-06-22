// SPDX-License-Identifier: UNLICENSED
/* Copyright (c) 2021 Kohi Art Community, Inc. All rights reserved. */

pragma solidity ^0.8.13;

import "./Fix64V1.sol";
import "./Trig256.sol";

library MathUtils {
    int32 public constant RecursionLimit = 32;
    int64 public constant AngleTolerance = 42949672; /* 0.01 */
    int64 public constant Epsilon = 4; /* 0.000000001 */

    function calcSquareDistance(
        int64 x1,
        int64 y1,
        int64 x2,
        int64 y2
    ) internal pure returns (int64) {
        int64 dx = Fix64V1.sub(x2, x1);
        int64 dy = Fix64V1.sub(y2, y1);
        return Fix64V1.add(Fix64V1.mul(dx, dx), Fix64V1.mul(dy, dy));
    }

    function calcDistance(
        int64 x1,
        int64 y1,
        int64 x2,
        int64 y2
    ) internal pure returns (int64) {
        int64 dx = Fix64V1.sub(x2, x1);
        int64 dy = Fix64V1.sub(y2, y1);
        int64 distance = Trig256.sqrt(
            Fix64V1.add(Fix64V1.mul(dx, dx), Fix64V1.mul(dy, dy))
        );
        return distance;
    }

    function crossProduct(
        int64 x1,
        int64 y1,
        int64 x2,
        int64 y2,
        int64 x,
        int64 y
    ) internal pure returns (int64) {
        return
            Fix64V1.sub(
                Fix64V1.mul(Fix64V1.sub(x, x2), Fix64V1.sub(y2, y1)),
                Fix64V1.mul(Fix64V1.sub(y, y2), Fix64V1.sub(x2, x1))
            );
    }

    struct CalcIntersection {
        int64 aX1;
        int64 aY1;
        int64 aX2;
        int64 aY2;
        int64 bX1;
        int64 bY1;
        int64 bX2;
        int64 bY2;
    }

    function calcIntersection(CalcIntersection memory f)
        internal
        pure
        returns (
            int64 x,
            int64 y,
            bool
        )
    {
        int64 num = Fix64V1.mul(
            Fix64V1.sub(f.aY1, f.bY1),
            Fix64V1.sub(f.bX2, f.bX1)
        ) - Fix64V1.mul(Fix64V1.sub(f.aX1, f.bX1), Fix64V1.sub(f.bY2, f.bY1));
        int64 den = Fix64V1.mul(
            Fix64V1.sub(f.aX2, f.aX1),
            Fix64V1.sub(f.bY2, f.bY1)
        ) - Fix64V1.mul(Fix64V1.sub(f.aY2, f.aY1), Fix64V1.sub(f.bX2, f.bX1));

        if (Fix64V1.abs(den) < Epsilon) {
            x = 0;
            y = 0;
            return (x, y, false);
        }

        int64 r = Fix64V1.div(num, den);
        x = Fix64V1.add(f.aX1, Fix64V1.mul(r, Fix64V1.sub(f.aX2, f.aX1)));
        y = Fix64V1.add(f.aY1, Fix64V1.mul(r, Fix64V1.sub(f.aY2, f.aY1)));
        return (x, y, true);
    }
}