/* SPDX-License-Identifier: UNLICENSED */
pragma solidity ^0.6.12;

library LiqiMathLib {
    /**
     * @notice Usado pela função mulDiv
     */
    function fullMul(uint256 x, uint256 y)
        internal
        pure
        returns (uint256 l, uint256 h)
    {
        uint256 xl = uint128(x);
        uint256 xh = x >> 128;
        uint256 yl = uint128(y);
        uint256 yh = y >> 128;
        uint256 xlyl = xl * yl;
        uint256 xlyh = xl * yh;
        uint256 xhyl = xh * yl;
        uint256 xhyh = xh * yh;

        uint256 ll = uint128(xlyl);
        uint256 lh = (xlyl >> 128) + uint128(xlyh) + uint128(xhyl);
        uint256 hl = uint128(xhyh) + (xlyh >> 128) + (xhyl >> 128);
        uint256 hh = (xhyh >> 128);
        l = ll + (lh << 128);
        h = (lh >> 128) + hl + (hh << 128);
    }

    /**
     * @notice Calcula x * y / z, de forma que não estoure o limite
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 z
    ) internal pure returns (uint256) {
        (uint256 l, uint256 h) = fullMul(x, y);
        require(h < z);
        uint256 mm = mulmod(x, y, z);
        if (mm > l) h -= 1;
        l -= mm;
        uint256 pow2 = z & -z;
        z /= pow2;
        l /= pow2;
        l += h * ((-pow2) / pow2 + 1);
        uint256 r = 1;
        r *= 2 - z * r;
        r *= 2 - z * r;
        r *= 2 - z * r;
        r *= 2 - z * r;
        r *= 2 - z * r;
        r *= 2 - z * r;
        r *= 2 - z * r;
        r *= 2 - z * r;
        return l * r;
    }
}