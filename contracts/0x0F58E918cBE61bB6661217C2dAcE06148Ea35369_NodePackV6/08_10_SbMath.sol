// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

library SbMath {

  uint internal constant DECIMAL_PRECISION = 1e18;

  /*
  * Multiply two decimal numbers and use normal rounding rules:
  * -round product up if 19'th mantissa digit >= 5
  * -round product down if 19'th mantissa digit < 5
  *
  * Used only inside the exponentiation, _decPow().
  */
  function decMul(uint x, uint y) internal pure returns (uint decProd) {
    uint prod_xy = x * y;

    decProd = (prod_xy + (DECIMAL_PRECISION / 2)) / DECIMAL_PRECISION;
  }

  /*
  * _decPow: Exponentiation function for 18-digit decimal base, and integer exponent n.
  *
  * Uses the efficient "exponentiation by squaring" algorithm. O(log(n)) complexity.
  *
  * The exponent is capped to avoid reverting due to overflow. The cap 525600000 equals
  * "minutes in 1000 years": 60 * 24 * 365 * 1000
  */
  function _decPow(uint _base, uint _minutes) internal pure returns (uint) {

    if (_minutes > 525_600_000) _minutes = 525_600_000;  // cap to avoid overflow

    if (_minutes == 0) return DECIMAL_PRECISION;

    uint y = DECIMAL_PRECISION;
    uint x = _base;
    uint n = _minutes;

    // Exponentiation-by-squaring
    while (n > 1) {
      if (n % 2 == 0) {
        x = decMul(x, x);
        n = n / 2;
      } else { // if (n % 2 != 0)
        y = decMul(x, y);
        x = decMul(x, x);
        n = (n - 1) / 2;
      }
    }

    return decMul(x, y);
  }

}