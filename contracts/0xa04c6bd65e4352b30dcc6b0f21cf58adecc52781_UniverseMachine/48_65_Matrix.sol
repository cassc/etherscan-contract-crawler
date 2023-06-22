// SPDX-License-Identifier: UNLICENSED
/* Copyright (c) 2021 Kohi Art Community, Inc. All rights reserved. */

pragma solidity ^0.8.13;

import "./Fix64V1.sol";
import "./Trig256.sol";
import "./MathUtils.sol";
import "./Vector2.sol";

struct Matrix {
    int64 sx;
    int64 shy;
    int64 shx;
    int64 sy;
    int64 tx;
    int64 ty;
}

library MatrixMethods {
    function newIdentity() internal pure returns (Matrix memory value) {
        value.sx = Fix64V1.ONE;
        value.shy = 0;
        value.shx = 0;
        value.sy = Fix64V1.ONE;
        value.tx = 0;
        value.ty = 0;
    }

    function newRotation(int64 radians) internal pure returns (Matrix memory) {
        int64 v0 = Trig256.cos(radians);
        int64 v1 = Trig256.sin(radians);
        int64 v2 = -Trig256.sin(radians);
        int64 v3 = Trig256.cos(radians);

        return Matrix(v0, v1, v2, v3, 0, 0);
    }

    function newScale(int64 scale) internal pure returns (Matrix memory) {
        return Matrix(scale, 0, 0, scale, 0, 0);
    }

    function newScale(int64 scaleX, int64 scaleY)
        internal
        pure
        returns (Matrix memory)
    {
        return Matrix(scaleX, 0, 0, scaleY, 0, 0);
    }

    function newTranslation(int64 x, int64 y)
        internal
        pure
        returns (Matrix memory)
    {
        return Matrix(Fix64V1.ONE, 0, 0, Fix64V1.ONE, x, y);
    }

    function transform(
        Matrix memory self,
        int64 x,
        int64 y
    ) internal pure returns (int64, int64) {
        int64 tmp = x;
        x = Fix64V1.add(
            Fix64V1.mul(tmp, self.sx),
            Fix64V1.add(Fix64V1.mul(y, self.shx), self.tx)
        );
        y = Fix64V1.add(
            Fix64V1.mul(tmp, self.shy),
            Fix64V1.add(Fix64V1.mul(y, self.sy), self.ty)
        );
        return (x, y);
    }

    function transform(Matrix memory self, Vector2 memory v)
        internal
        pure
        returns (Vector2 memory result)
    {
        result = v;
        transform(self, result.x, result.y);
        return result;
    }

    function invert(Matrix memory self) internal pure {
        int64 d = Fix64V1.div(
            Fix64V1.ONE,
            Fix64V1.sub(
                Fix64V1.mul(self.sx, self.sy),
                Fix64V1.mul(self.shy, self.shx)
            )
        );

        self.sy = Fix64V1.mul(self.sx, d);
        self.shy = Fix64V1.mul(-self.shy, d);
        self.shx = Fix64V1.mul(-self.shx, d);

        self.ty = Fix64V1.sub(
            Fix64V1.mul(-self.tx, self.shy),
            Fix64V1.mul(self.ty, self.sy)
        );
        self.sx = Fix64V1.mul(self.sy, d);
        self.tx = Fix64V1.sub(
            Fix64V1.mul(-self.tx, Fix64V1.mul(self.sy, d)),
            Fix64V1.mul(self.ty, self.shx)
        );
    }

    function isIdentity(Matrix memory self) internal pure returns (bool) {
        return
            isEqual(self.sx, Fix64V1.ONE, MathUtils.Epsilon) &&
            isEqual(self.shy, 0, MathUtils.Epsilon) &&
            isEqual(self.shx, 0, MathUtils.Epsilon) &&
            isEqual(self.sy, Fix64V1.ONE, MathUtils.Epsilon) &&
            isEqual(self.tx, 0, MathUtils.Epsilon) &&
            isEqual(self.ty, 0, MathUtils.Epsilon);
    }

    function isEqual(
        int64 v1,
        int64 v2,
        int64 epsilon
    ) internal pure returns (bool) {
        return Fix64V1.abs(Fix64V1.sub(v1, v2)) <= epsilon;
    }

    function mul(Matrix memory self, Matrix memory other)
        internal
        pure
        returns (Matrix memory)
    {
        int64 t0 = Fix64V1.add(
            Fix64V1.mul(self.sx, other.sx),
            Fix64V1.mul(self.shy, other.shx)
        );
        int64 t1 = Fix64V1.add(
            Fix64V1.mul(self.shx, other.sx),
            Fix64V1.mul(self.sy, other.shx)
        );
        int64 t2 = Fix64V1.add(
            Fix64V1.mul(self.tx, other.sx),
            Fix64V1.add(Fix64V1.mul(self.ty, other.shx), other.tx)
        );
        int64 t3 = Fix64V1.add(
            Fix64V1.mul(self.sx, other.shy),
            Fix64V1.mul(self.shy, other.sy)
        );
        int64 t4 = Fix64V1.add(
            Fix64V1.mul(self.shx, other.shy),
            Fix64V1.mul(self.sy, other.sy)
        );
        int64 t5 = Fix64V1.add(
            Fix64V1.mul(self.tx, other.shy),
            Fix64V1.add(Fix64V1.mul(self.ty, other.sy), other.ty)
        );

        self.shy = t3;
        self.sy = t4;
        self.ty = t5;
        self.sx = t0;
        self.shx = t1;
        self.tx = t2;

        return self;
    }
}

contract TestMatrixMethods {
    function mul(Matrix memory self, Matrix memory other)
        external
        pure
        returns (Matrix memory)
    {
        return MatrixMethods.mul(self, other);
    }
}