// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

library BoundaryMath {
    int24 public constant MIN_BOUNDARY = -527400;
    int24 public constant MAX_BOUNDARY = 443635;

    /// @dev The minimum value that can be returned from #getPriceX96AtBoundary. Equivalent to getPriceX96AtBoundary(MIN_BOUNDARY)
    uint160 internal constant MIN_RATIO = 989314;
    /// @dev The maximum value that can be returned from #getPriceX96AtBoundary. Equivalent to getPriceX96AtBoundary(MAX_BOUNDARY)
    uint160 internal constant MAX_RATIO = 1461300573427867316570072651998408279850435624081;

    /// @dev Checks if a boundary is divisible by a resolution
    /// @param boundary The boundary to check
    /// @param resolution The step size in initialized boundaries for a grid created with a given fee
    /// @return isValid Whether or not the boundary is valid
    function isValidBoundary(int24 boundary, int24 resolution) internal pure returns (bool isValid) {
        return boundary % resolution == 0;
    }

    /// @dev Checks if a boundary is within the valid range
    /// @param boundary The boundary to check
    /// @return inRange Whether or not the boundary is in range
    function isInRange(int24 boundary) internal pure returns (bool inRange) {
        return boundary >= MIN_BOUNDARY && boundary <= MAX_BOUNDARY;
    }

    /// @dev Checks if a price is within the valid range
    /// @param priceX96 The price to check, as a Q64.96
    /// @return inRange Whether or not the price is in range
    function isPriceX96InRange(uint160 priceX96) internal pure returns (bool inRange) {
        return priceX96 >= MIN_RATIO && priceX96 <= MAX_RATIO;
    }

    /// @notice Calculates the price at a given boundary
    /// @dev priceX96 = pow(1.0001, boundary) * 2**96
    /// @param boundary The boundary to calculate the price at
    /// @return priceX96 The price at the boundary, as a Q64.96
    function getPriceX96AtBoundary(int24 boundary) internal pure returns (uint160 priceX96) {
        unchecked {
            uint256 absBoundary = boundary < 0 ? uint256(-int256(boundary)) : uint24(boundary);

            uint256 ratio = absBoundary & 0x1 != 0
                ? 0xfff97272373d413259a46990580e213a
                : 0x100000000000000000000000000000000;
            if (absBoundary & 0x2 != 0) ratio = (ratio * 0xfff2e50f5f656932ef12357cf3c7fdcc) >> 128;
            if (absBoundary & 0x4 != 0) ratio = (ratio * 0xffe5caca7e10e4e61c3624eaa0941cd0) >> 128;
            if (absBoundary & 0x8 != 0) ratio = (ratio * 0xffcb9843d60f6159c9db58835c926644) >> 128;
            if (absBoundary & 0x10 != 0) ratio = (ratio * 0xff973b41fa98c081472e6896dfb254c0) >> 128;
            if (absBoundary & 0x20 != 0) ratio = (ratio * 0xff2ea16466c96a3843ec78b326b52861) >> 128;
            if (absBoundary & 0x40 != 0) ratio = (ratio * 0xfe5dee046a99a2a811c461f1969c3053) >> 128;
            if (absBoundary & 0x80 != 0) ratio = (ratio * 0xfcbe86c7900a88aedcffc83b479aa3a4) >> 128;
            if (absBoundary & 0x100 != 0) ratio = (ratio * 0xf987a7253ac413176f2b074cf7815e54) >> 128;
            if (absBoundary & 0x200 != 0) ratio = (ratio * 0xf3392b0822b70005940c7a398e4b70f3) >> 128;
            if (absBoundary & 0x400 != 0) ratio = (ratio * 0xe7159475a2c29b7443b29c7fa6e889d9) >> 128;
            if (absBoundary & 0x800 != 0) ratio = (ratio * 0xd097f3bdfd2022b8845ad8f792aa5825) >> 128;
            if (absBoundary & 0x1000 != 0) ratio = (ratio * 0xa9f746462d870fdf8a65dc1f90e061e5) >> 128;
            if (absBoundary & 0x2000 != 0) ratio = (ratio * 0x70d869a156d2a1b890bb3df62baf32f7) >> 128;
            if (absBoundary & 0x4000 != 0) ratio = (ratio * 0x31be135f97d08fd981231505542fcfa6) >> 128;
            if (absBoundary & 0x8000 != 0) ratio = (ratio * 0x9aa508b5b7a84e1c677de54f3e99bc9) >> 128;
            if (absBoundary & 0x10000 != 0) ratio = (ratio * 0x5d6af8dedb81196699c329225ee604) >> 128;
            if (absBoundary & 0x20000 != 0) ratio = (ratio * 0x2216e584f5fa1ea926041bedfe98) >> 128;
            if (absBoundary & 0x40000 != 0) ratio = (ratio * 0x48a170391f7dc42444e8fa2) >> 128;
            if (absBoundary & 0x80000 != 0) ratio = (ratio * 0x149b34ee7ac263) >> 128;

            if (boundary > 0) ratio = type(uint256).max / ratio;

            // this divides by 1<<32 and rounds up to go from a Q128.128 to a Q128.96.
            // due to out boundary input limitations, we then proceed to downcast as the
            // result will always fit within 160 bits.
            // we round up in the division so that getBoundaryAtPriceX96 of the output price is always consistent
            priceX96 = uint160((ratio + 0xffffffff) >> 32);
        }
    }

    /// @notice Calculates the boundary at a given price
    /// @param priceX96 The price to calculate the boundary at, as a Q64.96
    /// @return boundary The boundary at the price
    function getBoundaryAtPriceX96(uint160 priceX96) internal pure returns (int24 boundary) {
        unchecked {
            uint256 ratio = uint256(priceX96) << 32;

            uint256 r = ratio;
            uint256 msb = 0;

            assembly {
                let f := shl(7, gt(r, 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF))
                msb := or(msb, f)
                r := shr(f, r)
            }
            assembly {
                let f := shl(6, gt(r, 0xFFFFFFFFFFFFFFFF))
                msb := or(msb, f)
                r := shr(f, r)
            }
            assembly {
                let f := shl(5, gt(r, 0xFFFFFFFF))
                msb := or(msb, f)
                r := shr(f, r)
            }
            assembly {
                let f := shl(4, gt(r, 0xFFFF))
                msb := or(msb, f)
                r := shr(f, r)
            }
            assembly {
                let f := shl(3, gt(r, 0xFF))
                msb := or(msb, f)
                r := shr(f, r)
            }
            assembly {
                let f := shl(2, gt(r, 0xF))
                msb := or(msb, f)
                r := shr(f, r)
            }
            assembly {
                let f := shl(1, gt(r, 0x3))
                msb := or(msb, f)
                r := shr(f, r)
            }
            assembly {
                let f := gt(r, 0x1)
                msb := or(msb, f)
            }

            if (msb >= 128) r = ratio >> (msb - 127);
            else r = ratio << (127 - msb);

            int256 log_2 = (int256(msb) - 128) << 64;

            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(63, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(62, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(61, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(60, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(59, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(58, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(57, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(56, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(55, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(54, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(53, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(52, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(51, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(50, f))
            }

            int256 log10001 = log_2 * 127869479499801913173570;
            // 128.128 number

            int24 boundaryLow = int24((log10001 - 1701496478404566090792001455681771637) >> 128);
            int24 boundaryHi = int24((log10001 + 289637967442836604689790891002483458648) >> 128);

            boundary = boundaryLow == boundaryHi ? boundaryLow : getPriceX96AtBoundary(boundaryHi) <= priceX96
                ? boundaryHi
                : boundaryLow;
        }
    }

    /// @dev Returns the lower boundary for the given boundary and resolution.
    /// The lower boundary may not be valid (if out of the boundary range)
    /// @param boundary The boundary to get the lower boundary for
    /// @param resolution The step size in initialized boundaries for a grid created with a given fee
    /// @return boundaryLower The lower boundary for the given boundary and resolution
    function getBoundaryLowerAtBoundary(int24 boundary, int24 resolution) internal pure returns (int24 boundaryLower) {
        unchecked {
            return boundary - (((boundary % resolution) + resolution) % resolution);
        }
    }

    /// @dev Rewrite the lower boundary that is not in the range to a valid value
    /// @param boundaryLower The lower boundary to rewrite
    /// @param resolution The step size in initialized boundaries for a grid created with a given fee
    /// @return validBoundaryLower The valid lower boundary
    function rewriteToValidBoundaryLower(
        int24 boundaryLower,
        int24 resolution
    ) internal pure returns (int24 validBoundaryLower) {
        unchecked {
            if (boundaryLower < MIN_BOUNDARY) return boundaryLower + resolution;
            else if (boundaryLower + resolution > MAX_BOUNDARY) return boundaryLower - resolution;
            else return boundaryLower;
        }
    }
}