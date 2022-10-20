// SPDX-License-Identifier: MIT
pragma solidity =0.7.6;

import "SafeMath.sol";

library GammaLib {
    using SafeMath for uint256;

    uint256 internal constant DECIMAL_PRECISION = 1e18;

    /* 
    * Exponentiation function for 18-digit decimal base, and integer exponent n.
    * O(log(n)) complexity.
    */
    function decPow(uint256 _a, uint256 _n) internal pure returns (uint256) {
        if (_n == 0) {return DECIMAL_PRECISION;}

        uint256 y = DECIMAL_PRECISION;
        uint256 x = _a;
        uint256 n = _n;
        while (n > 1) {
            if (n & 1 == 0) {
                x = _decMul(x, x);
                n = n.div(2);
            } else {
                y = _decMul(x, y);
                x = _decMul(x, x);
                n = (n.sub(1)).div(2);
            }
        }
        return _decMul(x, y);
    }

    /* 
    * Multiply two decimal numbers and use normal rounding rules:
    * - round product up if 19'th mantissa digit >= 5
    * - round product down if 19'th mantissa digit < 5
    */
    function _decMul(uint256 x, uint256 y) internal pure returns (uint256 decProd) {
        uint256 prod_xy = x.mul(y);
        decProd = prod_xy.add(DECIMAL_PRECISION / 2).div(DECIMAL_PRECISION);
    }
}