// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;
import {PRBMath} from "prb-math/contracts/PRBMath.sol";
import {PRBMathUD60x18} from "prb-math/contracts/PRBMathUD60x18.sol";

library Math {
    using PRBMathUD60x18 for uint256;
    uint256 constant MAX_BIT = 0x8000000000000000000000000000000000000000000000000000000000000000;
    uint256 constant DEFAULT_SCALE = 1;

    function max(uint256 x, uint256 y) internal pure returns (uint256) {
        return x > y ? x : y;
    }

    function min(uint256 x, uint256 y) internal pure returns (uint256) {
        return x < y ? x : y;
    }

    function mulDiv(uint256 x, uint256 y, uint256 k, bool ceil) internal pure returns (uint256 result) {
        result = PRBMath.mulDiv(x, y, k);
        if (ceil && mulmod(x, y, k) != 0) result = result + 1;
    }

    function clip(uint256 x, uint256 y) internal pure returns (uint256) {
        return x < y ? 0 : x - y;
    }

    function toScale(uint256 amount, uint256 scaleFactor, bool ceil) internal pure returns (uint256) {
        if (scaleFactor == DEFAULT_SCALE || amount == 0) {
            return amount;
        } else if ((scaleFactor & MAX_BIT) != 0) {
            return amount * (scaleFactor & ~MAX_BIT);
        } else {
            return (ceil && mulmod(amount, 1, scaleFactor) != 0) ? amount / scaleFactor + 1 : amount / scaleFactor;
        }
    }

    function fromScale(uint256 amount, uint256 scaleFactor) internal pure returns (uint256) {
        if (scaleFactor == DEFAULT_SCALE) {
            return amount;
        } else if ((scaleFactor & MAX_BIT) != 0) {
            return amount / (scaleFactor & ~MAX_BIT);
        } else {
            return amount * scaleFactor;
        }
    }

    function tickSqrtPrice(uint256 tickSpacing, int32 _tick) internal pure returns (uint256 _result) {
        unchecked {
            uint256 tick = _tick < 0 ? uint256(-int256(_tick)) : uint256(int256(_tick));
            tick *= tickSpacing;
            uint256 ratio = tick & 0x1 != 0 ? 0xfffcb933bd6fad9d3af5f0b9f25db4d6 : 0x100000000000000000000000000000000;
            if (tick & 0x2 != 0) ratio = (ratio * 0xfff97272373d41fd789c8cb37ffcaa1c) >> 128;
            if (tick & 0x4 != 0) ratio = (ratio * 0xfff2e50f5f656ac9229c67059486f389) >> 128;
            if (tick & 0x8 != 0) ratio = (ratio * 0xffe5caca7e10e81259b3cddc7a064941) >> 128;
            if (tick & 0x10 != 0) ratio = (ratio * 0xffcb9843d60f67b19e8887e0bd251eb7) >> 128;
            if (tick & 0x20 != 0) ratio = (ratio * 0xff973b41fa98cd2e57b660be99eb2c4a) >> 128;
            if (tick & 0x40 != 0) ratio = (ratio * 0xff2ea16466c9838804e327cb417cafcb) >> 128;
            if (tick & 0x80 != 0) ratio = (ratio * 0xfe5dee046a99d51e2cc356c2f617dbe0) >> 128;
            if (tick & 0x100 != 0) ratio = (ratio * 0xfcbe86c7900aecf64236ab31f1f9dcb5) >> 128;
            if (tick & 0x200 != 0) ratio = (ratio * 0xf987a7253ac4d9194200696907cf2e37) >> 128;
            if (tick & 0x400 != 0) ratio = (ratio * 0xf3392b0822b88206f8abe8a3b44dd9be) >> 128;
            if (tick & 0x800 != 0) ratio = (ratio * 0xe7159475a2c578ef4f1d17b2b235d480) >> 128;
            if (tick & 0x1000 != 0) ratio = (ratio * 0xd097f3bdfd254ee83bdd3f248e7e785e) >> 128;
            if (tick & 0x2000 != 0) ratio = (ratio * 0xa9f746462d8f7dd10e744d913d033333) >> 128;
            if (tick & 0x4000 != 0) ratio = (ratio * 0x70d869a156ddd32a39e257bc3f50aa9b) >> 128;
            if (tick & 0x8000 != 0) ratio = (ratio * 0x31be135f97da6e09a19dc367e3b6da40) >> 128;
            if (tick & 0x10000 != 0) ratio = (ratio * 0x9aa508b5b7e5a9780b0cc4e25d61a56) >> 128;
            if (tick & 0x20000 != 0) ratio = (ratio * 0x5d6af8dedbcb3a6ccb7ce618d14225) >> 128;
            if (tick & 0x40000 != 0) ratio = (ratio * 0x2216e584f630389b2052b8db590e) >> 128;
            if (_tick > 0) ratio = type(uint256).max / ratio;
            _result = (ratio * PRBMathUD60x18.SCALE) >> 128;
        }
    }

    function getTickL(uint256 _reserveA, uint256 _reserveB, uint256 _sqrtLowerTickPrice, uint256 _sqrtUpperTickPrice) internal pure returns (uint256) {
        uint256 precisionBump = 0;
        if ((_reserveA >> 60) == 0 && (_reserveB >> 60) == 0) {
            precisionBump = 40;
            _reserveA <<= precisionBump;
            _reserveB <<= precisionBump;
        }
        if (_reserveA == 0 || _reserveB == 0) {
            uint256 b = (_reserveA.div(_sqrtUpperTickPrice) + _reserveB.mul(_sqrtLowerTickPrice));
            return mulDiv(b, _sqrtUpperTickPrice, _sqrtUpperTickPrice - _sqrtLowerTickPrice, false) >> precisionBump;
        } else {
            uint256 b = (_reserveA.div(_sqrtUpperTickPrice) + _reserveB.mul(_sqrtLowerTickPrice)) >> 1;
            uint256 diff = _sqrtUpperTickPrice - _sqrtLowerTickPrice;
            return mulDiv(b + (b.mul(b) + mulDiv(_reserveB.mul(_reserveA), diff, _sqrtUpperTickPrice, false)).sqrt(), _sqrtUpperTickPrice, diff, false) >> precisionBump;
        }
    }

    function getTickSqrtPriceAndL(uint256 _reserveA, uint256 _reserveB, uint256 _sqrtLowerTickPrice, uint256 _sqrtUpperTickPrice) internal pure returns (uint256 sqrtPrice, uint256 liquidity) {
        liquidity = getTickL(_reserveA, _reserveB, _sqrtLowerTickPrice, _sqrtUpperTickPrice);
        if (_reserveA == 0) {
            return (_sqrtLowerTickPrice, liquidity);
        }
        if (_reserveB == 0) {
            return (_sqrtUpperTickPrice, liquidity);
        }
        sqrtPrice = ((_reserveA + liquidity.mul(_sqrtLowerTickPrice)).div(_reserveB + liquidity.div(_sqrtUpperTickPrice))).sqrt();
        sqrtPrice = min(max(sqrtPrice, _sqrtLowerTickPrice), _sqrtUpperTickPrice);
    }
}