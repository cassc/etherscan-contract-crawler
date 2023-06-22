// SPDX-License-Identifier: UNLICENSED
/* Copyright (c) 2021 Kohi Art Community, Inc. All rights reserved. */

pragma solidity ^0.8.13;

import "./Fix64V1.sol";
import "./SinLut256.sol";

/*
    Provides trigonometric functions in Q31.Q32 format.

    exp: Adapted from Petteri Aimonen's libfixmath

    See: https://github.com/PetteriAimonen/libfixmath
         https://github.com/PetteriAimonen/libfixmath/blob/master/LICENSE

    other functions: Adapted from André Slupik's FixedMath.NET
                     https://github.com/asik/FixedMath.Net/blob/master/LICENSE.txt
         
    THIRD PARTY NOTICES:
    ====================

    libfixmath is Copyright (c) 2011-2021 Flatmush <[email protected]>,
    Petteri Aimonen <[email protected]>, & libfixmath AUTHORS

    Permission is hereby granted, free of charge, to any person obtaining a copy
    of this software and associated documentation files (the "Software"), to deal
    in the Software without restriction, including without limitation the rights
    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
    copies of the Software, and to permit persons to whom the Software is
    furnished to do so, subject to the following conditions:

    The above copyright notice and this permission notice shall be included in all
    copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
    SOFTWARE.

    Copyright 2012 André Slupik

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

        http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

    This project uses code from the log2fix library, which is under the following license:           
    The MIT License (MIT)

    Copyright (c) 2015 Dan Moulding
    
    Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), 
    to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, 
    and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
    
    The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, 
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
    IN THE SOFTWARE.
*/

library Trig256 {
    int64 private constant LARGE_PI = 7244019458077122842;
    int64 private constant LN2 = 0xB17217F7;
    int64 private constant LN_MAX = 0x157CD0E702;
    int64 private constant LN_MIN = -0x162E42FEFA;
    int64 private constant E = -0x2B7E15162;

    function sin(int64 x) internal pure returns (int64) {
        (int64 clamped, bool flipHorizontal, bool flipVertical) = clamp(x);

        int64 lutInterval = Fix64V1.div(
            ((256 - 1) * Fix64V1.ONE),
            Fix64V1.PI_OVER_2
        );
        int256 rawIndex = Fix64V1.mul_256(clamped, lutInterval);
        int64 roundedIndex = int64(Fix64V1.round(rawIndex));
        int64 indexError = Fix64V1.sub(int64(rawIndex), roundedIndex);

        roundedIndex = roundedIndex >> 32; /* FRACTIONAL_PLACES */

        int64 nearestValueIndex = flipHorizontal
            ? (256 - 1) - roundedIndex
            : roundedIndex;

        int64 nearestValue = SinLut256.sinlut(nearestValueIndex);

        int64 secondNearestValue = SinLut256.sinlut(
            flipHorizontal
                ? (256 - 1) - roundedIndex - Fix64V1.sign(indexError)
                : roundedIndex + Fix64V1.sign(indexError)
        );

        int64 delta = Fix64V1.mul(
            indexError,
            Fix64V1.abs(Fix64V1.sub(nearestValue, secondNearestValue))
        );
        int64 interpolatedValue = nearestValue +
            (flipHorizontal ? -delta : delta);
        int64 finalValue = flipVertical
            ? -interpolatedValue
            : interpolatedValue;

        return finalValue;
    }

    function cos(int64 x) internal pure returns (int64) {
        int64 xl = x;
        int64 angle;
        if (xl > 0) {
            angle = Fix64V1.add(
                xl,
                Fix64V1.sub(0 - Fix64V1.PI, Fix64V1.PI_OVER_2)
            );
        } else {
            angle = Fix64V1.add(xl, Fix64V1.PI_OVER_2);
        }
        return sin(angle);
    }

    function sqrt(int64 x) internal pure returns (int64) {
        int64 xl = x;
        if (xl < 0) revert("negative value passed to sqrt");

        uint64 num = uint64(xl);
        uint64 result = uint64(0);
        uint64 bit = uint64(1) << (64 - 2);

        while (bit > num) bit >>= 2;
        for (uint8 i = 0; i < 2; ++i) {
            while (bit != 0) {
                if (num >= result + bit) {
                    num -= result + bit;
                    result = (result >> 1) + bit;
                } else {
                    result = result >> 1;
                }

                bit >>= 2;
            }

            if (i == 0) {
                if (num > (uint64(1) << (64 / 2)) - 1) {
                    num -= result;
                    num = (num << (64 / 2)) - uint64(0x80000000);
                    result = (result << (64 / 2)) + uint64(0x80000000);
                } else {
                    num <<= 64 / 2;
                    result <<= 64 / 2;
                }

                bit = uint64(1) << (64 / 2 - 2);
            }
        }

        if (num > result) ++result;
        return int64(result);
    }

    function log2_256(int256 x) internal pure returns (int256) {
        if (x <= 0) {
            revert("negative value passed to log2_256");
        }

        // This implementation is based on Clay. S. Turner's fast binary logarithm
        // algorithm (C. S. Turner,  "A Fast Binary Logarithm Algorithm", IEEE Signal
        //     Processing Mag., pp. 124,140, Sep. 2010.)

        int256 b = 1 << 31; // FRACTIONAL_PLACES - 1
        int256 y = 0;

        int256 rawX = x;
        while (rawX < Fix64V1.ONE) {
            rawX <<= 1;
            y -= Fix64V1.ONE;
        }

        while (rawX >= Fix64V1.ONE << 1) {
            rawX >>= 1;
            y += Fix64V1.ONE;
        }

        int256 z = rawX;

        for (
            uint8 i = 0;
            i < 32; /* FRACTIONAL_PLACES */
            i++
        ) {
            z = Fix64V1.mul_256(z, z);
            if (z >= Fix64V1.ONE << 1) {
                z = z >> 1;
                y += b;
            }
            b >>= 1;
        }

        return y;
    }

    function log_256(int256 x) internal pure returns (int256) {
        return Fix64V1.mul_256(log2_256(x), LN2);
    }

    function log2(int64 x) internal pure returns (int64) {
        if (x <= 0) revert("non-positive value passed to log2");

        // This implementation is based on Clay. S. Turner's fast binary logarithm
        // algorithm (C. S. Turner,  "A Fast Binary Logarithm Algorithm", IEEE Signal
        //     Processing Mag., pp. 124,140, Sep. 2010.)

        int64 b = 1 << 31; // FRACTIONAL_PLACES - 1
        int64 y = 0;

        int64 rawX = x;
        while (rawX < Fix64V1.ONE) {
            rawX <<= 1;
            y -= Fix64V1.ONE;
        }

        while (rawX >= Fix64V1.ONE << 1) {
            rawX >>= 1;
            y += Fix64V1.ONE;
        }

        int64 z = rawX;

        for (int32 i = 0; i < Fix64V1.FRACTIONAL_PLACES; i++) {
            z = Fix64V1.mul(z, z);
            if (z >= Fix64V1.ONE << 1) {
                z = z >> 1;
                y += b;
            }

            b >>= 1;
        }

        return y;
    }

    function log(int64 x) internal pure returns (int64) {
        return Fix64V1.mul(log2(x), LN2);
    }

    function exp(int64 x) internal pure returns (int64) {
        if (x == 0) return Fix64V1.ONE;
        if (x == Fix64V1.ONE) return E;
        if (x >= LN_MAX) return Fix64V1.MAX_VALUE;
        if (x <= LN_MIN) return 0;

        /* The algorithm is based on the power series for exp(x):
         * http://en.wikipedia.org/wiki/Exponential_function#Formal_definition
         *
         * From term n, we get term n+1 by multiplying with x/n.
         * When the sum term drops to zero, we can stop summing.
         */

        // The power-series converges much faster on positive values
        // and exp(-x) = 1/exp(x).

        bool neg = (x < 0);
        if (neg) x = -x;

        int64 result = Fix64V1.add(int64(x), Fix64V1.ONE);
        int64 term = x;

        for (uint32 i = 2; i < 40; i++) {
            term = Fix64V1.mul(x, Fix64V1.div(term, int32(i) * Fix64V1.ONE));
            result = Fix64V1.add(result, int64(term));
            if (term == 0) break;
        }

        if (neg) {
            result = Fix64V1.div(Fix64V1.ONE, result);
        }

        return result;
    }

    function clamp(int64 x)
        internal
        pure
        returns (
            int64,
            bool,
            bool
        )
    {
        int64 clamped2Pi = x;
        for (uint8 i = 0; i < 29; ++i) {
            clamped2Pi %= LARGE_PI >> i;
        }
        if (x < 0) {
            clamped2Pi += Fix64V1.TWO_PI;
        }

        bool flipVertical = clamped2Pi >= Fix64V1.PI;
        int64 clampedPi = clamped2Pi;
        while (clampedPi >= Fix64V1.PI) {
            clampedPi -= Fix64V1.PI;
        }

        bool flipHorizontal = clampedPi >= Fix64V1.PI_OVER_2;

        int64 clampedPiOver2 = clampedPi;
        if (clampedPiOver2 >= Fix64V1.PI_OVER_2)
            clampedPiOver2 -= Fix64V1.PI_OVER_2;

        return (clampedPiOver2, flipHorizontal, flipVertical);
    }

    function acos(int64 x) internal pure returns (int64 result) {
        if (x < -Fix64V1.ONE || x > Fix64V1.ONE) revert("invalid range for x");
        if (x == 0) return Fix64V1.PI_OVER_2;

        int64 t1 = Fix64V1.ONE - Fix64V1.mul(x, x);
        int64 t2 = Fix64V1.div(sqrt(t1), x);

        result = atan(t2);
        return x < 0 ? result + Fix64V1.PI : result;
    }

    function atan(int64 z) internal pure returns (int64 result) {
        if (z == 0) return 0;

        bool neg = z < 0;
        if (neg) z = -z;

        int64 two = Fix64V1.TWO;
        int64 three = Fix64V1.THREE;

        bool invert = z > Fix64V1.ONE;
        if (invert) z = Fix64V1.div(Fix64V1.ONE, z);

        result = Fix64V1.ONE;
        int64 term = Fix64V1.ONE;

        int64 zSq = Fix64V1.mul(z, z);
        int64 zSq2 = Fix64V1.mul(zSq, two);
        int64 zSqPlusOne = Fix64V1.add(zSq, Fix64V1.ONE);
        int64 zSq12 = Fix64V1.mul(zSqPlusOne, two);
        int64 dividend = zSq2;
        int64 divisor = Fix64V1.mul(zSqPlusOne, three);

        for (uint8 i = 2; i < 30; ++i) {
            term = Fix64V1.mul(term, Fix64V1.div(dividend, divisor));
            result = Fix64V1.add(result, term);

            dividend = Fix64V1.add(dividend, zSq2);
            divisor = Fix64V1.add(divisor, zSq12);

            if (term == 0) break;
        }

        result = Fix64V1.mul(result, Fix64V1.div(z, zSqPlusOne));

        if (invert) {
            result = Fix64V1.sub(Fix64V1.PI_OVER_2, result);
        }

        if (neg) {
            result = -result;
        }

        return result;
    }

    function atan2(int64 y, int64 x) internal pure returns (int64 result) {
        int64 e = 1202590848; /* 0.28 */
        int64 yl = y;
        int64 xl = x;

        if (xl == 0) {
            if (yl > 0) {
                return Fix64V1.PI_OVER_2;
            }
            if (yl == 0) {
                return 0;
            }
            return -Fix64V1.PI_OVER_2;
        }

        int64 z = Fix64V1.div(y, x);

        if (
            Fix64V1.add(Fix64V1.ONE, Fix64V1.mul(e, Fix64V1.mul(z, z))) ==
            type(int64).max
        ) {
            return y < 0 ? -Fix64V1.PI_OVER_2 : Fix64V1.PI_OVER_2;
        }

        if (Fix64V1.abs(z) < Fix64V1.ONE) {
            result = Fix64V1.div(
                z,
                Fix64V1.add(Fix64V1.ONE, Fix64V1.mul(e, Fix64V1.mul(z, z)))
            );
            if (xl < 0) {
                if (yl < 0) {
                    return Fix64V1.sub(result, Fix64V1.PI);
                }

                return Fix64V1.add(result, Fix64V1.PI);
            }
        } else {
            result = Fix64V1.sub(
                Fix64V1.PI_OVER_2,
                Fix64V1.div(z, Fix64V1.add(Fix64V1.mul(z, z), e))
            );

            if (yl < 0) {
                return Fix64V1.sub(result, Fix64V1.PI);
            }
        }
    }
}