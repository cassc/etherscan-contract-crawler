/**
 *Submitted for verification at Etherscan.io on 2023-10-09
*/

// SPDX-License-Identifier: BUSL-1.1
// File: abdk-libraries-solidity/ABDKMathQuad.sol


/*
 * ABDK Math Quad Smart Contract Library.  Copyright © 2019 by ABDK Consulting.
 * Author: Mikhail Vladimirov <[email protected]>
 */
pragma solidity ^0.8.0;

/**
 * Smart contract library of mathematical functions operating with IEEE 754
 * quadruple-precision binary floating-point numbers (quadruple precision
 * numbers).  As long as quadruple precision numbers are 16-bytes long, they are
 * represented by bytes16 type.
 */
library ABDKMathQuad {
  /*
   * 0.
   */
  bytes16 private constant POSITIVE_ZERO = 0x00000000000000000000000000000000;

  /*
   * -0.
   */
  bytes16 private constant NEGATIVE_ZERO = 0x80000000000000000000000000000000;

  /*
   * +Infinity.
   */
  bytes16 private constant POSITIVE_INFINITY = 0x7FFF0000000000000000000000000000;

  /*
   * -Infinity.
   */
  bytes16 private constant NEGATIVE_INFINITY = 0xFFFF0000000000000000000000000000;

  /*
   * Canonical NaN value.
   */
  bytes16 private constant NaN = 0x7FFF8000000000000000000000000000;

  /**
   * Convert signed 256-bit integer number into quadruple precision number.
   *
   * @param x signed 256-bit integer number
   * @return quadruple precision number
   */
  function fromInt (int256 x) internal pure returns (bytes16) {
    unchecked {
      if (x == 0) return bytes16 (0);
      else {
        // We rely on overflow behavior here
        uint256 result = uint256 (x > 0 ? x : -x);

        uint256 msb = mostSignificantBit (result);
        if (msb < 112) result <<= 112 - msb;
        else if (msb > 112) result >>= msb - 112;

        result = result & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF | 16383 + msb << 112;
        if (x < 0) result |= 0x80000000000000000000000000000000;

        return bytes16 (uint128 (result));
      }
    }
  }

  /**
   * Convert quadruple precision number into signed 256-bit integer number
   * rounding towards zero.  Revert on overflow.
   *
   * @param x quadruple precision number
   * @return signed 256-bit integer number
   */
  function toInt (bytes16 x) internal pure returns (int256) {
    unchecked {
      uint256 exponent = uint128 (x) >> 112 & 0x7FFF;

      require (exponent <= 16638); // Overflow
      if (exponent < 16383) return 0; // Underflow

      uint256 result = uint256 (uint128 (x)) & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF |
        0x10000000000000000000000000000;

      if (exponent < 16495) result >>= 16495 - exponent;
      else if (exponent > 16495) result <<= exponent - 16495;

      if (uint128 (x) >= 0x80000000000000000000000000000000) { // Negative
        require (result <= 0x8000000000000000000000000000000000000000000000000000000000000000);
        return -int256 (result); // We rely on overflow behavior here
      } else {
        require (result <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
        return int256 (result);
      }
    }
  }

  /**
   * Convert unsigned 256-bit integer number into quadruple precision number.
   *
   * @param x unsigned 256-bit integer number
   * @return quadruple precision number
   */
  function fromUInt (uint256 x) internal pure returns (bytes16) {
    unchecked {
      if (x == 0) return bytes16 (0);
      else {
        uint256 result = x;

        uint256 msb = mostSignificantBit (result);
        if (msb < 112) result <<= 112 - msb;
        else if (msb > 112) result >>= msb - 112;

        result = result & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF | 16383 + msb << 112;

        return bytes16 (uint128 (result));
      }
    }
  }

  /**
   * Convert quadruple precision number into unsigned 256-bit integer number
   * rounding towards zero.  Revert on underflow.  Note, that negative floating
   * point numbers in range (-1.0 .. 0.0) may be converted to unsigned integer
   * without error, because they are rounded to zero.
   *
   * @param x quadruple precision number
   * @return unsigned 256-bit integer number
   */
  function toUInt (bytes16 x) internal pure returns (uint256) {
    unchecked {
      uint256 exponent = uint128 (x) >> 112 & 0x7FFF;

      if (exponent < 16383) return 0; // Underflow

      require (uint128 (x) < 0x80000000000000000000000000000000); // Negative

      require (exponent <= 16638); // Overflow
      uint256 result = uint256 (uint128 (x)) & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF |
        0x10000000000000000000000000000;

      if (exponent < 16495) result >>= 16495 - exponent;
      else if (exponent > 16495) result <<= exponent - 16495;

      return result;
    }
  }

  /**
   * Convert signed 128.128 bit fixed point number into quadruple precision
   * number.
   *
   * @param x signed 128.128 bit fixed point number
   * @return quadruple precision number
   */
  function from128x128 (int256 x) internal pure returns (bytes16) {
    unchecked {
      if (x == 0) return bytes16 (0);
      else {
        // We rely on overflow behavior here
        uint256 result = uint256 (x > 0 ? x : -x);

        uint256 msb = mostSignificantBit (result);
        if (msb < 112) result <<= 112 - msb;
        else if (msb > 112) result >>= msb - 112;

        result = result & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF | 16255 + msb << 112;
        if (x < 0) result |= 0x80000000000000000000000000000000;

        return bytes16 (uint128 (result));
      }
    }
  }

  /**
   * Convert quadruple precision number into signed 128.128 bit fixed point
   * number.  Revert on overflow.
   *
   * @param x quadruple precision number
   * @return signed 128.128 bit fixed point number
   */
  function to128x128 (bytes16 x) internal pure returns (int256) {
    unchecked {
      uint256 exponent = uint128 (x) >> 112 & 0x7FFF;

      require (exponent <= 16510); // Overflow
      if (exponent < 16255) return 0; // Underflow

      uint256 result = uint256 (uint128 (x)) & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF |
        0x10000000000000000000000000000;

      if (exponent < 16367) result >>= 16367 - exponent;
      else if (exponent > 16367) result <<= exponent - 16367;

      if (uint128 (x) >= 0x80000000000000000000000000000000) { // Negative
        require (result <= 0x8000000000000000000000000000000000000000000000000000000000000000);
        return -int256 (result); // We rely on overflow behavior here
      } else {
        require (result <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
        return int256 (result);
      }
    }
  }

  /**
   * Convert signed 64.64 bit fixed point number into quadruple precision
   * number.
   *
   * @param x signed 64.64 bit fixed point number
   * @return quadruple precision number
   */
  function from64x64 (int128 x) internal pure returns (bytes16) {
    unchecked {
      if (x == 0) return bytes16 (0);
      else {
        // We rely on overflow behavior here
        uint256 result = uint128 (x > 0 ? x : -x);

        uint256 msb = mostSignificantBit (result);
        if (msb < 112) result <<= 112 - msb;
        else if (msb > 112) result >>= msb - 112;

        result = result & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF | 16319 + msb << 112;
        if (x < 0) result |= 0x80000000000000000000000000000000;

        return bytes16 (uint128 (result));
      }
    }
  }

  /**
   * Convert quadruple precision number into signed 64.64 bit fixed point
   * number.  Revert on overflow.
   *
   * @param x quadruple precision number
   * @return signed 64.64 bit fixed point number
   */
  function to64x64 (bytes16 x) internal pure returns (int128) {
    unchecked {
      uint256 exponent = uint128 (x) >> 112 & 0x7FFF;

      require (exponent <= 16446); // Overflow
      if (exponent < 16319) return 0; // Underflow

      uint256 result = uint256 (uint128 (x)) & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF |
        0x10000000000000000000000000000;

      if (exponent < 16431) result >>= 16431 - exponent;
      else if (exponent > 16431) result <<= exponent - 16431;

      if (uint128 (x) >= 0x80000000000000000000000000000000) { // Negative
        require (result <= 0x80000000000000000000000000000000);
        return -int128 (int256 (result)); // We rely on overflow behavior here
      } else {
        require (result <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
        return int128 (int256 (result));
      }
    }
  }

  /**
   * Convert octuple precision number into quadruple precision number.
   *
   * @param x octuple precision number
   * @return quadruple precision number
   */
  function fromOctuple (bytes32 x) internal pure returns (bytes16) {
    unchecked {
      bool negative = x & 0x8000000000000000000000000000000000000000000000000000000000000000 > 0;

      uint256 exponent = uint256 (x) >> 236 & 0x7FFFF;
      uint256 significand = uint256 (x) & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

      if (exponent == 0x7FFFF) {
        if (significand > 0) return NaN;
        else return negative ? NEGATIVE_INFINITY : POSITIVE_INFINITY;
      }

      if (exponent > 278526)
        return negative ? NEGATIVE_INFINITY : POSITIVE_INFINITY;
      else if (exponent < 245649)
        return negative ? NEGATIVE_ZERO : POSITIVE_ZERO;
      else if (exponent < 245761) {
        significand = (significand | 0x100000000000000000000000000000000000000000000000000000000000) >> 245885 - exponent;
        exponent = 0;
      } else {
        significand >>= 124;
        exponent -= 245760;
      }

      uint128 result = uint128 (significand | exponent << 112);
      if (negative) result |= 0x80000000000000000000000000000000;

      return bytes16 (result);
    }
  }

  /**
   * Convert quadruple precision number into octuple precision number.
   *
   * @param x quadruple precision number
   * @return octuple precision number
   */
  function toOctuple (bytes16 x) internal pure returns (bytes32) {
    unchecked {
      uint256 exponent = uint128 (x) >> 112 & 0x7FFF;

      uint256 result = uint128 (x) & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

      if (exponent == 0x7FFF) exponent = 0x7FFFF; // Infinity or NaN
      else if (exponent == 0) {
        if (result > 0) {
          uint256 msb = mostSignificantBit (result);
          result = result << 236 - msb & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
          exponent = 245649 + msb;
        }
      } else {
        result <<= 124;
        exponent += 245760;
      }

      result |= exponent << 236;
      if (uint128 (x) >= 0x80000000000000000000000000000000)
        result |= 0x8000000000000000000000000000000000000000000000000000000000000000;

      return bytes32 (result);
    }
  }

  /**
   * Convert double precision number into quadruple precision number.
   *
   * @param x double precision number
   * @return quadruple precision number
   */
  function fromDouble (bytes8 x) internal pure returns (bytes16) {
    unchecked {
      uint256 exponent = uint64 (x) >> 52 & 0x7FF;

      uint256 result = uint64 (x) & 0xFFFFFFFFFFFFF;

      if (exponent == 0x7FF) exponent = 0x7FFF; // Infinity or NaN
      else if (exponent == 0) {
        if (result > 0) {
          uint256 msb = mostSignificantBit (result);
          result = result << 112 - msb & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
          exponent = 15309 + msb;
        }
      } else {
        result <<= 60;
        exponent += 15360;
      }

      result |= exponent << 112;
      if (x & 0x8000000000000000 > 0)
        result |= 0x80000000000000000000000000000000;

      return bytes16 (uint128 (result));
    }
  }

  /**
   * Convert quadruple precision number into double precision number.
   *
   * @param x quadruple precision number
   * @return double precision number
   */
  function toDouble (bytes16 x) internal pure returns (bytes8) {
    unchecked {
      bool negative = uint128 (x) >= 0x80000000000000000000000000000000;

      uint256 exponent = uint128 (x) >> 112 & 0x7FFF;
      uint256 significand = uint128 (x) & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

      if (exponent == 0x7FFF) {
        if (significand > 0) return 0x7FF8000000000000; // NaN
        else return negative ?
            bytes8 (0xFFF0000000000000) : // -Infinity
            bytes8 (0x7FF0000000000000); // Infinity
      }

      if (exponent > 17406)
        return negative ?
            bytes8 (0xFFF0000000000000) : // -Infinity
            bytes8 (0x7FF0000000000000); // Infinity
      else if (exponent < 15309)
        return negative ?
            bytes8 (0x8000000000000000) : // -0
            bytes8 (0x0000000000000000); // 0
      else if (exponent < 15361) {
        significand = (significand | 0x10000000000000000000000000000) >> 15421 - exponent;
        exponent = 0;
      } else {
        significand >>= 60;
        exponent -= 15360;
      }

      uint64 result = uint64 (significand | exponent << 52);
      if (negative) result |= 0x8000000000000000;

      return bytes8 (result);
    }
  }

  /**
   * Test whether given quadruple precision number is NaN.
   *
   * @param x quadruple precision number
   * @return true if x is NaN, false otherwise
   */
  function isNaN (bytes16 x) internal pure returns (bool) {
    unchecked {
      return uint128 (x) & 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF >
        0x7FFF0000000000000000000000000000;
    }
  }

  /**
   * Test whether given quadruple precision number is positive or negative
   * infinity.
   *
   * @param x quadruple precision number
   * @return true if x is positive or negative infinity, false otherwise
   */
  function isInfinity (bytes16 x) internal pure returns (bool) {
    unchecked {
      return uint128 (x) & 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF ==
        0x7FFF0000000000000000000000000000;
    }
  }

  /**
   * Calculate sign of x, i.e. -1 if x is negative, 0 if x if zero, and 1 if x
   * is positive.  Note that sign (-0) is zero.  Revert if x is NaN. 
   *
   * @param x quadruple precision number
   * @return sign of x
   */
  function sign (bytes16 x) internal pure returns (int8) {
    unchecked {
      uint128 absoluteX = uint128 (x) & 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

      require (absoluteX <= 0x7FFF0000000000000000000000000000); // Not NaN

      if (absoluteX == 0) return 0;
      else if (uint128 (x) >= 0x80000000000000000000000000000000) return -1;
      else return 1;
    }
  }

  /**
   * Calculate sign (x - y).  Revert if either argument is NaN, or both
   * arguments are infinities of the same sign. 
   *
   * @param x quadruple precision number
   * @param y quadruple precision number
   * @return sign (x - y)
   */
  function cmp (bytes16 x, bytes16 y) internal pure returns (int8) {
    unchecked {
      uint128 absoluteX = uint128 (x) & 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

      require (absoluteX <= 0x7FFF0000000000000000000000000000); // Not NaN

      uint128 absoluteY = uint128 (y) & 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

      require (absoluteY <= 0x7FFF0000000000000000000000000000); // Not NaN

      // Not infinities of the same sign
      require (x != y || absoluteX < 0x7FFF0000000000000000000000000000);

      if (x == y) return 0;
      else {
        bool negativeX = uint128 (x) >= 0x80000000000000000000000000000000;
        bool negativeY = uint128 (y) >= 0x80000000000000000000000000000000;

        if (negativeX) {
          if (negativeY) return absoluteX > absoluteY ? -1 : int8 (1);
          else return -1; 
        } else {
          if (negativeY) return 1;
          else return absoluteX > absoluteY ? int8 (1) : -1;
        }
      }
    }
  }

  /**
   * Test whether x equals y.  NaN, infinity, and -infinity are not equal to
   * anything. 
   *
   * @param x quadruple precision number
   * @param y quadruple precision number
   * @return true if x equals to y, false otherwise
   */
  function eq (bytes16 x, bytes16 y) internal pure returns (bool) {
    unchecked {
      if (x == y) {
        return uint128 (x) & 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF <
          0x7FFF0000000000000000000000000000;
      } else return false;
    }
  }

  /**
   * Calculate x + y.  Special values behave in the following way:
   *
   * NaN + x = NaN for any x.
   * Infinity + x = Infinity for any finite x.
   * -Infinity + x = -Infinity for any finite x.
   * Infinity + Infinity = Infinity.
   * -Infinity + -Infinity = -Infinity.
   * Infinity + -Infinity = -Infinity + Infinity = NaN.
   *
   * @param x quadruple precision number
   * @param y quadruple precision number
   * @return quadruple precision number
   */
  function add (bytes16 x, bytes16 y) internal pure returns (bytes16) {
    unchecked {
      uint256 xExponent = uint128 (x) >> 112 & 0x7FFF;
      uint256 yExponent = uint128 (y) >> 112 & 0x7FFF;

      if (xExponent == 0x7FFF) {
        if (yExponent == 0x7FFF) { 
          if (x == y) return x;
          else return NaN;
        } else return x; 
      } else if (yExponent == 0x7FFF) return y;
      else {
        bool xSign = uint128 (x) >= 0x80000000000000000000000000000000;
        uint256 xSignifier = uint128 (x) & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
        if (xExponent == 0) xExponent = 1;
        else xSignifier |= 0x10000000000000000000000000000;

        bool ySign = uint128 (y) >= 0x80000000000000000000000000000000;
        uint256 ySignifier = uint128 (y) & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
        if (yExponent == 0) yExponent = 1;
        else ySignifier |= 0x10000000000000000000000000000;

        if (xSignifier == 0) return y == NEGATIVE_ZERO ? POSITIVE_ZERO : y;
        else if (ySignifier == 0) return x == NEGATIVE_ZERO ? POSITIVE_ZERO : x;
        else {
          int256 delta = int256 (xExponent) - int256 (yExponent);
  
          if (xSign == ySign) {
            if (delta > 112) return x;
            else if (delta > 0) ySignifier >>= uint256 (delta);
            else if (delta < -112) return y;
            else if (delta < 0) {
              xSignifier >>= uint256 (-delta);
              xExponent = yExponent;
            }
  
            xSignifier += ySignifier;
  
            if (xSignifier >= 0x20000000000000000000000000000) {
              xSignifier >>= 1;
              xExponent += 1;
            }
  
            if (xExponent == 0x7FFF)
              return xSign ? NEGATIVE_INFINITY : POSITIVE_INFINITY;
            else {
              if (xSignifier < 0x10000000000000000000000000000) xExponent = 0;
              else xSignifier &= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
  
              return bytes16 (uint128 (
                  (xSign ? 0x80000000000000000000000000000000 : 0) |
                  (xExponent << 112) |
                  xSignifier)); 
            }
          } else {
            if (delta > 0) {
              xSignifier <<= 1;
              xExponent -= 1;
            } else if (delta < 0) {
              ySignifier <<= 1;
              xExponent = yExponent - 1;
            }

            if (delta > 112) ySignifier = 1;
            else if (delta > 1) ySignifier = (ySignifier - 1 >> uint256 (delta - 1)) + 1;
            else if (delta < -112) xSignifier = 1;
            else if (delta < -1) xSignifier = (xSignifier - 1 >> uint256 (-delta - 1)) + 1;

            if (xSignifier >= ySignifier) xSignifier -= ySignifier;
            else {
              xSignifier = ySignifier - xSignifier;
              xSign = ySign;
            }

            if (xSignifier == 0)
              return POSITIVE_ZERO;

            uint256 msb = mostSignificantBit (xSignifier);

            if (msb == 113) {
              xSignifier = xSignifier >> 1 & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
              xExponent += 1;
            } else if (msb < 112) {
              uint256 shift = 112 - msb;
              if (xExponent > shift) {
                xSignifier = xSignifier << shift & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
                xExponent -= shift;
              } else {
                xSignifier <<= xExponent - 1;
                xExponent = 0;
              }
            } else xSignifier &= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

            if (xExponent == 0x7FFF)
              return xSign ? NEGATIVE_INFINITY : POSITIVE_INFINITY;
            else return bytes16 (uint128 (
                (xSign ? 0x80000000000000000000000000000000 : 0) |
                (xExponent << 112) |
                xSignifier));
          }
        }
      }
    }
  }

  /**
   * Calculate x - y.  Special values behave in the following way:
   *
   * NaN - x = NaN for any x.
   * Infinity - x = Infinity for any finite x.
   * -Infinity - x = -Infinity for any finite x.
   * Infinity - -Infinity = Infinity.
   * -Infinity - Infinity = -Infinity.
   * Infinity - Infinity = -Infinity - -Infinity = NaN.
   *
   * @param x quadruple precision number
   * @param y quadruple precision number
   * @return quadruple precision number
   */
  function sub (bytes16 x, bytes16 y) internal pure returns (bytes16) {
    unchecked {
      return add (x, y ^ 0x80000000000000000000000000000000);
    }
  }

  /**
   * Calculate x * y.  Special values behave in the following way:
   *
   * NaN * x = NaN for any x.
   * Infinity * x = Infinity for any finite positive x.
   * Infinity * x = -Infinity for any finite negative x.
   * -Infinity * x = -Infinity for any finite positive x.
   * -Infinity * x = Infinity for any finite negative x.
   * Infinity * 0 = NaN.
   * -Infinity * 0 = NaN.
   * Infinity * Infinity = Infinity.
   * Infinity * -Infinity = -Infinity.
   * -Infinity * Infinity = -Infinity.
   * -Infinity * -Infinity = Infinity.
   *
   * @param x quadruple precision number
   * @param y quadruple precision number
   * @return quadruple precision number
   */
  function mul (bytes16 x, bytes16 y) internal pure returns (bytes16) {
    unchecked {
      uint256 xExponent = uint128 (x) >> 112 & 0x7FFF;
      uint256 yExponent = uint128 (y) >> 112 & 0x7FFF;

      if (xExponent == 0x7FFF) {
        if (yExponent == 0x7FFF) {
          if (x == y) return x ^ y & 0x80000000000000000000000000000000;
          else if (x ^ y == 0x80000000000000000000000000000000) return x | y;
          else return NaN;
        } else {
          if (y & 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF == 0) return NaN;
          else return x ^ y & 0x80000000000000000000000000000000;
        }
      } else if (yExponent == 0x7FFF) {
          if (x & 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF == 0) return NaN;
          else return y ^ x & 0x80000000000000000000000000000000;
      } else {
        uint256 xSignifier = uint128 (x) & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
        if (xExponent == 0) xExponent = 1;
        else xSignifier |= 0x10000000000000000000000000000;

        uint256 ySignifier = uint128 (y) & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
        if (yExponent == 0) yExponent = 1;
        else ySignifier |= 0x10000000000000000000000000000;

        xSignifier *= ySignifier;
        if (xSignifier == 0)
          return (x ^ y) & 0x80000000000000000000000000000000 > 0 ?
              NEGATIVE_ZERO : POSITIVE_ZERO;

        xExponent += yExponent;

        uint256 msb =
          xSignifier >= 0x200000000000000000000000000000000000000000000000000000000 ? 225 :
          xSignifier >= 0x100000000000000000000000000000000000000000000000000000000 ? 224 :
          mostSignificantBit (xSignifier);

        if (xExponent + msb < 16496) { // Underflow
          xExponent = 0;
          xSignifier = 0;
        } else if (xExponent + msb < 16608) { // Subnormal
          if (xExponent < 16496)
            xSignifier >>= 16496 - xExponent;
          else if (xExponent > 16496)
            xSignifier <<= xExponent - 16496;
          xExponent = 0;
        } else if (xExponent + msb > 49373) {
          xExponent = 0x7FFF;
          xSignifier = 0;
        } else {
          if (msb > 112)
            xSignifier >>= msb - 112;
          else if (msb < 112)
            xSignifier <<= 112 - msb;

          xSignifier &= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

          xExponent = xExponent + msb - 16607;
        }

        return bytes16 (uint128 (uint128 ((x ^ y) & 0x80000000000000000000000000000000) |
            xExponent << 112 | xSignifier));
      }
    }
  }

  /**
   * Calculate x / y.  Special values behave in the following way:
   *
   * NaN / x = NaN for any x.
   * x / NaN = NaN for any x.
   * Infinity / x = Infinity for any finite non-negative x.
   * Infinity / x = -Infinity for any finite negative x including -0.
   * -Infinity / x = -Infinity for any finite non-negative x.
   * -Infinity / x = Infinity for any finite negative x including -0.
   * x / Infinity = 0 for any finite non-negative x.
   * x / -Infinity = -0 for any finite non-negative x.
   * x / Infinity = -0 for any finite non-negative x including -0.
   * x / -Infinity = 0 for any finite non-negative x including -0.
   * 
   * Infinity / Infinity = NaN.
   * Infinity / -Infinity = -NaN.
   * -Infinity / Infinity = -NaN.
   * -Infinity / -Infinity = NaN.
   *
   * Division by zero behaves in the following way:
   *
   * x / 0 = Infinity for any finite positive x.
   * x / -0 = -Infinity for any finite positive x.
   * x / 0 = -Infinity for any finite negative x.
   * x / -0 = Infinity for any finite negative x.
   * 0 / 0 = NaN.
   * 0 / -0 = NaN.
   * -0 / 0 = NaN.
   * -0 / -0 = NaN.
   *
   * @param x quadruple precision number
   * @param y quadruple precision number
   * @return quadruple precision number
   */
  function div (bytes16 x, bytes16 y) internal pure returns (bytes16) {
    unchecked {
      uint256 xExponent = uint128 (x) >> 112 & 0x7FFF;
      uint256 yExponent = uint128 (y) >> 112 & 0x7FFF;

      if (xExponent == 0x7FFF) {
        if (yExponent == 0x7FFF) return NaN;
        else return x ^ y & 0x80000000000000000000000000000000;
      } else if (yExponent == 0x7FFF) {
        if (y & 0x0000FFFFFFFFFFFFFFFFFFFFFFFFFFFF != 0) return NaN;
        else return POSITIVE_ZERO | (x ^ y) & 0x80000000000000000000000000000000;
      } else if (y & 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF == 0) {
        if (x & 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF == 0) return NaN;
        else return POSITIVE_INFINITY | (x ^ y) & 0x80000000000000000000000000000000;
      } else {
        uint256 ySignifier = uint128 (y) & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
        if (yExponent == 0) yExponent = 1;
        else ySignifier |= 0x10000000000000000000000000000;

        uint256 xSignifier = uint128 (x) & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
        if (xExponent == 0) {
          if (xSignifier != 0) {
            uint shift = 226 - mostSignificantBit (xSignifier);

            xSignifier <<= shift;

            xExponent = 1;
            yExponent += shift - 114;
          }
        }
        else {
          xSignifier = (xSignifier | 0x10000000000000000000000000000) << 114;
        }

        xSignifier = xSignifier / ySignifier;
        if (xSignifier == 0)
          return (x ^ y) & 0x80000000000000000000000000000000 > 0 ?
              NEGATIVE_ZERO : POSITIVE_ZERO;

        assert (xSignifier >= 0x1000000000000000000000000000);

        uint256 msb =
          xSignifier >= 0x80000000000000000000000000000 ? mostSignificantBit (xSignifier) :
          xSignifier >= 0x40000000000000000000000000000 ? 114 :
          xSignifier >= 0x20000000000000000000000000000 ? 113 : 112;

        if (xExponent + msb > yExponent + 16497) { // Overflow
          xExponent = 0x7FFF;
          xSignifier = 0;
        } else if (xExponent + msb + 16380  < yExponent) { // Underflow
          xExponent = 0;
          xSignifier = 0;
        } else if (xExponent + msb + 16268  < yExponent) { // Subnormal
          if (xExponent + 16380 > yExponent)
            xSignifier <<= xExponent + 16380 - yExponent;
          else if (xExponent + 16380 < yExponent)
            xSignifier >>= yExponent - xExponent - 16380;

          xExponent = 0;
        } else { // Normal
          if (msb > 112)
            xSignifier >>= msb - 112;

          xSignifier &= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

          xExponent = xExponent + msb + 16269 - yExponent;
        }

        return bytes16 (uint128 (uint128 ((x ^ y) & 0x80000000000000000000000000000000) |
            xExponent << 112 | xSignifier));
      }
    }
  }

  /**
   * Calculate -x.
   *
   * @param x quadruple precision number
   * @return quadruple precision number
   */
  function neg (bytes16 x) internal pure returns (bytes16) {
    unchecked {
      return x ^ 0x80000000000000000000000000000000;
    }
  }

  /**
   * Calculate |x|.
   *
   * @param x quadruple precision number
   * @return quadruple precision number
   */
  function abs (bytes16 x) internal pure returns (bytes16) {
    unchecked {
      return x & 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
    }
  }

  /**
   * Calculate square root of x.  Return NaN on negative x excluding -0.
   *
   * @param x quadruple precision number
   * @return quadruple precision number
   */
  function sqrt (bytes16 x) internal pure returns (bytes16) {
    unchecked {
      if (uint128 (x) >  0x80000000000000000000000000000000) return NaN;
      else {
        uint256 xExponent = uint128 (x) >> 112 & 0x7FFF;
        if (xExponent == 0x7FFF) return x;
        else {
          uint256 xSignifier = uint128 (x) & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
          if (xExponent == 0) xExponent = 1;
          else xSignifier |= 0x10000000000000000000000000000;

          if (xSignifier == 0) return POSITIVE_ZERO;

          bool oddExponent = xExponent & 0x1 == 0;
          xExponent = xExponent + 16383 >> 1;

          if (oddExponent) {
            if (xSignifier >= 0x10000000000000000000000000000)
              xSignifier <<= 113;
            else {
              uint256 msb = mostSignificantBit (xSignifier);
              uint256 shift = (226 - msb) & 0xFE;
              xSignifier <<= shift;
              xExponent -= shift - 112 >> 1;
            }
          } else {
            if (xSignifier >= 0x10000000000000000000000000000)
              xSignifier <<= 112;
            else {
              uint256 msb = mostSignificantBit (xSignifier);
              uint256 shift = (225 - msb) & 0xFE;
              xSignifier <<= shift;
              xExponent -= shift - 112 >> 1;
            }
          }

          uint256 r = 0x10000000000000000000000000000;
          r = (r + xSignifier / r) >> 1;
          r = (r + xSignifier / r) >> 1;
          r = (r + xSignifier / r) >> 1;
          r = (r + xSignifier / r) >> 1;
          r = (r + xSignifier / r) >> 1;
          r = (r + xSignifier / r) >> 1;
          r = (r + xSignifier / r) >> 1; // Seven iterations should be enough
          uint256 r1 = xSignifier / r;
          if (r1 < r) r = r1;

          return bytes16 (uint128 (xExponent << 112 | r & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF));
        }
      }
    }
  }

  /**
   * Calculate binary logarithm of x.  Return NaN on negative x excluding -0.
   *
   * @param x quadruple precision number
   * @return quadruple precision number
   */
  function log_2 (bytes16 x) internal pure returns (bytes16) {
    unchecked {
      if (uint128 (x) > 0x80000000000000000000000000000000) return NaN;
      else if (x == 0x3FFF0000000000000000000000000000) return POSITIVE_ZERO; 
      else {
        uint256 xExponent = uint128 (x) >> 112 & 0x7FFF;
        if (xExponent == 0x7FFF) return x;
        else {
          uint256 xSignifier = uint128 (x) & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
          if (xExponent == 0) xExponent = 1;
          else xSignifier |= 0x10000000000000000000000000000;

          if (xSignifier == 0) return NEGATIVE_INFINITY;

          bool resultNegative;
          uint256 resultExponent = 16495;
          uint256 resultSignifier;

          if (xExponent >= 0x3FFF) {
            resultNegative = false;
            resultSignifier = xExponent - 0x3FFF;
            xSignifier <<= 15;
          } else {
            resultNegative = true;
            if (xSignifier >= 0x10000000000000000000000000000) {
              resultSignifier = 0x3FFE - xExponent;
              xSignifier <<= 15;
            } else {
              uint256 msb = mostSignificantBit (xSignifier);
              resultSignifier = 16493 - msb;
              xSignifier <<= 127 - msb;
            }
          }

          if (xSignifier == 0x80000000000000000000000000000000) {
            if (resultNegative) resultSignifier += 1;
            uint256 shift = 112 - mostSignificantBit (resultSignifier);
            resultSignifier <<= shift;
            resultExponent -= shift;
          } else {
            uint256 bb = resultNegative ? 1 : 0;
            while (resultSignifier < 0x10000000000000000000000000000) {
              resultSignifier <<= 1;
              resultExponent -= 1;
  
              xSignifier *= xSignifier;
              uint256 b = xSignifier >> 255;
              resultSignifier += b ^ bb;
              xSignifier >>= 127 + b;
            }
          }

          return bytes16 (uint128 ((resultNegative ? 0x80000000000000000000000000000000 : 0) |
              resultExponent << 112 | resultSignifier & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF));
        }
      }
    }
  }

  /**
   * Calculate natural logarithm of x.  Return NaN on negative x excluding -0.
   *
   * @param x quadruple precision number
   * @return quadruple precision number
   */
  function ln (bytes16 x) internal pure returns (bytes16) {
    unchecked {
      return mul (log_2 (x), 0x3FFE62E42FEFA39EF35793C7673007E5);
    }
  }

  /**
   * Calculate 2^x.
   *
   * @param x quadruple precision number
   * @return quadruple precision number
   */
  function pow_2 (bytes16 x) internal pure returns (bytes16) {
    unchecked {
      bool xNegative = uint128 (x) > 0x80000000000000000000000000000000;
      uint256 xExponent = uint128 (x) >> 112 & 0x7FFF;
      uint256 xSignifier = uint128 (x) & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

      if (xExponent == 0x7FFF && xSignifier != 0) return NaN;
      else if (xExponent > 16397)
        return xNegative ? POSITIVE_ZERO : POSITIVE_INFINITY;
      else if (xExponent < 16255)
        return 0x3FFF0000000000000000000000000000;
      else {
        if (xExponent == 0) xExponent = 1;
        else xSignifier |= 0x10000000000000000000000000000;

        if (xExponent > 16367)
          xSignifier <<= xExponent - 16367;
        else if (xExponent < 16367)
          xSignifier >>= 16367 - xExponent;

        if (xNegative && xSignifier > 0x406E00000000000000000000000000000000)
          return POSITIVE_ZERO;

        if (!xNegative && xSignifier > 0x3FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
          return POSITIVE_INFINITY;

        uint256 resultExponent = xSignifier >> 128;
        xSignifier &= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
        if (xNegative && xSignifier != 0) {
          xSignifier = ~xSignifier;
          resultExponent += 1;
        }

        uint256 resultSignifier = 0x80000000000000000000000000000000;
        if (xSignifier & 0x80000000000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x16A09E667F3BCC908B2FB1366EA957D3E >> 128;
        if (xSignifier & 0x40000000000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x1306FE0A31B7152DE8D5A46305C85EDEC >> 128;
        if (xSignifier & 0x20000000000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x1172B83C7D517ADCDF7C8C50EB14A791F >> 128;
        if (xSignifier & 0x10000000000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x10B5586CF9890F6298B92B71842A98363 >> 128;
        if (xSignifier & 0x8000000000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x1059B0D31585743AE7C548EB68CA417FD >> 128;
        if (xSignifier & 0x4000000000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x102C9A3E778060EE6F7CACA4F7A29BDE8 >> 128;
        if (xSignifier & 0x2000000000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x10163DA9FB33356D84A66AE336DCDFA3F >> 128;
        if (xSignifier & 0x1000000000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x100B1AFA5ABCBED6129AB13EC11DC9543 >> 128;
        if (xSignifier & 0x800000000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x10058C86DA1C09EA1FF19D294CF2F679B >> 128;
        if (xSignifier & 0x400000000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x1002C605E2E8CEC506D21BFC89A23A00F >> 128;
        if (xSignifier & 0x200000000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x100162F3904051FA128BCA9C55C31E5DF >> 128;
        if (xSignifier & 0x100000000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x1000B175EFFDC76BA38E31671CA939725 >> 128;
        if (xSignifier & 0x80000000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x100058BA01FB9F96D6CACD4B180917C3D >> 128;
        if (xSignifier & 0x40000000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x10002C5CC37DA9491D0985C348C68E7B3 >> 128;
        if (xSignifier & 0x20000000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x1000162E525EE054754457D5995292026 >> 128;
        if (xSignifier & 0x10000000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x10000B17255775C040618BF4A4ADE83FC >> 128;
        if (xSignifier & 0x8000000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x1000058B91B5BC9AE2EED81E9B7D4CFAB >> 128;
        if (xSignifier & 0x4000000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x100002C5C89D5EC6CA4D7C8ACC017B7C9 >> 128;
        if (xSignifier & 0x2000000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x10000162E43F4F831060E02D839A9D16D >> 128;
        if (xSignifier & 0x1000000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x100000B1721BCFC99D9F890EA06911763 >> 128;
        if (xSignifier & 0x800000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x10000058B90CF1E6D97F9CA14DBCC1628 >> 128;
        if (xSignifier & 0x400000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x1000002C5C863B73F016468F6BAC5CA2B >> 128;
        if (xSignifier & 0x200000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x100000162E430E5A18F6119E3C02282A5 >> 128;
        if (xSignifier & 0x100000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x1000000B1721835514B86E6D96EFD1BFE >> 128;
        if (xSignifier & 0x80000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x100000058B90C0B48C6BE5DF846C5B2EF >> 128;
        if (xSignifier & 0x40000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x10000002C5C8601CC6B9E94213C72737A >> 128;
        if (xSignifier & 0x20000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x1000000162E42FFF037DF38AA2B219F06 >> 128;
        if (xSignifier & 0x10000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x10000000B17217FBA9C739AA5819F44F9 >> 128;
        if (xSignifier & 0x8000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x1000000058B90BFCDEE5ACD3C1CEDC823 >> 128;
        if (xSignifier & 0x4000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x100000002C5C85FE31F35A6A30DA1BE50 >> 128;
        if (xSignifier & 0x2000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x10000000162E42FF0999CE3541B9FFFCF >> 128;
        if (xSignifier & 0x1000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x100000000B17217F80F4EF5AADDA45554 >> 128;
        if (xSignifier & 0x800000000000000000000000 > 0) resultSignifier = resultSignifier * 0x10000000058B90BFBF8479BD5A81B51AD >> 128;
        if (xSignifier & 0x400000000000000000000000 > 0) resultSignifier = resultSignifier * 0x1000000002C5C85FDF84BD62AE30A74CC >> 128;
        if (xSignifier & 0x200000000000000000000000 > 0) resultSignifier = resultSignifier * 0x100000000162E42FEFB2FED257559BDAA >> 128;
        if (xSignifier & 0x100000000000000000000000 > 0) resultSignifier = resultSignifier * 0x1000000000B17217F7D5A7716BBA4A9AE >> 128;
        if (xSignifier & 0x80000000000000000000000 > 0) resultSignifier = resultSignifier * 0x100000000058B90BFBE9DDBAC5E109CCE >> 128;
        if (xSignifier & 0x40000000000000000000000 > 0) resultSignifier = resultSignifier * 0x10000000002C5C85FDF4B15DE6F17EB0D >> 128;
        if (xSignifier & 0x20000000000000000000000 > 0) resultSignifier = resultSignifier * 0x1000000000162E42FEFA494F1478FDE05 >> 128;
        if (xSignifier & 0x10000000000000000000000 > 0) resultSignifier = resultSignifier * 0x10000000000B17217F7D20CF927C8E94C >> 128;
        if (xSignifier & 0x8000000000000000000000 > 0) resultSignifier = resultSignifier * 0x1000000000058B90BFBE8F71CB4E4B33D >> 128;
        if (xSignifier & 0x4000000000000000000000 > 0) resultSignifier = resultSignifier * 0x100000000002C5C85FDF477B662B26945 >> 128;
        if (xSignifier & 0x2000000000000000000000 > 0) resultSignifier = resultSignifier * 0x10000000000162E42FEFA3AE53369388C >> 128;
        if (xSignifier & 0x1000000000000000000000 > 0) resultSignifier = resultSignifier * 0x100000000000B17217F7D1D351A389D40 >> 128;
        if (xSignifier & 0x800000000000000000000 > 0) resultSignifier = resultSignifier * 0x10000000000058B90BFBE8E8B2D3D4EDE >> 128;
        if (xSignifier & 0x400000000000000000000 > 0) resultSignifier = resultSignifier * 0x1000000000002C5C85FDF4741BEA6E77E >> 128;
        if (xSignifier & 0x200000000000000000000 > 0) resultSignifier = resultSignifier * 0x100000000000162E42FEFA39FE95583C2 >> 128;
        if (xSignifier & 0x100000000000000000000 > 0) resultSignifier = resultSignifier * 0x1000000000000B17217F7D1CFB72B45E1 >> 128;
        if (xSignifier & 0x80000000000000000000 > 0) resultSignifier = resultSignifier * 0x100000000000058B90BFBE8E7CC35C3F0 >> 128;
        if (xSignifier & 0x40000000000000000000 > 0) resultSignifier = resultSignifier * 0x10000000000002C5C85FDF473E242EA38 >> 128;
        if (xSignifier & 0x20000000000000000000 > 0) resultSignifier = resultSignifier * 0x1000000000000162E42FEFA39F02B772C >> 128;
        if (xSignifier & 0x10000000000000000000 > 0) resultSignifier = resultSignifier * 0x10000000000000B17217F7D1CF7D83C1A >> 128;
        if (xSignifier & 0x8000000000000000000 > 0) resultSignifier = resultSignifier * 0x1000000000000058B90BFBE8E7BDCBE2E >> 128;
        if (xSignifier & 0x4000000000000000000 > 0) resultSignifier = resultSignifier * 0x100000000000002C5C85FDF473DEA871F >> 128;
        if (xSignifier & 0x2000000000000000000 > 0) resultSignifier = resultSignifier * 0x10000000000000162E42FEFA39EF44D91 >> 128;
        if (xSignifier & 0x1000000000000000000 > 0) resultSignifier = resultSignifier * 0x100000000000000B17217F7D1CF79E949 >> 128;
        if (xSignifier & 0x800000000000000000 > 0) resultSignifier = resultSignifier * 0x10000000000000058B90BFBE8E7BCE544 >> 128;
        if (xSignifier & 0x400000000000000000 > 0) resultSignifier = resultSignifier * 0x1000000000000002C5C85FDF473DE6ECA >> 128;
        if (xSignifier & 0x200000000000000000 > 0) resultSignifier = resultSignifier * 0x100000000000000162E42FEFA39EF366F >> 128;
        if (xSignifier & 0x100000000000000000 > 0) resultSignifier = resultSignifier * 0x1000000000000000B17217F7D1CF79AFA >> 128;
        if (xSignifier & 0x80000000000000000 > 0) resultSignifier = resultSignifier * 0x100000000000000058B90BFBE8E7BCD6D >> 128;
        if (xSignifier & 0x40000000000000000 > 0) resultSignifier = resultSignifier * 0x10000000000000002C5C85FDF473DE6B2 >> 128;
        if (xSignifier & 0x20000000000000000 > 0) resultSignifier = resultSignifier * 0x1000000000000000162E42FEFA39EF358 >> 128;
        if (xSignifier & 0x10000000000000000 > 0) resultSignifier = resultSignifier * 0x10000000000000000B17217F7D1CF79AB >> 128;
        if (xSignifier & 0x8000000000000000 > 0) resultSignifier = resultSignifier * 0x1000000000000000058B90BFBE8E7BCD5 >> 128;
        if (xSignifier & 0x4000000000000000 > 0) resultSignifier = resultSignifier * 0x100000000000000002C5C85FDF473DE6A >> 128;
        if (xSignifier & 0x2000000000000000 > 0) resultSignifier = resultSignifier * 0x10000000000000000162E42FEFA39EF34 >> 128;
        if (xSignifier & 0x1000000000000000 > 0) resultSignifier = resultSignifier * 0x100000000000000000B17217F7D1CF799 >> 128;
        if (xSignifier & 0x800000000000000 > 0) resultSignifier = resultSignifier * 0x10000000000000000058B90BFBE8E7BCC >> 128;
        if (xSignifier & 0x400000000000000 > 0) resultSignifier = resultSignifier * 0x1000000000000000002C5C85FDF473DE5 >> 128;
        if (xSignifier & 0x200000000000000 > 0) resultSignifier = resultSignifier * 0x100000000000000000162E42FEFA39EF2 >> 128;
        if (xSignifier & 0x100000000000000 > 0) resultSignifier = resultSignifier * 0x1000000000000000000B17217F7D1CF78 >> 128;
        if (xSignifier & 0x80000000000000 > 0) resultSignifier = resultSignifier * 0x100000000000000000058B90BFBE8E7BB >> 128;
        if (xSignifier & 0x40000000000000 > 0) resultSignifier = resultSignifier * 0x10000000000000000002C5C85FDF473DD >> 128;
        if (xSignifier & 0x20000000000000 > 0) resultSignifier = resultSignifier * 0x1000000000000000000162E42FEFA39EE >> 128;
        if (xSignifier & 0x10000000000000 > 0) resultSignifier = resultSignifier * 0x10000000000000000000B17217F7D1CF6 >> 128;
        if (xSignifier & 0x8000000000000 > 0) resultSignifier = resultSignifier * 0x1000000000000000000058B90BFBE8E7A >> 128;
        if (xSignifier & 0x4000000000000 > 0) resultSignifier = resultSignifier * 0x100000000000000000002C5C85FDF473C >> 128;
        if (xSignifier & 0x2000000000000 > 0) resultSignifier = resultSignifier * 0x10000000000000000000162E42FEFA39D >> 128;
        if (xSignifier & 0x1000000000000 > 0) resultSignifier = resultSignifier * 0x100000000000000000000B17217F7D1CE >> 128;
        if (xSignifier & 0x800000000000 > 0) resultSignifier = resultSignifier * 0x10000000000000000000058B90BFBE8E6 >> 128;
        if (xSignifier & 0x400000000000 > 0) resultSignifier = resultSignifier * 0x1000000000000000000002C5C85FDF472 >> 128;
        if (xSignifier & 0x200000000000 > 0) resultSignifier = resultSignifier * 0x100000000000000000000162E42FEFA38 >> 128;
        if (xSignifier & 0x100000000000 > 0) resultSignifier = resultSignifier * 0x1000000000000000000000B17217F7D1B >> 128;
        if (xSignifier & 0x80000000000 > 0) resultSignifier = resultSignifier * 0x100000000000000000000058B90BFBE8D >> 128;
        if (xSignifier & 0x40000000000 > 0) resultSignifier = resultSignifier * 0x10000000000000000000002C5C85FDF46 >> 128;
        if (xSignifier & 0x20000000000 > 0) resultSignifier = resultSignifier * 0x1000000000000000000000162E42FEFA2 >> 128;
        if (xSignifier & 0x10000000000 > 0) resultSignifier = resultSignifier * 0x10000000000000000000000B17217F7D0 >> 128;
        if (xSignifier & 0x8000000000 > 0) resultSignifier = resultSignifier * 0x1000000000000000000000058B90BFBE7 >> 128;
        if (xSignifier & 0x4000000000 > 0) resultSignifier = resultSignifier * 0x100000000000000000000002C5C85FDF3 >> 128;
        if (xSignifier & 0x2000000000 > 0) resultSignifier = resultSignifier * 0x10000000000000000000000162E42FEF9 >> 128;
        if (xSignifier & 0x1000000000 > 0) resultSignifier = resultSignifier * 0x100000000000000000000000B17217F7C >> 128;
        if (xSignifier & 0x800000000 > 0) resultSignifier = resultSignifier * 0x10000000000000000000000058B90BFBD >> 128;
        if (xSignifier & 0x400000000 > 0) resultSignifier = resultSignifier * 0x1000000000000000000000002C5C85FDE >> 128;
        if (xSignifier & 0x200000000 > 0) resultSignifier = resultSignifier * 0x100000000000000000000000162E42FEE >> 128;
        if (xSignifier & 0x100000000 > 0) resultSignifier = resultSignifier * 0x1000000000000000000000000B17217F6 >> 128;
        if (xSignifier & 0x80000000 > 0) resultSignifier = resultSignifier * 0x100000000000000000000000058B90BFA >> 128;
        if (xSignifier & 0x40000000 > 0) resultSignifier = resultSignifier * 0x10000000000000000000000002C5C85FC >> 128;
        if (xSignifier & 0x20000000 > 0) resultSignifier = resultSignifier * 0x1000000000000000000000000162E42FD >> 128;
        if (xSignifier & 0x10000000 > 0) resultSignifier = resultSignifier * 0x10000000000000000000000000B17217E >> 128;
        if (xSignifier & 0x8000000 > 0) resultSignifier = resultSignifier * 0x1000000000000000000000000058B90BE >> 128;
        if (xSignifier & 0x4000000 > 0) resultSignifier = resultSignifier * 0x100000000000000000000000002C5C85E >> 128;
        if (xSignifier & 0x2000000 > 0) resultSignifier = resultSignifier * 0x10000000000000000000000000162E42E >> 128;
        if (xSignifier & 0x1000000 > 0) resultSignifier = resultSignifier * 0x100000000000000000000000000B17216 >> 128;
        if (xSignifier & 0x800000 > 0) resultSignifier = resultSignifier * 0x10000000000000000000000000058B90A >> 128;
        if (xSignifier & 0x400000 > 0) resultSignifier = resultSignifier * 0x1000000000000000000000000002C5C84 >> 128;
        if (xSignifier & 0x200000 > 0) resultSignifier = resultSignifier * 0x100000000000000000000000000162E41 >> 128;
        if (xSignifier & 0x100000 > 0) resultSignifier = resultSignifier * 0x1000000000000000000000000000B1720 >> 128;
        if (xSignifier & 0x80000 > 0) resultSignifier = resultSignifier * 0x100000000000000000000000000058B8F >> 128;
        if (xSignifier & 0x40000 > 0) resultSignifier = resultSignifier * 0x10000000000000000000000000002C5C7 >> 128;
        if (xSignifier & 0x20000 > 0) resultSignifier = resultSignifier * 0x1000000000000000000000000000162E3 >> 128;
        if (xSignifier & 0x10000 > 0) resultSignifier = resultSignifier * 0x10000000000000000000000000000B171 >> 128;
        if (xSignifier & 0x8000 > 0) resultSignifier = resultSignifier * 0x1000000000000000000000000000058B8 >> 128;
        if (xSignifier & 0x4000 > 0) resultSignifier = resultSignifier * 0x100000000000000000000000000002C5B >> 128;
        if (xSignifier & 0x2000 > 0) resultSignifier = resultSignifier * 0x10000000000000000000000000000162D >> 128;
        if (xSignifier & 0x1000 > 0) resultSignifier = resultSignifier * 0x100000000000000000000000000000B16 >> 128;
        if (xSignifier & 0x800 > 0) resultSignifier = resultSignifier * 0x10000000000000000000000000000058A >> 128;
        if (xSignifier & 0x400 > 0) resultSignifier = resultSignifier * 0x1000000000000000000000000000002C4 >> 128;
        if (xSignifier & 0x200 > 0) resultSignifier = resultSignifier * 0x100000000000000000000000000000161 >> 128;
        if (xSignifier & 0x100 > 0) resultSignifier = resultSignifier * 0x1000000000000000000000000000000B0 >> 128;
        if (xSignifier & 0x80 > 0) resultSignifier = resultSignifier * 0x100000000000000000000000000000057 >> 128;
        if (xSignifier & 0x40 > 0) resultSignifier = resultSignifier * 0x10000000000000000000000000000002B >> 128;
        if (xSignifier & 0x20 > 0) resultSignifier = resultSignifier * 0x100000000000000000000000000000015 >> 128;
        if (xSignifier & 0x10 > 0) resultSignifier = resultSignifier * 0x10000000000000000000000000000000A >> 128;
        if (xSignifier & 0x8 > 0) resultSignifier = resultSignifier * 0x100000000000000000000000000000004 >> 128;
        if (xSignifier & 0x4 > 0) resultSignifier = resultSignifier * 0x100000000000000000000000000000001 >> 128;

        if (!xNegative) {
          resultSignifier = resultSignifier >> 15 & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
          resultExponent += 0x3FFF;
        } else if (resultExponent <= 0x3FFE) {
          resultSignifier = resultSignifier >> 15 & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
          resultExponent = 0x3FFF - resultExponent;
        } else {
          resultSignifier = resultSignifier >> resultExponent - 16367;
          resultExponent = 0;
        }

        return bytes16 (uint128 (resultExponent << 112 | resultSignifier));
      }
    }
  }

  /**
   * Calculate e^x.
   *
   * @param x quadruple precision number
   * @return quadruple precision number
   */
  function exp (bytes16 x) internal pure returns (bytes16) {
    unchecked {
      return pow_2 (mul (x, 0x3FFF71547652B82FE1777D0FFDA0D23A));
    }
  }

  /**
   * Get index of the most significant non-zero bit in binary representation of
   * x.  Reverts if x is zero.
   *
   * @return index of the most significant non-zero bit in binary representation
   *         of x
   */
  function mostSignificantBit (uint256 x) private pure returns (uint256) {
    unchecked {
      require (x > 0);

      uint256 result = 0;

      if (x >= 0x100000000000000000000000000000000) { x >>= 128; result += 128; }
      if (x >= 0x10000000000000000) { x >>= 64; result += 64; }
      if (x >= 0x100000000) { x >>= 32; result += 32; }
      if (x >= 0x10000) { x >>= 16; result += 16; }
      if (x >= 0x100) { x >>= 8; result += 8; }
      if (x >= 0x10) { x >>= 4; result += 4; }
      if (x >= 0x4) { x >>= 2; result += 2; }
      if (x >= 0x2) result += 1; // No need to shift x anymore

      return result;
    }
  }
}

// File: contracts/libraries/math/IporMath.sol


pragma solidity 0.8.20;

library IporMath {
    uint256 private constant RAY = 1e27;

    //@notice Division with rounding up on last position, x, and y is with MD
    function division(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = (x + (y / 2)) / y;
    }

    function divisionInt(int256 x, int256 y) internal pure returns (int256 z) {
        uint256 absX = uint256(x < 0 ? -x : x);
        uint256 absY = uint256(y < 0 ? -y : y);

        // Use bitwise XOR to get the sign on MBS bit then shift to LSB
        // sign == 0x0000...0000 ==  0 if the number is non-negative
        // sign == 0xFFFF...FFFF == -1 if the number is negative
        int256 sign = (x ^ y) >> 255;

        uint256 divAbs;
        uint256 remainder;

        unchecked {
            divAbs = absX / absY;
            remainder = absX % absY;
        }
        // Check if we need to round
        if (sign < 0) {
            // remainder << 1 left shift is equivalent to multiplying by 2
            if (remainder << 1 > absY) {
                ++divAbs;
            }
        } else {
            if (remainder << 1 >= absY) {
                ++divAbs;
            }
        }

        // (sign | 1) is cheaper than (sign < 0) ? -1 : 1;
        unchecked {
            z = int256(divAbs) * (sign | 1);
        }
    }

    function divisionWithoutRound(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x / y;
    }

    function convertWadToAssetDecimals(uint256 value, uint256 assetDecimals) internal pure returns (uint256) {
        if (assetDecimals == 18) {
            return value;
        } else if (assetDecimals > 18) {
            return value * 10 ** (assetDecimals - 18);
        } else {
            return division(value, 10 ** (18 - assetDecimals));
        }
    }

    function convertWadToAssetDecimalsWithoutRound(
        uint256 value,
        uint256 assetDecimals
    ) internal pure returns (uint256) {
        if (assetDecimals == 18) {
            return value;
        } else if (assetDecimals > 18) {
            return value * 10 ** (assetDecimals - 18);
        } else {
            return divisionWithoutRound(value, 10 ** (18 - assetDecimals));
        }
    }

    function convertToWad(uint256 value, uint256 assetDecimals) internal pure returns (uint256) {
        if (value > 0) {
            if (assetDecimals == 18) {
                return value;
            } else if (assetDecimals > 18) {
                return division(value, 10 ** (assetDecimals - 18));
            } else {
                return value * 10 ** (18 - assetDecimals);
            }
        } else {
            return value;
        }
    }

    function absoluteValue(int256 value) internal pure returns (uint256) {
        return (uint256)(value < 0 ? -value : value);
    }

    function percentOf(uint256 value, uint256 rate) internal pure returns (uint256) {
        return division(value * rate, 1e18);
    }

    /// @notice Calculates x^n where x and y are represented in RAY (27 decimals)
    /// @param x base, represented in 27 decimals
    /// @param n exponent, represented in 27 decimals
    /// @return z x^n represented in 27 decimals
    function rayPow(uint256 x, uint256 n) internal pure returns (uint256 z) {
        assembly {
            switch x
            case 0 {
                switch n
                case 0 {
                    z := RAY
                }
                default {
                    z := 0
                }
            }
            default {
                switch mod(n, 2)
                case 0 {
                    z := RAY
                }
                default {
                    z := x
                }
                let half := div(RAY, 2) // for rounding.
                for {
                    n := div(n, 2)
                } n {
                    n := div(n, 2)
                } {
                    let xx := mul(x, x)
                    if iszero(eq(div(xx, x), x)) {
                        revert(0, 0)
                    }
                    let xxRound := add(xx, half)
                    if lt(xxRound, xx) {
                        revert(0, 0)
                    }
                    x := div(xxRound, RAY)
                    if mod(n, 2) {
                        let zx := mul(z, x)
                        if and(iszero(iszero(x)), iszero(eq(div(zx, x), z))) {
                            revert(0, 0)
                        }
                        let zxRound := add(zx, half)
                        if lt(zxRound, zx) {
                            revert(0, 0)
                        }
                        z := div(zxRound, RAY)
                    }
                }
            }
        }
    }
}

// File: contracts/libraries/errors/AmmErrors.sol


pragma solidity 0.8.20;

/// @title Errors which occur inside AmmTreasury's method execution.
library AmmErrors {
    // 300-399-AMM
    /// @notice Liquidity Pool balance is equal 0.
    string public constant LIQUIDITY_POOL_IS_EMPTY = "IPOR_300";

    /// @notice Liquidity Pool balance is too low, should be equal or higher than 0.
    string public constant LIQUIDITY_POOL_AMOUNT_TOO_LOW = "IPOR_301";

    /// @notice Liquidity Pool Collateral Ratio exceeded. Liquidity Pool Collateral Ratio is higher than configured in AmmTreasury maximum liquidity pool collateral ratio.
    string public constant LP_COLLATERAL_RATIO_EXCEEDED = "IPOR_302";

    /// @notice Liquidity Pool Collateral Ratio Per Leg exceeded. Liquidity Pool Collateral Ratio per leg is higher than configured in AmmTreasury maximum liquidity pool collateral ratio per leg.
    string public constant LP_COLLATERAL_RATIO_PER_LEG_EXCEEDED = "IPOR_303";

    /// @notice Liquidity Pool Balance is too high
    string public constant LIQUIDITY_POOL_BALANCE_IS_TOO_HIGH = "IPOR_304";

    /// @notice Swap cannot be closed because liquidity pool is too low for payid out cash. Situation should never happen where Liquidity Pool is insolvent.
    string public constant CANNOT_CLOSE_SWAP_LP_IS_TOO_LOW = "IPOR_305";

    /// @notice Swap id used in input has incorrect value (like 0) or not exists.
    string public constant INCORRECT_SWAP_ID = "IPOR_306";

    /// @notice Swap has incorrect status.
    string public constant INCORRECT_SWAP_STATUS = "IPOR_307";

    /// @notice Leverage given as a parameter when opening swap is lower than configured in AmmTreasury minimum leverage.
    string public constant LEVERAGE_TOO_LOW = "IPOR_308";

    /// @notice Leverage given as a parameter when opening swap is higher than configured in AmmTreasury maxumum leverage.
    string public constant LEVERAGE_TOO_HIGH = "IPOR_309";

    /// @notice Total amount given as a parameter when opening swap is too low. Cannot be equal zero.
    string public constant TOTAL_AMOUNT_TOO_LOW = "IPOR_310";

    /// @notice Total amount given as a parameter when opening swap is lower than sum of liquidation deposit amount and ipor publication fee.
    string public constant TOTAL_AMOUNT_LOWER_THAN_FEE = "IPOR_311";

    /// @notice Amount of collateral used to open swap is higher than configured in AmmTreasury max swap collateral amount
    string public constant COLLATERAL_AMOUNT_TOO_HIGH = "IPOR_312";

    /// @notice Acceptable fixed interest rate defined by traded exceeded.
    string public constant ACCEPTABLE_FIXED_INTEREST_RATE_EXCEEDED = "IPOR_313";

    /// @notice Swap Notional Amount is higher than Total Notional for specific leg.
    string public constant SWAP_NOTIONAL_HIGHER_THAN_TOTAL_NOTIONAL = "IPOR_314";

    /// @notice Number of swaps per leg which are going to be liquidated is too high, is higher than configured in AmmTreasury liquidation leg limit.
    string public constant MAX_LENGTH_LIQUIDATED_SWAPS_PER_LEG_EXCEEDED = "IPOR_315";

    /// @notice Sum of SOAP and Liquidity Pool Balance is lower than zero.
    /// @dev SOAP can be negative, Sum of SOAP and Liquidity Pool Balance can be negative, but this is undesirable.
    string public constant SOAP_AND_LP_BALANCE_SUM_IS_TOO_LOW = "IPOR_316";

    /// @notice Calculation timestamp is earlier than last SOAP rebalance timestamp.
    string public constant CALC_TIMESTAMP_LOWER_THAN_SOAP_REBALANCE_TIMESTAMP = "IPOR_317";

    /// @notice Calculation timestamp is lower than  Swap's open timestamp.
    string public constant CALC_TIMESTAMP_LOWER_THAN_SWAP_OPEN_TIMESTAMP = "IPOR_318";

    /// @notice Closing timestamp is lower than Swap's open timestamp.
    string public constant CLOSING_TIMESTAMP_LOWER_THAN_SWAP_OPEN_TIMESTAMP = "IPOR_319";

    /// @notice Swap cannot be closed because sender is not a buyer nor liquidator.
    string public constant CANNOT_CLOSE_SWAP_SENDER_IS_NOT_BUYER_NOR_LIQUIDATOR = "IPOR_320";

    /// @notice Interest from Strategy is below zero.
    string public constant INTEREST_FROM_STRATEGY_EXCEEDED_THRESHOLD = "IPOR_321";

    /// @notice IPOR publication fee balance is too low.
    string public constant PUBLICATION_FEE_BALANCE_IS_TOO_LOW = "IPOR_322";

    /// @notice The caller must be the Token Manager (Smart Contract responsible for managing token total supply).
    string public constant CALLER_NOT_TOKEN_MANAGER = "IPOR_323";

    /// @notice Deposit amount is too low.
    string public constant DEPOSIT_AMOUNT_IS_TOO_LOW = "IPOR_324";

    /// @notice Vault balance is lower than deposit value.
    string public constant VAULT_BALANCE_LOWER_THAN_DEPOSIT_VALUE = "IPOR_325";

    /// @notice Treasury balance is too low.
    string public constant TREASURY_BALANCE_IS_TOO_LOW = "IPOR_326";

    /// @notice Swap cannot be closed because closing timestamp is lower than swap's open timestamp in general.
    string public constant CANNOT_CLOSE_SWAP_CLOSING_IS_TOO_EARLY = "IPOR_327";

    /// @notice Swap cannot be closed because closing timestamp is lower than swap's open timestamp for buyer.
    string public constant CANNOT_CLOSE_SWAP_CLOSING_IS_TOO_EARLY_FOR_BUYER = "IPOR_328";

    /// @notice Swap cannot be closed and unwind because is too late
    string public constant CANNOT_UNWIND_CLOSING_TOO_LATE = "IPOR_329";

    /// @notice Unsupported swap tenor
    string public constant UNSUPPORTED_SWAP_TENOR = "IPOR_330";

    /// @notice Sender is not AMM (is not a IporProtocolRouter contract)
    string public constant SENDER_NOT_AMM = "IPOR_331";

    /// @notice Storage id is not time weighted notional group
    string public constant STORAGE_ID_IS_NOT_TIME_WEIGHTED_NOTIONAL = "IPOR_332";

    /// @notice Spread function is not supported
    string public constant FUNCTION_NOT_SUPPORTED = "IPOR_333";

    /// @notice Unsupported direction
    string public constant UNSUPPORTED_DIRECTION = "IPOR_334";

    /// @notice Invalid notional
    string public constant INVALID_NOTIONAL = "IPOR_335";

    /// @notice Average interest rate cannot be zero when open swap
    string public constant AVERAGE_INTEREST_RATE_WHEN_OPEN_SWAP_CANNOT_BE_ZERO = "IPOR_336";

    /// @notice Average interest rate cannot be zero when close swap
    string public constant AVERAGE_INTEREST_RATE_WHEN_CLOSE_SWAP_CANNOT_BE_ZERO = "IPOR_337";

    /// @notice Submit ETH to stETH contract failed.
    string public constant STETH_SUBMIT_FAILED = "IPOR_338";

    /// @notice Collateral is not sufficient to cover unwind swap
    string public constant COLLATERAL_IS_NOT_SUFFICIENT_TO_COVER_UNWIND_SWAP = "IPOR_339";

    /// @notice Error when withdraw from asset management is not enough to cover transfer amount to buyer and/or beneficiary
    string public constant ASSET_MANAGEMENT_WITHDRAW_NOT_ENOUGH = "IPOR_340";
}

// File: contracts/libraries/StorageLib.sol


pragma solidity 0.8.20;

/// @title Storage ID's associated with the IPOR Protocol Router.
library StorageLib {
    uint256 constant STORAGE_SLOT_BASE = 1_000_000;

    // append only
    enum StorageId {
        /// @dev The address of the contract owner.
        Owner,
        AppointedOwner,
        Paused,
        PauseGuardian,
        ReentrancyStatus,
        RouterFunctionPaused,
        AmmSwapsLiquidators,
        AmmPoolsAppointedToRebalance,
        AmmPoolsParams
    }

    /// @notice Struct which contains owner address of IPOR Protocol Router.
    struct OwnerStorage {
        address owner;
    }

    /// @notice Struct which contains appointed owner address of IPOR Protocol Router.
    struct AppointedOwnerStorage {
        address appointedOwner;
    }

    /// @notice Struct which contains reentrancy status of IPOR Protocol Router.
    struct ReentrancyStatusStorage {
        uint256 value;
    }

    /// @notice Struct which contains information about swap liquidators.
    /// @dev First key is an asset (pool), second key is an liquidator address in the asset pool,
    /// value is a flag to indicate whether account is a liquidator.
    /// True - account is a liquidator, False - account is not a liquidator.
    struct AmmSwapsLiquidatorsStorage {
        mapping(address => mapping(address => bool)) value;
    }

    /// @notice Struct which contains information about accounts appointed to rebalance.
    /// @dev first key - asset address, second key - account address which is allowed to rebalance in the asset pool,
    /// value - flag to indicate whether account is allowed to rebalance. True - allowed, False - not allowed.
    struct AmmPoolsAppointedToRebalanceStorage {
        mapping(address => mapping(address => bool)) value;
    }

    struct AmmPoolsParamsValue {
        /// @dev max liquidity pool balance in the asset pool, represented without 18 decimals
        uint32 maxLiquidityPoolBalance;
        /// @dev The threshold for auto-rebalancing the pool. Value represented without 18 decimals.
        /// Value represents multiplication of 1000.
        uint32 autoRebalanceThresholdInThousands;
        /// @dev asset management ratio, represented without 18 decimals, value represents percentage with 2 decimals
        /// 65% = 6500, 99,99% = 9999, this is a percentage which stay in Amm Treasury in opposite to Asset Management
        /// based on AMM Treasury balance (100%).
        uint16 ammTreasuryAndAssetManagementRatio;
    }

    /// @dev key - asset address, value - struct AmmOpenSwapParamsValue
    struct AmmPoolsParamsStorage {
        mapping(address => AmmPoolsParamsValue) value;
    }

    /// @dev key - function sig, value - 1 if function is paused, 0 if not
    struct RouterFunctionPausedStorage {
        mapping(bytes4 => uint256) value;
    }

    /// @notice Gets Ipor Protocol Router owner address.
    function getOwner() internal pure returns (OwnerStorage storage owner) {
        uint256 slot = _getStorageSlot(StorageId.Owner);
        assembly {
            owner.slot := slot
        }
    }

    /// @notice Gets Ipor Protocol Router appointed owner address.
    function getAppointedOwner() internal pure returns (AppointedOwnerStorage storage appointedOwner) {
        uint256 slot = _getStorageSlot(StorageId.AppointedOwner);
        assembly {
            appointedOwner.slot := slot
        }
    }

    /// @notice Gets Ipor Protocol Router reentrancy status.
    function getReentrancyStatus() internal pure returns (ReentrancyStatusStorage storage reentrancyStatus) {
        uint256 slot = _getStorageSlot(StorageId.ReentrancyStatus);
        assembly {
            reentrancyStatus.slot := slot
        }
    }

    /// @notice Gets information if function is paused in Ipor Protocol Router.
    function getRouterFunctionPaused() internal pure returns (RouterFunctionPausedStorage storage paused) {
        uint256 slot = _getStorageSlot(StorageId.RouterFunctionPaused);
        assembly {
            paused.slot := slot
        }
    }

    /// @notice Gets point to pause guardian storage.
    function getPauseGuardianStorage() internal pure returns (mapping(address => bool) storage store) {
        uint256 slot = _getStorageSlot(StorageId.PauseGuardian);
        assembly {
            store.slot := slot
        }
    }

    /// @notice Gets point to liquidators storage.
    /// @return store - point to liquidators storage.
    function getAmmSwapsLiquidatorsStorage() internal pure returns (AmmSwapsLiquidatorsStorage storage store) {
        uint256 slot = _getStorageSlot(StorageId.AmmSwapsLiquidators);
        assembly {
            store.slot := slot
        }
    }

    /// @notice Gets point to accounts appointed to rebalance storage.
    /// @return store - point to accounts appointed to rebalance storage.
    function getAmmPoolsAppointedToRebalanceStorage()
        internal
        pure
        returns (AmmPoolsAppointedToRebalanceStorage storage store)
    {
        uint256 slot = _getStorageSlot(StorageId.AmmPoolsAppointedToRebalance);
        assembly {
            store.slot := slot
        }
    }

    /// @notice Gets point to amm pools params storage.
    /// @return store - point to amm pools params storage.
    function getAmmPoolsParamsStorage() internal pure returns (AmmPoolsParamsStorage storage store) {
        uint256 slot = _getStorageSlot(StorageId.AmmPoolsParams);
        assembly {
            store.slot := slot
        }
    }

    function _getStorageSlot(StorageId storageId) private pure returns (uint256 slot) {
        return uint256(storageId) + STORAGE_SLOT_BASE;
    }
}

// File: contracts/security/PauseManager.sol


pragma solidity 0.8.20;


/// @title Ipor Protocol Router Pause Manager library
library PauseManager {
    /// @notice Emitted when new pause guardian is added
    /// @param guardians List of addresses of guardian
    event PauseGuardiansAdded(address[] indexed guardians);

    /// @notice Emitted when pause guardian is removed
    /// @param guardians List of addresses of guardian
    event PauseGuardiansRemoved(address[] indexed guardians);

    /// @notice Checks if account is Ipor Protocol Router pause guardian
    /// @param account Address of guardian
    /// @return true if account is Ipor Protocol Router pause guardian
    function isPauseGuardian(address account) internal view returns (bool) {
        mapping(address => bool) storage pauseGuardians = StorageLib.getPauseGuardianStorage();
        return pauseGuardians[account];
    }

    /// @notice Adds Ipor Protocol Router pause guardian
    /// @param newGuardians Addresses of guardians
    function addPauseGuardians(address[] calldata newGuardians) internal {
        uint256 length = newGuardians.length;
        if (length == 0) {
            return;
        }

        mapping(address => bool) storage pauseGuardians = StorageLib.getPauseGuardianStorage();

        for (uint256 i; i < length; ) {
            pauseGuardians[newGuardians[i]] = true;
            unchecked {
                i++;
            }
        }
        emit PauseGuardiansAdded(newGuardians);
    }

    /// @notice Removes Ipor Protocol Router pause guardian
    /// @param guardians Addresses of guardians
    function removePauseGuardians(address[] calldata guardians) internal {
        uint256 length = guardians.length;

        if (length == 0) {
            return;
        }

        mapping(address => bool) storage pauseGuardians = StorageLib.getPauseGuardianStorage();

        for (uint256 i; i < length; ) {
            pauseGuardians[guardians[i]] = false;
            unchecked {
                i++;
            }
        }
        emit PauseGuardiansRemoved(guardians);
    }
}

// File: contracts/libraries/errors/IporErrors.sol


pragma solidity 0.8.20;

library IporErrors {
    // 000-199 - general codes

    /// @notice General problem, address is wrong
    string public constant WRONG_ADDRESS = "IPOR_000";

    /// @notice General problem. Wrong decimals
    string public constant WRONG_DECIMALS = "IPOR_001";

    /// @notice General problem, addresses mismatch
    string public constant ADDRESSES_MISMATCH = "IPOR_002";

    /// @notice Sender's asset balance is too low to transfer and to open a swap
    string public constant SENDER_ASSET_BALANCE_TOO_LOW = "IPOR_003";

    /// @notice Value is not greater than zero
    string public constant VALUE_NOT_GREATER_THAN_ZERO = "IPOR_004";

    /// @notice Input arrays length mismatch
    string public constant INPUT_ARRAYS_LENGTH_MISMATCH = "IPOR_005";

    /// @notice Amount is too low to transfer
    string public constant NOT_ENOUGH_AMOUNT_TO_TRANSFER = "IPOR_006";

    /// @notice msg.sender is not an appointed owner, so cannot confirm his appointment to be an owner of a specific smart contract
    string public constant SENDER_NOT_APPOINTED_OWNER = "IPOR_007";

    /// @notice only Router can have access to function
    string public constant CALLER_NOT_IPOR_PROTOCOL_ROUTER = "IPOR_008";

    /// @notice Chunk size is equal to zero
    string public constant CHUNK_SIZE_EQUAL_ZERO = "IPOR_009";

    /// @notice Chunk size is too big
    string public constant CHUNK_SIZE_TOO_BIG = "IPOR_010";

    /// @notice Caller is not a  guardian
    string public constant CALLER_NOT_GUARDIAN = "IPOR_011";

    /// @notice Request contains invalid method signature, which is not supported by the Ipor Protocol Router
    string public constant ROUTER_INVALID_SIGNATURE = "IPOR_012";

    /// @notice Only AMM Treasury can have access to function
    string public constant CALLER_NOT_AMM_TREASURY = "IPOR_013";

    /// @notice Caller is not an owner
    string public constant CALLER_NOT_OWNER = "IPOR_014";

    /// @notice Method is paused
    string public constant METHOD_PAUSED = "IPOR_015";

    /// @notice Reentrancy appears
    string public constant REENTRANCY = "IPOR_016";

    /// @notice Asset is not supported
    string public constant ASSET_NOT_SUPPORTED = "IPOR_017";

    /// @notice Return back ETH failed in Ipor Protocol Router
    string public constant ROUTER_RETURN_BACK_ETH_FAILED = "IPOR_018";
}

// File: contracts/libraries/IporContractValidator.sol


pragma solidity 0.8.20;


library IporContractValidator {
    function checkAddress(address addr) internal pure returns (address) {
        require(addr != address(0), IporErrors.WRONG_ADDRESS);
        return addr;
    }
}

// File: contracts/libraries/PaginationUtils.sol


pragma solidity 0.8.20;

library PaginationUtils {
    function resolveResultSetSize(
        uint256 totalSwapNumber,
        uint256 offset,
        uint256 chunkSize
    ) internal pure returns (uint256) {
        uint256 resultSetSize;
        if (offset > totalSwapNumber) {
            resultSetSize = 0;
        } else if (offset + chunkSize < totalSwapNumber) {
            resultSetSize = chunkSize;
        } else {
            resultSetSize = totalSwapNumber - offset;
        }

        return resultSetSize;
    }
}

// File: contracts/libraries/Constants.sol


pragma solidity 0.8.20;

library Constants {
    uint256 public constant MAX_VALUE = type(uint256).max;
    uint256 public constant WAD_LEVERAGE_1000 = 1_000e18;
    uint256 public constant YEAR_IN_SECONDS = 365 days;
    uint256 public constant MAX_CHUNK_SIZE = 50;
}

// File: contracts/interfaces/IIporContractCommonGov.sol


pragma solidity 0.8.20;

/// @title Interface for interaction with standalone IPOR smart contract by DAO government with common methods.
interface IIporContractCommonGov {
    /// @notice Pauses current smart contract. It can be executed only by the Owner.
    /// @dev Emits {Paused} event from AssetManagement.
    function pause() external;

    /// @notice Unpauses current smart contract. It can be executed only by the Owner
    /// @dev Emits {Unpaused} event from AssetManagement.
    function unpause() external;

    /// @notice Checks if given account is a pause guardian.
    /// @param account The address of the account to be checked.
    /// @return true if account is a pause guardian.
    function isPauseGuardian(address account) external view returns (bool);

    /// @notice Adds a pause guardian to the list of guardians. Function available only for the Owner.
    /// @param guardians The list of addresses of the pause guardians to be added.
    function addPauseGuardians(address[] calldata guardians) external;

    /// @notice Removes a pause guardian from the list of guardians. Function available only for the Owner.
    /// @param guardians The list of addresses of the pause guardians to be removed.
    function removePauseGuardians(address[] calldata guardians) external;
}

// File: contracts/interfaces/IProxyImplementation.sol


pragma solidity 0.8.20;

/// @title Technical interface for reading data related to the UUPS proxy pattern in Ipor Protocol.
interface IProxyImplementation {
    /// @notice Retrieves the address of the implementation contract for UUPS proxy.
    /// @return The address of the implementation contract.
    /// @dev The function returns the value stored in the implementation storage slot.
    function getImplementation() external view returns (address);
}

// File: contracts/interfaces/types/IporTypes.sol


pragma solidity 0.8.20;

/// @title Struct used across various interfaces in IPOR Protocol.
library IporTypes {
    /// @notice enum describing Swap's state, ACTIVE - when the swap is opened, INACTIVE when it's closed
    enum SwapState {
        INACTIVE,
        ACTIVE
    }

    /// @notice enum describing Swap's duration, 28 days, 60 days or 90 days
    enum SwapTenor {
        DAYS_28,
        DAYS_60,
        DAYS_90
    }

    /// @notice The struct describing the IPOR and its params calculated for the time when it was most recently updated and the change that took place since the update.
    /// Namely, the interest that would be computed into IBT should the rebalance occur.
    struct  AccruedIpor {
        /// @notice IPOR Index Value
        /// @dev value represented in 18 decimals
        uint256 indexValue;
        /// @notice IBT Price (IBT - Interest Bearing Token). For more information refer to the documentation:
        /// https://ipor-labs.gitbook.io/ipor-labs/interest-rate-derivatives/ibt
        /// @dev value represented in 18 decimals
        uint256 ibtPrice;
    }

    /// @notice Struct representing balances used internally for asset calculations
    /// @dev all balances in 18 decimals
    struct AmmBalancesMemory {
        /// @notice Sum of all collateral put forward by the derivative buyer's on  Pay Fixed & Receive Floating leg.
        uint256 totalCollateralPayFixed;
        /// @notice Sum of all collateral put forward by the derivative buyer's on  Pay Floating & Receive Fixed leg.
        uint256 totalCollateralReceiveFixed;
        /// @notice Liquidity Pool Balance. This balance is where the liquidity from liquidity providers and the opening fee are accounted for,
        /// @dev Amount of opening fee accounted in this balance is defined by _OPENING_FEE_FOR_TREASURY_PORTION_RATE param.
        uint256 liquidityPool;
        /// @notice Vault's balance, describes how much asset has been transferred to Asset Management Vault (AssetManagement)
        uint256 vault;
    }

    struct AmmBalancesForOpenSwapMemory {
        /// @notice Sum of all collateral put forward by the derivative buyer's on  Pay Fixed & Receive Floating leg.
        uint256 totalCollateralPayFixed;
        /// @notice Total notional amount of all swaps on  Pay Fixed leg (denominated in 18 decimals).
        uint256 totalNotionalPayFixed;
        /// @notice Sum of all collateral put forward by the derivative buyer's on  Pay Floating & Receive Fixed leg.
        uint256 totalCollateralReceiveFixed;
        /// @notice Total notional amount of all swaps on  Receive Fixed leg (denominated in 18 decimals).
        uint256 totalNotionalReceiveFixed;
        /// @notice Liquidity Pool Balance.
        uint256 liquidityPool;
    }

    struct SpreadInputs {
        //// @notice Swap's assets DAI/USDC/USDT
        address asset;
        /// @notice Swap's notional value
        uint256 swapNotional;
        /// @notice demand spread factor used in demand spread calculation
        uint256 demandSpreadFactor;
        /// @notice Base spread
        int256 baseSpreadPerLeg;
        /// @notice Swap's balance for Pay Fixed leg
        uint256 totalCollateralPayFixed;
        /// @notice Swap's balance for Receive Fixed leg
        uint256 totalCollateralReceiveFixed;
        /// @notice Liquidity Pool's Balance
        uint256 liquidityPoolBalance;
        /// @notice Ipor index value at the time of swap creation
        uint256 iporIndexValue;
        // @notice fixed rate cap for given leg for offered rate without demandSpread in 18 decimals
        uint256 fixedRateCapPerLeg;
    }
}

// File: contracts/amm/libraries/types/StorageInternalTypes.sol


pragma solidity 0.8.20;


/// @notice Structs used in the AmmStorage interface
library StorageInternalTypes {
    struct Swap {
        /// @notice Swap's ID
        uint32 id;
        /// @notice Address of swap's Buyer
        address buyer;
        /// @notice Starting EPOCH timestamp of this swap.
        uint32 openTimestamp;
        /// @notice Index position of this Swap in an array of swaps' identification associated to swap's buyer
        /// @dev Field used for gas optimization purposes, it allows for quick removal by id in the array.
        /// During removal the last item in the array is switched with the one that just has been removed.
        uint32 idsIndex;
        /// @notice Swap's collateral
        /// @dev value represented in 18 decimals
        uint128 collateral;
        /// @notice Swap's notional amount
        /// @dev value represented in 18 decimals
        uint128 notional;
        /// @notice Swap's notional amount denominated in the Interest Bearing Token (IBT)
        /// @dev value represented in 18 decimals
        uint128 ibtQuantity;
        /// @notice Fixed interest rate at which the position has been opened
        /// @dev value represented in 18 decimals
        uint64 fixedInterestRate;
        /// @notice Liquidation deposit amount
        /// @dev value represented WITHOUT decimals
        uint32 liquidationDepositAmount;
        /// @notice State of the swap
        /// @dev 0 - INACTIVE, 1 - ACTIVE
        IporTypes.SwapState state;
        /// @notice Swap's tenor, it is used to calculate the swap's end date, date when swap achieved maturity.
        /// @dev 0 - 28 days, 1 - 60 days, 2 - 90 days
        IporTypes.SwapTenor tenor;
    }

    /// @notice All active swaps available in AMM with information on swaps belong to the account.
    /// It describes swaps for a given leg.
    struct SwapContainer {
        /// @notice Swap details, key in the map is a swapId
        mapping(uint32 => Swap) swaps;
        /// @notice List of swap IDs for every account, key in the list is the account's address, and the value is a list of swap IDs
        mapping(address => uint32[]) ids;
    }

    /// @notice A struct containing balances that AMM keeps track of. It acts as a AMM's accounting book.
    /// Those balances are used in various calculations across the protocol.
    /// @dev All balances are in 18 decimals
    struct Balances {
        /// @notice Sum of all collateral put forward by the derivative buyer's on  Pay Fixed & Receive Floating leg.
        uint128 totalCollateralPayFixed;
        /// @notice Sum of all collateral put forward by the derivative buyer's on  Pay Floating & Receive Fixed leg.
        uint128 totalCollateralReceiveFixed;
        /// @notice Liquidity Pool Balance. This balance is where the liquidity from liquidity providers and the opening fee are accounted for,
        /// @dev Amount of opening fee accounted in this balance is defined by _OPENING_FEE_FOR_TREASURY_PORTION_RATE param.
        uint128 liquidityPool;
        /// @notice AssetManagement's current balance. It includes interest accrued until AssetManagement's most recent state change.
        uint128 vault;
        /// @notice This balance is used to track the funds accounted for IporOracle subsidization.
        uint128 iporPublicationFee;
        /// @notice Treasury is the balance that belongs to IPOR DAO and funds up to this amount can be transferred to the DAO-appointed multi-sig wallet.
        /// this ballance is fed by part of the opening fee appointed by the DAO. For more information refer to the documentation:
        /// https://ipor-labs.gitbook.io/ipor-labs/automated-market-maker/ipor-swaps#fees
        uint128 treasury;
    }

    /// @notice A struct with parameters required to calculate SOAP for pay fixed and receive fixed legs.
    /// @dev Saved to the databse.
    struct SoapIndicatorsStorage {
        /// @notice Value of interest accrued on a fixed leg of all derivatives for this particular type of swap.
        /// @dev  Is represented in 18 decimals.
        uint256 hypotheticalInterestCumulative;
        /// @notice Sum of all swaps' notional amounts for a given leg.
        /// @dev Is represented in 18 decimals.
        uint128 totalNotional;
        /// @notice Sum of all IBTs on a given leg.
        /// @dev Is represented in 18 decimals.
        uint128 totalIbtQuantity;
        /// @notice The notional-weighted average interest rate of all swaps on a given leg combined.
        /// @dev Is represented in 18 decimals.
        uint64 averageInterestRate;
        /// @notice EPOCH timestamp of when the most recent rebalancing took place
        uint32 rebalanceTimestamp;
    }
}

// File: contracts/interfaces/types/AmmTypes.sol


pragma solidity 0.8.20;


/// @title Types used in interfaces strictly related to AMM (Automated Market Maker).
/// @dev Used by IAmmTreasury and IAmmStorage interfaces.
library AmmTypes {
    /// @notice Struct describing AMM Pool's core addresses.
    struct AmmPoolCoreModel {
        /// @notice asset address
        address asset;
        /// @notice asset decimals
        uint256 assetDecimals;
        /// @notice ipToken address associated to the asset
        address ipToken;
        /// @notice AMM Storage address
        address ammStorage;
        /// @notice AMM Treasury address
        address ammTreasury;
        /// @notice Asset Management address
        address assetManagement;
        /// @notice IPOR Oracle address
        address iporOracle;
        /// @notice IPOR Risk Management Oracle address
        address iporRiskManagementOracle;
    }

    /// @notice Structure which represents Swap's data that will be saved in the storage.
    /// Refer to the documentation https://ipor-labs.gitbook.io/ipor-labs/automated-market-maker/ipor-swaps for more information.
    struct NewSwap {
        /// @notice Account / trader who opens the Swap
        address buyer;
        /// @notice Epoch timestamp of when position was opened by the trader.
        uint256 openTimestamp;
        /// @notice Swap's collateral amount.
        /// @dev value represented in 18 decimals
        uint256 collateral;
        /// @notice Swap's notional amount.
        /// @dev value represented in 18 decimals
        uint256 notional;
        /// @notice Quantity of Interest Bearing Token (IBT) at moment when position was opened.
        /// @dev value represented in 18 decimals
        uint256 ibtQuantity;
        /// @notice Fixed interest rate at which the position has been opened.
        /// @dev value represented in 18 decimals
        uint256 fixedInterestRate;
        /// @notice Liquidation deposit is retained when the swap is opened. It is then paid back to agent who closes the derivative at maturity.
        /// It can be both trader or community member. Trader receives the deposit back when he chooses to close the derivative before maturity.
        /// @dev value represented WITHOUT 18 decimals
        uint256 liquidationDepositAmount;
        /// @notice Opening fee amount part which is allocated in Liquidity Pool Balance. This fee is calculated as a rate of the swap's collateral.
        /// @dev value represented in 18 decimals
        uint256 openingFeeLPAmount;
        /// @notice Opening fee amount part which is allocated in Treasury Balance. This fee is calculated as a rate of the swap's collateral.
        /// @dev value represented in 18 decimals
        uint256 openingFeeTreasuryAmount;
        /// @notice Swap's tenor, 0 - 28 days, 1 - 60 days or 2 - 90 days
        IporTypes.SwapTenor tenor;
    }

    /// @notice Struct representing swap item, used for listing and in internal calculations
    struct Swap {
        /// @notice Swap's unique ID
        uint256 id;
        /// @notice Swap's buyer
        address buyer;
        /// @notice Swap opening epoch timestamp
        uint256 openTimestamp;
        /// @notice Swap's tenor
        IporTypes.SwapTenor tenor;
        /// @notice Index position of this Swap in an array of swaps' identification associated to swap buyer
        /// @dev Field used for gas optimization purposes, it allows for quick removal by id in the array.
        /// During removal the last item in the array is switched with the one that just has been removed.
        uint256 idsIndex;
        /// @notice Swap's collateral
        /// @dev value represented in 18 decimals
        uint256 collateral;
        /// @notice Swap's notional amount
        /// @dev value represented in 18 decimals
        uint256 notional;
        /// @notice Swap's notional amount denominated in the Interest Bearing Token (IBT)
        /// @dev value represented in 18 decimals
        uint256 ibtQuantity;
        /// @notice Fixed interest rate at which the position has been opened
        /// @dev value represented in 18 decimals
        uint256 fixedInterestRate;
        /// @notice Liquidation deposit amount
        /// @dev value represented in 18 decimals
        uint256 liquidationDepositAmount;
        /// @notice State of the swap
        /// @dev 0 - INACTIVE, 1 - ACTIVE
        IporTypes.SwapState state;
    }

    /// @notice Struct representing amounts related to Swap that is presently being opened.
    /// @dev all values represented in 18 decimals
    struct OpenSwapAmount {
        /// @notice Total Amount of asset that is sent from buyer to AmmTreasury when opening swap.
        uint256 totalAmount;
        /// @notice Swap's collateral
        uint256 collateral;
        /// @notice Swap's notional
        uint256 notional;
        /// @notice Opening Fee - part allocated as a profit of the Liquidity Pool
        uint256 openingFeeLPAmount;
        /// @notice  Part of the fee set aside for subsidizing the oracle that publishes IPOR rate. Flat fee set by the DAO.
        /// @notice Opening Fee - part allocated in Treasury balance. Part of the fee set asside for subsidising the oracle that publishes IPOR rate. Flat fee set by the DAO.
        uint256 openingFeeTreasuryAmount;
        /// @notice Fee set aside for subsidizing the oracle that publishes IPOR rate. Flat fee set by the DAO.
        uint256 iporPublicationFee;
        /// @notice Liquidation deposit is retained when the swap is opened. Value represented in 18 decimals.
        uint256 liquidationDepositAmount;
    }

    /// @notice Structure describes one swap processed by closeSwaps method, information about swap ID and flag if this swap was closed during execution closeSwaps method.
    struct IporSwapClosingResult {
        /// @notice Swap ID
        uint256 swapId;
        /// @notice Flag describe if swap was closed during this execution
        bool closed;
    }

    /// @notice Technical structure used for storing information about amounts used during redeeming assets from liquidity pool.
    struct RedeemAmount {
        /// @notice Asset amount represented in 18 decimals
        /// @dev Asset amount is a sum of wadRedeemFee and wadRedeemAmount
        uint256 wadAssetAmount;
        /// @notice Redeemed amount represented in decimals of asset
        uint256 redeemAmount;
        /// @notice Redeem fee value represented in 18 decimals
        uint256 wadRedeemFee;
        /// @notice Redeem amount represented in 18 decimals
        uint256 wadRedeemAmount;
    }

    /// @notice Swap direction (long = Pay Fixed and Receive a Floating or short = receive fixed and pay a floating)
    enum SwapDirection {
        /// @notice When taking the "long" position the trader will pay a fixed rate and receive a floating rate.
        /// for more information refer to the documentation https://ipor-labs.gitbook.io/ipor-labs/automated-market-maker/ipor-swaps
        PAY_FIXED_RECEIVE_FLOATING,
        /// @notice When taking the "short" position the trader will pay a floating rate and receive a fixed rate.
        PAY_FLOATING_RECEIVE_FIXED
    }
    /// @notice List of closable statuses for a given swap
    /// @dev Closable status is a one of the following values:
    /// 0 - Swap is closable
    /// 1 - Swap is already closed
    /// 2 - Swap state required Buyer or Liquidator to close. Sender is not Buyer nor Liquidator.
    /// 3 - Cannot close swap, closing is too early for Community
    enum SwapClosableStatus {
        SWAP_IS_CLOSABLE,
        SWAP_ALREADY_CLOSED,
        SWAP_REQUIRED_BUYER_OR_LIQUIDATOR_TO_CLOSE,
        SWAP_CANNOT_CLOSE_CLOSING_TOO_EARLY_FOR_COMMUNITY
    }

    /// @notice Collection of swap attributes connected with IPOR Index and swap itself.
    /// @dev all values are in 18 decimals
    struct IporSwapIndicator {
        /// @notice IPOR Index value at the time of swap opening
        uint256 iporIndexValue;
        /// @notice IPOR Interest Bearing Token (IBT) price at the time of swap opening
        uint256 ibtPrice;
        /// @notice Swap's notional denominated in IBT
        uint256 ibtQuantity;
        /// @notice Fixed interest rate at which the position has been opened,
        /// it is quote from spread documentation
        uint256 fixedInterestRate;
    }

    /// @notice Risk indicators calculated for swap opening
    struct OpenSwapRiskIndicators {
        /// @notice Maximum collateral ratio in general
        uint256 maxCollateralRatio;
        /// @notice Maximum collateral ratio for a given leg
        uint256 maxCollateralRatioPerLeg;
        /// @notice Maximum leverage for a given leg
        uint256 maxLeveragePerLeg;
        /// @notice Base Spread for a given leg (without demand part)
        int256 baseSpreadPerLeg;
        /// @notice Fixed rate cap
        uint256 fixedRateCapPerLeg;
        /// @notice Demand spread factor used to calculate demand spread
        uint256 demandSpreadFactor;
    }

    /// @notice Structure containing information about swap's closing status, unwind values and PnL for a given swap and time.
    struct ClosingSwapDetails {
        /// @notice Swap's closing status
        AmmTypes.SwapClosableStatus closableStatus;
        /// @notice Flag indicating if swap unwind is required
        bool swapUnwindRequired;
        /// @notice Swap's unwind PnL Value, part of PnL corresponded to virtual swap (unwinded swap), represented in 18 decimals
        int256 swapUnwindPnlValue;
        /// @notice Unwind opening fee amount it is a sum of `swapUnwindFeeLPAmount` and `swapUnwindFeeTreasuryAmount`
        uint256 swapUnwindOpeningFeeAmount;
        /// @notice Part of unwind opening fee allocated as a profit of the Liquidity Pool
        uint256 swapUnwindFeeLPAmount;
        /// @notice Part of unwind opening fee allocated in Treasury Balance
        uint256 swapUnwindFeeTreasuryAmount;
        /// @notice Final Profit and Loss which takes into account the swap unwind and limits the PnL to the collateral amount. Represented in 18 decimals.
        int256 pnlValue;
    }
}

// File: contracts/amm/libraries/types/AmmInternalTypes.sol


pragma solidity 0.8.20;



/// @notice The types used in the AmmTreasury's interface.
/// @dev All values, where applicable, are represented in 18 decimals.
library AmmInternalTypes {
    struct PnlValueStruct    {
        /// @notice PnL Value of the swap.
        int256 pnlValue;
        /// @notice flag indicating if unwind is required when closing swap.
        bool swapUnwindRequired;
        /// @notice Unwind amount of the swap.
        int256 swapUnwindAmount;
        /// @notice Unwind fee of the swap that will be added to the AMM liquidity pool balance.
        uint256 swapUnwindFeeLPAmount;
        /// @notice Unwind fee of the swap that will be added to the AMM treasury balance.
        uint256 swapUnwindFeeTreasuryAmount;
    }

    struct BeforeOpenSwapStruct {
        /// @notice Sum of all asset transfered when opening swap. It includes the collateral, fees and desposits.
        /// @dev The amount is represented in 18 decimals regardless of the decimals of the asset.
        uint256 wadTotalAmount;
        /// @notice Swap's collateral.
        uint256 collateral;
        /// @notice Swap's notional amount.
        uint256 notional;
        /// @notice The part of the opening fee that will be added to the liquidity pool balance.
        uint256 openingFeeLPAmount;
        /// @notice Part of the opening fee that will be added to the treasury balance.
        uint256 openingFeeTreasuryAmount;
        /// @notice Amount of asset set aside for the oracle subsidization.
        uint256 iporPublicationFeeAmount;
        /// @notice Refundable deposit blocked for the entity that will close the swap.
        /// For more information on how the liquidations work refer to the documentation.
        /// https://ipor-labs.gitbook.io/ipor-labs/automated-market-maker/liquidations
        /// @dev value represented without decimals, as an integer
        uint256 liquidationDepositAmount;
        /// @notice The struct describing the IPOR and its params calculated for the time when it was most recently updated and the change that took place since the update.
        /// Namely, the interest that would be computed into IBT should the rebalance occur.
        IporTypes.AccruedIpor accruedIpor;
    }

    /// @notice Risk indicators context data
    struct RiskIndicatorsContext {
        /// @notice Asset address for which the risk indicators are calculated.
        address asset;
        /// @notice Ipor Risk Management Oracle address.
        address iporRiskManagementOracle;
        /// @notice Tenor of the swap.
        IporTypes.SwapTenor tenor;
        /// @notice AMM Liquidity Pool balance.
        uint256 liquidityPoolBalance;
        /// @notice AMM Min Leverage allowed for a swap.
        uint256 minLeverage;
    }

    /// @notice Spread context data
    struct SpreadContext {
        /// @notice Asset address for which the spread is calculated.
        address asset;
        /// @notice Signature of spread method used to calculate spread.
        bytes4 spreadFunctionSig;
        /// @notice Tenor of the swap.
        IporTypes.SwapTenor tenor;
        /// @notice Swap's notional
        uint256 notional;
        /// @notice Minimum leverage allowed for a swap.
        uint256 minLeverage;
        /// @notice Ipor Index Value
        uint256 indexValue;
        /// @notice Risk Indicators data for a opened swap used to calculate spread.
        AmmTypes.OpenSwapRiskIndicators riskIndicators;
        /// @notice AMM Balance for a opened swap used to calculate spread.
        IporTypes.AmmBalancesForOpenSwapMemory balance;
    }

    /// @notice Open swap item - element of linked list of swaps
    struct OpenSwapItem {
        /// @notice Swap ID
        uint32 swapId;
        /// @notcie Next swap ID in linked list
        uint32 nextSwapId;
        /// @notice Previous swap ID in linked list
        uint32 previousSwapId;
        /// @notice Timestamp of the swap opening
        uint32 openSwapTimestamp;
    }

    /// @notice Open swap list structure
    struct OpenSwapList {
        /// @notice Head swap ID
        uint32 headSwapId;
        /// @notice Swaps mapping, where key is swap ID
        mapping(uint32 => OpenSwapItem) swaps;
    }
}

// File: contracts/interfaces/types/AmmStorageTypes.sol


pragma solidity 0.8.20;

/// @title Types used in AmmStorage smart contract
library AmmStorageTypes {
    /// @notice struct representing swap's ID and direction
    /// @dev direction = 0 - Pay Fixed - Receive Floating, direction = 1 - Receive Fixed - Pay Floating
    struct IporSwapId {
        /// @notice Swap's ID
        uint256 id;
        /// @notice Swap's direction, 0 - Pay Fixed Receive Floating, 1 - Receive Fixed Pay Floating
        uint8 direction;
    }

    /// @notice Struct containing extended balance information.
    /// @dev extended information includes: opening fee balance, liquidation deposit balance,
    /// IPOR publication fee balance, treasury balance, all values are with 18 decimals
    struct ExtendedBalancesMemory {
        /// @notice Swap's balance for Pay Fixed leg
        uint256 totalCollateralPayFixed;
        /// @notice Swap's balance for Receive Fixed leg
        uint256 totalCollateralReceiveFixed;
        /// @notice Liquidity Pool's Balance
        uint256 liquidityPool;
        /// @notice AssetManagement's (Asset Management) balance
        uint256 vault;
        /// @notice IPOR publication fee balance. This balance is used to subsidise the oracle operations
        uint256 iporPublicationFee;
        /// @notice Balance of the DAO's treasury. Fed by portion of the opening fee set by the DAO
        uint256 treasury;
    }

    /// @notice A struct with parameters required to calculate SOAP for pay fixed and receive fixed legs.
    /// @dev Committed to the memory.
    struct SoapIndicators {
        /// @notice Value of interest accrued on a fixed leg of all derivatives for this particular type of swap.
        /// @dev Represented in 18 decimals.
        uint256 hypotheticalInterestCumulative;
        /// @notice Sum of all swaps' notional amounts for a given leg.
        /// @dev Represented in 18 decimals.
        uint256 totalNotional;
        /// @notice Sum of all IBTs on a given leg.
        /// @dev Represented in 18 decimals.
        uint256 totalIbtQuantity;
        /// @notice The notional-weighted average interest rate of all swaps on a given leg combined.
        /// @dev Represented in 18 decimals.
        uint256 averageInterestRate;
        /// @notice EPOCH timestamp of when the most recent rebalancing took place
        uint256 rebalanceTimestamp;
    }
}

// File: contracts/interfaces/IAmmStorage.sol


pragma solidity 0.8.20;





/// @title Interface for interaction with the IPOR AMM Storage, contract responsible for managing AMM storage.
interface IAmmStorage {
    /// @notice Returns the current version of AmmTreasury Storage
    /// @dev Increase number when the implementation inside source code is different that the implementation deployed on the Mainnet
    /// @return current AmmTreasury Storage version, integer
    function getVersion() external pure returns (uint256);

    /// @notice Gets the configuration of the IPOR AMM Storage.
    /// @return ammTreasury address of the AmmTreasury contract
    /// @return router address of the IPOR Protocol Router contract
    function getConfiguration() external view returns (address ammTreasury, address router);

    /// @notice Gets last swap ID.
    /// @dev swap ID is incremented when new position is opened, last swap ID is used in Pay Fixed and Receive Fixed swaps.
    /// @dev ID is global for all swaps, regardless if they are Pay Fixed or Receive Fixed in tenor 28, 60 or 90 days.
    /// @return last swap ID, integer
    function getLastSwapId() external view returns (uint256);

    /// @notice Gets the last opened swap for a given tenor and direction.
    /// @param tenor tenor of the swap
    /// @param direction direction of the swap: 0 for Pay Fixed, 1 for Receive Fixed
    /// @return last opened swap {AmmInternalTypes.OpenSwapItem}
    function getLastOpenedSwap(
        IporTypes.SwapTenor tenor,
        uint256 direction
    ) external view returns (AmmInternalTypes.OpenSwapItem memory);

    /// @notice Gets the AMM balance struct
    /// @dev Balance contains:
    /// # Pay Fixed Total Collateral
    /// # Receive Fixed Total Collateral
    /// # Liquidity Pool and Vault balances.
    /// @return balance structure {IporTypes.AmmBalancesMemory}
    function getBalance() external view returns (IporTypes.AmmBalancesMemory memory);

    /// @notice Gets the balance for open swap
    /// @dev Balance contains:
    /// # Pay Fixed Total Collateral
    /// # Receive Fixed Total Collateral
    /// # Liquidity Pool balance
    /// # Total Notional Pay Fixed
    /// # Total Notional Receive Fixed
    /// @return balance structure {IporTypes.AmmBalancesForOpenSwapMemory}
    function getBalancesForOpenSwap() external view returns (IporTypes.AmmBalancesForOpenSwapMemory memory);

    /// @notice Gets the balance with the extended information: IPOR publication fee balance and Treasury balance.
    /// @return balance structure {AmmStorageTypes.ExtendedBalancesMemory}
    function getExtendedBalance() external view returns (AmmStorageTypes.ExtendedBalancesMemory memory);

    /// @notice gets the SOAP indicators.
    /// @dev SOAP is a Sum Of All Payouts, aka undealised PnL.
    /// @return indicatorsPayFixed structure {AmmStorageTypes.SoapIndicators} indicators for Pay Fixed swaps
    /// @return indicatorsReceiveFixed structure {AmmStorageTypes.SoapIndicators} indicators for Receive Fixed swaps
    function getSoapIndicators()
        external
        view
        returns (
            AmmStorageTypes.SoapIndicators memory indicatorsPayFixed,
            AmmStorageTypes.SoapIndicators memory indicatorsReceiveFixed
        );

    /// @notice Gets swap based on the direction and swap ID.
    /// @param direction direction of the swap: 0 for Pay Fixed, 1 for Receive Fixed
    /// @param swapId swap ID
    /// @return swap structure {AmmTypes.Swap}
    function getSwap(AmmTypes.SwapDirection direction, uint256 swapId) external view returns (AmmTypes.Swap memory);

    /// @notice Gets the active Pay-Fixed swaps for a given account address.
    /// @param account account address
    /// @param offset offset for paging
    /// @param chunkSize page size for paging
    /// @return totalCount total number of active Pay-Fixed swaps
    /// @return swaps array where each element has structure {AmmTypes.Swap}
    function getSwapsPayFixed(
        address account,
        uint256 offset,
        uint256 chunkSize
    ) external view returns (uint256 totalCount, AmmTypes.Swap[] memory swaps);

    /// @notice Gets the active Receive-Fixed swaps for a given account address.
    /// @param account account address
    /// @param offset offset for paging
    /// @param chunkSize page size for paging
    /// @return totalCount total number of active Receive Fixed swaps
    /// @return swaps array where each element has structure {AmmTypes.Swap}
    function getSwapsReceiveFixed(
        address account,
        uint256 offset,
        uint256 chunkSize
    ) external view returns (uint256 totalCount, AmmTypes.Swap[] memory swaps);

    /// @notice Gets the active Pay-Fixed and Receive-Fixed swaps IDs for a given account address.
    /// @param account account address
    /// @param offset offset for paging
    /// @param chunkSize page size for paging
    /// @return totalCount total number of active Pay-Fixed and Receive-Fixed IDs.
    /// @return ids array where each element has structure {AmmStorageTypes.IporSwapId}
    function getSwapIds(
        address account,
        uint256 offset,
        uint256 chunkSize
    ) external view returns (uint256 totalCount, AmmStorageTypes.IporSwapId[] memory ids);

    /// @notice adds liquidity to the Liquidity Pool. Function available only to Router.
    /// @param account account address executing request for redeem asset amount
    /// @param assetAmount amount of asset added to balance of Liquidity Pool, represented in 18 decimals
    /// @param cfgMaxLiquidityPoolBalance max liquidity pool balance taken from AmmPoolsService configuration, represented in 18 decimals.
    /// @dev Function is only available to AmmPoolsService, can be executed only by IPOR Protocol Router as internal interaction.
    function addLiquidityInternal(address account, uint256 assetAmount, uint256 cfgMaxLiquidityPoolBalance) external;

    /// @notice subtract liquidity from the Liquidity Pool. Function available only to Router.
    /// @param assetAmount amount of asset subtracted from Liquidity Pool, represented in 18 decimals
    /// @dev Function is only available to AmmPoolsService, it can be executed only by IPOR Protocol Router as internal interaction.
    function subtractLiquidityInternal(uint256 assetAmount) external;

    /// @notice Updates structures in storage: balance, swaps, SOAP indicators when new Pay-Fixed swap is opened.
    /// @dev Function is only available to AmmOpenSwapService, it can be executed only by IPOR Protocol Router as internal interaction.
    /// @param newSwap new swap structure {AmmTypes.NewSwap}
    /// @param cfgIporPublicationFee publication fee amount taken from AmmTreasury configuration, represented in 18 decimals.
    /// @return new swap ID
    function updateStorageWhenOpenSwapPayFixedInternal(
        AmmTypes.NewSwap memory newSwap,
        uint256 cfgIporPublicationFee
    ) external returns (uint256);

    /// @notice Updates structures in the storage: balance, swaps, SOAP indicators when new Receive-Fixed swap is opened.
    /// @dev Function is only available to AmmOpenSwapService, it can be executed only by IPOR Protocol Router as internal interaction.
    /// @param newSwap new swap structure {AmmTypes.NewSwap}
    /// @param cfgIporPublicationFee publication fee amount taken from AmmTreasury configuration, represented in 18 decimals.
    /// @return new swap ID
    function updateStorageWhenOpenSwapReceiveFixedInternal(
        AmmTypes.NewSwap memory newSwap,
        uint256 cfgIporPublicationFee
    ) external returns (uint256);

    /// @notice Updates structures in the storage: balance, swaps, SOAP indicators when closing Pay-Fixed swap.
    /// @dev Function is only available to AmmCloseSwapService, it can be executed only by IPOR Protocol Router as internal interaction.
    /// @param swap The swap structure containing IPOR swap information.
    /// @param pnlValue The amount that the trader has earned or lost on the swap, represented in 18 decimals.
    /// pnValue can be negative, pnlValue NOT INCLUDE potential unwind fee.
    /// @param swapUnwindFeeLPAmount unwind fee which is accounted on AMM Liquidity Pool balance.
    /// @param swapUnwindFeeTreasuryAmount unwind fee which is accounted on AMM Treasury balance.
    /// @param closingTimestamp The moment when the swap was closed.
    /// @return closedSwap A memory struct representing the closed swap.
    function updateStorageWhenCloseSwapPayFixedInternal(
        AmmTypes.Swap memory swap,
        int256 pnlValue,
        uint256 swapUnwindFeeLPAmount,
        uint256 swapUnwindFeeTreasuryAmount,
        uint256 closingTimestamp
    ) external returns (AmmInternalTypes.OpenSwapItem memory closedSwap);

    /// @notice Updates structures in the storage: swaps, balances, SOAP indicators when closing Receive-Fixed swap.
    /// @dev Function is only available to AmmCloseSwapService, it can be executed only by IPOR Protocol Router as internal interaction.
    /// @param swap The swap structure containing IPOR swap information.
    /// @param pnlValue The amount that the trader has earned or lost on the swap, represented in 18 decimals.
    /// pnValue can be negative, pnlValue NOT INCLUDE potential unwind fee.
    /// @param swapUnwindFeeLPAmount unwind fee which is accounted on AMM Liquidity Pool balance.
    /// @param swapUnwindFeeTreasuryAmount unwind fee which is accounted on AMM Treasury balance.
    /// @param closingTimestamp The moment when the swap was closed.
    /// @return closedSwap A memory struct representing the closed swap.
    function updateStorageWhenCloseSwapReceiveFixedInternal(
        AmmTypes.Swap memory swap,
        int256 pnlValue,
        uint256 swapUnwindFeeLPAmount,
        uint256 swapUnwindFeeTreasuryAmount,
        uint256 closingTimestamp
    ) external returns (AmmInternalTypes.OpenSwapItem memory closedSwap);

    /// @notice Updates the balance when the AmmPoolsService withdraws AmmTreasury's assets from the AssetManagement.
    /// @dev Function is only available to the AmmTreasury contract.
    /// @param withdrawnAmount asset amount that was withdrawn from AssetManagement to AmmTreasury by AmmPoolsService, represented in 18 decimals.
    /// @param vaultBalance Asset Management Vault (AssetManagement) balance, represented in 18 decimals
    function updateStorageWhenWithdrawFromAssetManagement(uint256 withdrawnAmount, uint256 vaultBalance) external;

    /// @notice Updates the balance when AmmPoolsService deposits AmmTreasury's assets to AssetManagement. Function is only available to AmmTreasury.
    /// @param depositAmount asset amount deposited from AmmTreasury to AssetManagement by AmmPoolsService, represented in 18 decimals.
    /// @param vaultBalance actual Asset Management Vault(AssetManagement) balance , represented in 18 decimals
    function updateStorageWhenDepositToAssetManagement(uint256 depositAmount, uint256 vaultBalance) external;

    /// @notice Updates the balance when AmmPoolsService transfers AmmTreasury's assets to Oracle Treasury's multisig wallet.
    /// @dev Function is only available to the AmmGovernanceService, can be executed only by IPOR Protocol Router as internal interaction.
    /// @param transferredAmount asset amount transferred to Charlie Treasury multisig wallet.
    function updateStorageWhenTransferToCharlieTreasuryInternal(uint256 transferredAmount) external;

    /// @notice Updates the balance when AmmPoolsService transfers AmmTreasury's assets to Treasury's multisig wallet.
    /// @dev Function is only available to the AmmGovernanceService, can be executed only by IPOR Protocol Router as internal interaction.
    /// @param transferredAmount asset amount transferred to Treasury's multisig wallet.
    function updateStorageWhenTransferToTreasuryInternal(uint256 transferredAmount) external;
}

// File: @openzeppelin/contracts/utils/math/SafeCast.sol


// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/SafeCast.sol)
// This file was procedurally generated from scripts/generate/templates/SafeCast.js.

pragma solidity ^0.8.0;

/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library SafeCast {
    /**
     * @dev Returns the downcasted uint248 from uint256, reverting on
     * overflow (when the input is greater than largest uint248).
     *
     * Counterpart to Solidity's `uint248` operator.
     *
     * Requirements:
     *
     * - input must fit into 248 bits
     *
     * _Available since v4.7._
     */
    function toUint248(uint256 value) internal pure returns (uint248) {
        require(value <= type(uint248).max, "SafeCast: value doesn't fit in 248 bits");
        return uint248(value);
    }

    /**
     * @dev Returns the downcasted uint240 from uint256, reverting on
     * overflow (when the input is greater than largest uint240).
     *
     * Counterpart to Solidity's `uint240` operator.
     *
     * Requirements:
     *
     * - input must fit into 240 bits
     *
     * _Available since v4.7._
     */
    function toUint240(uint256 value) internal pure returns (uint240) {
        require(value <= type(uint240).max, "SafeCast: value doesn't fit in 240 bits");
        return uint240(value);
    }

    /**
     * @dev Returns the downcasted uint232 from uint256, reverting on
     * overflow (when the input is greater than largest uint232).
     *
     * Counterpart to Solidity's `uint232` operator.
     *
     * Requirements:
     *
     * - input must fit into 232 bits
     *
     * _Available since v4.7._
     */
    function toUint232(uint256 value) internal pure returns (uint232) {
        require(value <= type(uint232).max, "SafeCast: value doesn't fit in 232 bits");
        return uint232(value);
    }

    /**
     * @dev Returns the downcasted uint224 from uint256, reverting on
     * overflow (when the input is greater than largest uint224).
     *
     * Counterpart to Solidity's `uint224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     *
     * _Available since v4.2._
     */
    function toUint224(uint256 value) internal pure returns (uint224) {
        require(value <= type(uint224).max, "SafeCast: value doesn't fit in 224 bits");
        return uint224(value);
    }

    /**
     * @dev Returns the downcasted uint216 from uint256, reverting on
     * overflow (when the input is greater than largest uint216).
     *
     * Counterpart to Solidity's `uint216` operator.
     *
     * Requirements:
     *
     * - input must fit into 216 bits
     *
     * _Available since v4.7._
     */
    function toUint216(uint256 value) internal pure returns (uint216) {
        require(value <= type(uint216).max, "SafeCast: value doesn't fit in 216 bits");
        return uint216(value);
    }

    /**
     * @dev Returns the downcasted uint208 from uint256, reverting on
     * overflow (when the input is greater than largest uint208).
     *
     * Counterpart to Solidity's `uint208` operator.
     *
     * Requirements:
     *
     * - input must fit into 208 bits
     *
     * _Available since v4.7._
     */
    function toUint208(uint256 value) internal pure returns (uint208) {
        require(value <= type(uint208).max, "SafeCast: value doesn't fit in 208 bits");
        return uint208(value);
    }

    /**
     * @dev Returns the downcasted uint200 from uint256, reverting on
     * overflow (when the input is greater than largest uint200).
     *
     * Counterpart to Solidity's `uint200` operator.
     *
     * Requirements:
     *
     * - input must fit into 200 bits
     *
     * _Available since v4.7._
     */
    function toUint200(uint256 value) internal pure returns (uint200) {
        require(value <= type(uint200).max, "SafeCast: value doesn't fit in 200 bits");
        return uint200(value);
    }

    /**
     * @dev Returns the downcasted uint192 from uint256, reverting on
     * overflow (when the input is greater than largest uint192).
     *
     * Counterpart to Solidity's `uint192` operator.
     *
     * Requirements:
     *
     * - input must fit into 192 bits
     *
     * _Available since v4.7._
     */
    function toUint192(uint256 value) internal pure returns (uint192) {
        require(value <= type(uint192).max, "SafeCast: value doesn't fit in 192 bits");
        return uint192(value);
    }

    /**
     * @dev Returns the downcasted uint184 from uint256, reverting on
     * overflow (when the input is greater than largest uint184).
     *
     * Counterpart to Solidity's `uint184` operator.
     *
     * Requirements:
     *
     * - input must fit into 184 bits
     *
     * _Available since v4.7._
     */
    function toUint184(uint256 value) internal pure returns (uint184) {
        require(value <= type(uint184).max, "SafeCast: value doesn't fit in 184 bits");
        return uint184(value);
    }

    /**
     * @dev Returns the downcasted uint176 from uint256, reverting on
     * overflow (when the input is greater than largest uint176).
     *
     * Counterpart to Solidity's `uint176` operator.
     *
     * Requirements:
     *
     * - input must fit into 176 bits
     *
     * _Available since v4.7._
     */
    function toUint176(uint256 value) internal pure returns (uint176) {
        require(value <= type(uint176).max, "SafeCast: value doesn't fit in 176 bits");
        return uint176(value);
    }

    /**
     * @dev Returns the downcasted uint168 from uint256, reverting on
     * overflow (when the input is greater than largest uint168).
     *
     * Counterpart to Solidity's `uint168` operator.
     *
     * Requirements:
     *
     * - input must fit into 168 bits
     *
     * _Available since v4.7._
     */
    function toUint168(uint256 value) internal pure returns (uint168) {
        require(value <= type(uint168).max, "SafeCast: value doesn't fit in 168 bits");
        return uint168(value);
    }

    /**
     * @dev Returns the downcasted uint160 from uint256, reverting on
     * overflow (when the input is greater than largest uint160).
     *
     * Counterpart to Solidity's `uint160` operator.
     *
     * Requirements:
     *
     * - input must fit into 160 bits
     *
     * _Available since v4.7._
     */
    function toUint160(uint256 value) internal pure returns (uint160) {
        require(value <= type(uint160).max, "SafeCast: value doesn't fit in 160 bits");
        return uint160(value);
    }

    /**
     * @dev Returns the downcasted uint152 from uint256, reverting on
     * overflow (when the input is greater than largest uint152).
     *
     * Counterpart to Solidity's `uint152` operator.
     *
     * Requirements:
     *
     * - input must fit into 152 bits
     *
     * _Available since v4.7._
     */
    function toUint152(uint256 value) internal pure returns (uint152) {
        require(value <= type(uint152).max, "SafeCast: value doesn't fit in 152 bits");
        return uint152(value);
    }

    /**
     * @dev Returns the downcasted uint144 from uint256, reverting on
     * overflow (when the input is greater than largest uint144).
     *
     * Counterpart to Solidity's `uint144` operator.
     *
     * Requirements:
     *
     * - input must fit into 144 bits
     *
     * _Available since v4.7._
     */
    function toUint144(uint256 value) internal pure returns (uint144) {
        require(value <= type(uint144).max, "SafeCast: value doesn't fit in 144 bits");
        return uint144(value);
    }

    /**
     * @dev Returns the downcasted uint136 from uint256, reverting on
     * overflow (when the input is greater than largest uint136).
     *
     * Counterpart to Solidity's `uint136` operator.
     *
     * Requirements:
     *
     * - input must fit into 136 bits
     *
     * _Available since v4.7._
     */
    function toUint136(uint256 value) internal pure returns (uint136) {
        require(value <= type(uint136).max, "SafeCast: value doesn't fit in 136 bits");
        return uint136(value);
    }

    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v2.5._
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value <= type(uint128).max, "SafeCast: value doesn't fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint120 from uint256, reverting on
     * overflow (when the input is greater than largest uint120).
     *
     * Counterpart to Solidity's `uint120` operator.
     *
     * Requirements:
     *
     * - input must fit into 120 bits
     *
     * _Available since v4.7._
     */
    function toUint120(uint256 value) internal pure returns (uint120) {
        require(value <= type(uint120).max, "SafeCast: value doesn't fit in 120 bits");
        return uint120(value);
    }

    /**
     * @dev Returns the downcasted uint112 from uint256, reverting on
     * overflow (when the input is greater than largest uint112).
     *
     * Counterpart to Solidity's `uint112` operator.
     *
     * Requirements:
     *
     * - input must fit into 112 bits
     *
     * _Available since v4.7._
     */
    function toUint112(uint256 value) internal pure returns (uint112) {
        require(value <= type(uint112).max, "SafeCast: value doesn't fit in 112 bits");
        return uint112(value);
    }

    /**
     * @dev Returns the downcasted uint104 from uint256, reverting on
     * overflow (when the input is greater than largest uint104).
     *
     * Counterpart to Solidity's `uint104` operator.
     *
     * Requirements:
     *
     * - input must fit into 104 bits
     *
     * _Available since v4.7._
     */
    function toUint104(uint256 value) internal pure returns (uint104) {
        require(value <= type(uint104).max, "SafeCast: value doesn't fit in 104 bits");
        return uint104(value);
    }

    /**
     * @dev Returns the downcasted uint96 from uint256, reverting on
     * overflow (when the input is greater than largest uint96).
     *
     * Counterpart to Solidity's `uint96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     *
     * _Available since v4.2._
     */
    function toUint96(uint256 value) internal pure returns (uint96) {
        require(value <= type(uint96).max, "SafeCast: value doesn't fit in 96 bits");
        return uint96(value);
    }

    /**
     * @dev Returns the downcasted uint88 from uint256, reverting on
     * overflow (when the input is greater than largest uint88).
     *
     * Counterpart to Solidity's `uint88` operator.
     *
     * Requirements:
     *
     * - input must fit into 88 bits
     *
     * _Available since v4.7._
     */
    function toUint88(uint256 value) internal pure returns (uint88) {
        require(value <= type(uint88).max, "SafeCast: value doesn't fit in 88 bits");
        return uint88(value);
    }

    /**
     * @dev Returns the downcasted uint80 from uint256, reverting on
     * overflow (when the input is greater than largest uint80).
     *
     * Counterpart to Solidity's `uint80` operator.
     *
     * Requirements:
     *
     * - input must fit into 80 bits
     *
     * _Available since v4.7._
     */
    function toUint80(uint256 value) internal pure returns (uint80) {
        require(value <= type(uint80).max, "SafeCast: value doesn't fit in 80 bits");
        return uint80(value);
    }

    /**
     * @dev Returns the downcasted uint72 from uint256, reverting on
     * overflow (when the input is greater than largest uint72).
     *
     * Counterpart to Solidity's `uint72` operator.
     *
     * Requirements:
     *
     * - input must fit into 72 bits
     *
     * _Available since v4.7._
     */
    function toUint72(uint256 value) internal pure returns (uint72) {
        require(value <= type(uint72).max, "SafeCast: value doesn't fit in 72 bits");
        return uint72(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v2.5._
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value <= type(uint64).max, "SafeCast: value doesn't fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint56 from uint256, reverting on
     * overflow (when the input is greater than largest uint56).
     *
     * Counterpart to Solidity's `uint56` operator.
     *
     * Requirements:
     *
     * - input must fit into 56 bits
     *
     * _Available since v4.7._
     */
    function toUint56(uint256 value) internal pure returns (uint56) {
        require(value <= type(uint56).max, "SafeCast: value doesn't fit in 56 bits");
        return uint56(value);
    }

    /**
     * @dev Returns the downcasted uint48 from uint256, reverting on
     * overflow (when the input is greater than largest uint48).
     *
     * Counterpart to Solidity's `uint48` operator.
     *
     * Requirements:
     *
     * - input must fit into 48 bits
     *
     * _Available since v4.7._
     */
    function toUint48(uint256 value) internal pure returns (uint48) {
        require(value <= type(uint48).max, "SafeCast: value doesn't fit in 48 bits");
        return uint48(value);
    }

    /**
     * @dev Returns the downcasted uint40 from uint256, reverting on
     * overflow (when the input is greater than largest uint40).
     *
     * Counterpart to Solidity's `uint40` operator.
     *
     * Requirements:
     *
     * - input must fit into 40 bits
     *
     * _Available since v4.7._
     */
    function toUint40(uint256 value) internal pure returns (uint40) {
        require(value <= type(uint40).max, "SafeCast: value doesn't fit in 40 bits");
        return uint40(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v2.5._
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value <= type(uint32).max, "SafeCast: value doesn't fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint24 from uint256, reverting on
     * overflow (when the input is greater than largest uint24).
     *
     * Counterpart to Solidity's `uint24` operator.
     *
     * Requirements:
     *
     * - input must fit into 24 bits
     *
     * _Available since v4.7._
     */
    function toUint24(uint256 value) internal pure returns (uint24) {
        require(value <= type(uint24).max, "SafeCast: value doesn't fit in 24 bits");
        return uint24(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v2.5._
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value <= type(uint16).max, "SafeCast: value doesn't fit in 16 bits");
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits
     *
     * _Available since v2.5._
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value <= type(uint8).max, "SafeCast: value doesn't fit in 8 bits");
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     *
     * _Available since v3.0._
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int248 from int256, reverting on
     * overflow (when the input is less than smallest int248 or
     * greater than largest int248).
     *
     * Counterpart to Solidity's `int248` operator.
     *
     * Requirements:
     *
     * - input must fit into 248 bits
     *
     * _Available since v4.7._
     */
    function toInt248(int256 value) internal pure returns (int248 downcasted) {
        downcasted = int248(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 248 bits");
    }

    /**
     * @dev Returns the downcasted int240 from int256, reverting on
     * overflow (when the input is less than smallest int240 or
     * greater than largest int240).
     *
     * Counterpart to Solidity's `int240` operator.
     *
     * Requirements:
     *
     * - input must fit into 240 bits
     *
     * _Available since v4.7._
     */
    function toInt240(int256 value) internal pure returns (int240 downcasted) {
        downcasted = int240(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 240 bits");
    }

    /**
     * @dev Returns the downcasted int232 from int256, reverting on
     * overflow (when the input is less than smallest int232 or
     * greater than largest int232).
     *
     * Counterpart to Solidity's `int232` operator.
     *
     * Requirements:
     *
     * - input must fit into 232 bits
     *
     * _Available since v4.7._
     */
    function toInt232(int256 value) internal pure returns (int232 downcasted) {
        downcasted = int232(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 232 bits");
    }

    /**
     * @dev Returns the downcasted int224 from int256, reverting on
     * overflow (when the input is less than smallest int224 or
     * greater than largest int224).
     *
     * Counterpart to Solidity's `int224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     *
     * _Available since v4.7._
     */
    function toInt224(int256 value) internal pure returns (int224 downcasted) {
        downcasted = int224(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 224 bits");
    }

    /**
     * @dev Returns the downcasted int216 from int256, reverting on
     * overflow (when the input is less than smallest int216 or
     * greater than largest int216).
     *
     * Counterpart to Solidity's `int216` operator.
     *
     * Requirements:
     *
     * - input must fit into 216 bits
     *
     * _Available since v4.7._
     */
    function toInt216(int256 value) internal pure returns (int216 downcasted) {
        downcasted = int216(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 216 bits");
    }

    /**
     * @dev Returns the downcasted int208 from int256, reverting on
     * overflow (when the input is less than smallest int208 or
     * greater than largest int208).
     *
     * Counterpart to Solidity's `int208` operator.
     *
     * Requirements:
     *
     * - input must fit into 208 bits
     *
     * _Available since v4.7._
     */
    function toInt208(int256 value) internal pure returns (int208 downcasted) {
        downcasted = int208(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 208 bits");
    }

    /**
     * @dev Returns the downcasted int200 from int256, reverting on
     * overflow (when the input is less than smallest int200 or
     * greater than largest int200).
     *
     * Counterpart to Solidity's `int200` operator.
     *
     * Requirements:
     *
     * - input must fit into 200 bits
     *
     * _Available since v4.7._
     */
    function toInt200(int256 value) internal pure returns (int200 downcasted) {
        downcasted = int200(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 200 bits");
    }

    /**
     * @dev Returns the downcasted int192 from int256, reverting on
     * overflow (when the input is less than smallest int192 or
     * greater than largest int192).
     *
     * Counterpart to Solidity's `int192` operator.
     *
     * Requirements:
     *
     * - input must fit into 192 bits
     *
     * _Available since v4.7._
     */
    function toInt192(int256 value) internal pure returns (int192 downcasted) {
        downcasted = int192(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 192 bits");
    }

    /**
     * @dev Returns the downcasted int184 from int256, reverting on
     * overflow (when the input is less than smallest int184 or
     * greater than largest int184).
     *
     * Counterpart to Solidity's `int184` operator.
     *
     * Requirements:
     *
     * - input must fit into 184 bits
     *
     * _Available since v4.7._
     */
    function toInt184(int256 value) internal pure returns (int184 downcasted) {
        downcasted = int184(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 184 bits");
    }

    /**
     * @dev Returns the downcasted int176 from int256, reverting on
     * overflow (when the input is less than smallest int176 or
     * greater than largest int176).
     *
     * Counterpart to Solidity's `int176` operator.
     *
     * Requirements:
     *
     * - input must fit into 176 bits
     *
     * _Available since v4.7._
     */
    function toInt176(int256 value) internal pure returns (int176 downcasted) {
        downcasted = int176(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 176 bits");
    }

    /**
     * @dev Returns the downcasted int168 from int256, reverting on
     * overflow (when the input is less than smallest int168 or
     * greater than largest int168).
     *
     * Counterpart to Solidity's `int168` operator.
     *
     * Requirements:
     *
     * - input must fit into 168 bits
     *
     * _Available since v4.7._
     */
    function toInt168(int256 value) internal pure returns (int168 downcasted) {
        downcasted = int168(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 168 bits");
    }

    /**
     * @dev Returns the downcasted int160 from int256, reverting on
     * overflow (when the input is less than smallest int160 or
     * greater than largest int160).
     *
     * Counterpart to Solidity's `int160` operator.
     *
     * Requirements:
     *
     * - input must fit into 160 bits
     *
     * _Available since v4.7._
     */
    function toInt160(int256 value) internal pure returns (int160 downcasted) {
        downcasted = int160(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 160 bits");
    }

    /**
     * @dev Returns the downcasted int152 from int256, reverting on
     * overflow (when the input is less than smallest int152 or
     * greater than largest int152).
     *
     * Counterpart to Solidity's `int152` operator.
     *
     * Requirements:
     *
     * - input must fit into 152 bits
     *
     * _Available since v4.7._
     */
    function toInt152(int256 value) internal pure returns (int152 downcasted) {
        downcasted = int152(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 152 bits");
    }

    /**
     * @dev Returns the downcasted int144 from int256, reverting on
     * overflow (when the input is less than smallest int144 or
     * greater than largest int144).
     *
     * Counterpart to Solidity's `int144` operator.
     *
     * Requirements:
     *
     * - input must fit into 144 bits
     *
     * _Available since v4.7._
     */
    function toInt144(int256 value) internal pure returns (int144 downcasted) {
        downcasted = int144(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 144 bits");
    }

    /**
     * @dev Returns the downcasted int136 from int256, reverting on
     * overflow (when the input is less than smallest int136 or
     * greater than largest int136).
     *
     * Counterpart to Solidity's `int136` operator.
     *
     * Requirements:
     *
     * - input must fit into 136 bits
     *
     * _Available since v4.7._
     */
    function toInt136(int256 value) internal pure returns (int136 downcasted) {
        downcasted = int136(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 136 bits");
    }

    /**
     * @dev Returns the downcasted int128 from int256, reverting on
     * overflow (when the input is less than smallest int128 or
     * greater than largest int128).
     *
     * Counterpart to Solidity's `int128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v3.1._
     */
    function toInt128(int256 value) internal pure returns (int128 downcasted) {
        downcasted = int128(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 128 bits");
    }

    /**
     * @dev Returns the downcasted int120 from int256, reverting on
     * overflow (when the input is less than smallest int120 or
     * greater than largest int120).
     *
     * Counterpart to Solidity's `int120` operator.
     *
     * Requirements:
     *
     * - input must fit into 120 bits
     *
     * _Available since v4.7._
     */
    function toInt120(int256 value) internal pure returns (int120 downcasted) {
        downcasted = int120(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 120 bits");
    }

    /**
     * @dev Returns the downcasted int112 from int256, reverting on
     * overflow (when the input is less than smallest int112 or
     * greater than largest int112).
     *
     * Counterpart to Solidity's `int112` operator.
     *
     * Requirements:
     *
     * - input must fit into 112 bits
     *
     * _Available since v4.7._
     */
    function toInt112(int256 value) internal pure returns (int112 downcasted) {
        downcasted = int112(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 112 bits");
    }

    /**
     * @dev Returns the downcasted int104 from int256, reverting on
     * overflow (when the input is less than smallest int104 or
     * greater than largest int104).
     *
     * Counterpart to Solidity's `int104` operator.
     *
     * Requirements:
     *
     * - input must fit into 104 bits
     *
     * _Available since v4.7._
     */
    function toInt104(int256 value) internal pure returns (int104 downcasted) {
        downcasted = int104(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 104 bits");
    }

    /**
     * @dev Returns the downcasted int96 from int256, reverting on
     * overflow (when the input is less than smallest int96 or
     * greater than largest int96).
     *
     * Counterpart to Solidity's `int96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     *
     * _Available since v4.7._
     */
    function toInt96(int256 value) internal pure returns (int96 downcasted) {
        downcasted = int96(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 96 bits");
    }

    /**
     * @dev Returns the downcasted int88 from int256, reverting on
     * overflow (when the input is less than smallest int88 or
     * greater than largest int88).
     *
     * Counterpart to Solidity's `int88` operator.
     *
     * Requirements:
     *
     * - input must fit into 88 bits
     *
     * _Available since v4.7._
     */
    function toInt88(int256 value) internal pure returns (int88 downcasted) {
        downcasted = int88(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 88 bits");
    }

    /**
     * @dev Returns the downcasted int80 from int256, reverting on
     * overflow (when the input is less than smallest int80 or
     * greater than largest int80).
     *
     * Counterpart to Solidity's `int80` operator.
     *
     * Requirements:
     *
     * - input must fit into 80 bits
     *
     * _Available since v4.7._
     */
    function toInt80(int256 value) internal pure returns (int80 downcasted) {
        downcasted = int80(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 80 bits");
    }

    /**
     * @dev Returns the downcasted int72 from int256, reverting on
     * overflow (when the input is less than smallest int72 or
     * greater than largest int72).
     *
     * Counterpart to Solidity's `int72` operator.
     *
     * Requirements:
     *
     * - input must fit into 72 bits
     *
     * _Available since v4.7._
     */
    function toInt72(int256 value) internal pure returns (int72 downcasted) {
        downcasted = int72(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 72 bits");
    }

    /**
     * @dev Returns the downcasted int64 from int256, reverting on
     * overflow (when the input is less than smallest int64 or
     * greater than largest int64).
     *
     * Counterpart to Solidity's `int64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v3.1._
     */
    function toInt64(int256 value) internal pure returns (int64 downcasted) {
        downcasted = int64(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 64 bits");
    }

    /**
     * @dev Returns the downcasted int56 from int256, reverting on
     * overflow (when the input is less than smallest int56 or
     * greater than largest int56).
     *
     * Counterpart to Solidity's `int56` operator.
     *
     * Requirements:
     *
     * - input must fit into 56 bits
     *
     * _Available since v4.7._
     */
    function toInt56(int256 value) internal pure returns (int56 downcasted) {
        downcasted = int56(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 56 bits");
    }

    /**
     * @dev Returns the downcasted int48 from int256, reverting on
     * overflow (when the input is less than smallest int48 or
     * greater than largest int48).
     *
     * Counterpart to Solidity's `int48` operator.
     *
     * Requirements:
     *
     * - input must fit into 48 bits
     *
     * _Available since v4.7._
     */
    function toInt48(int256 value) internal pure returns (int48 downcasted) {
        downcasted = int48(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 48 bits");
    }

    /**
     * @dev Returns the downcasted int40 from int256, reverting on
     * overflow (when the input is less than smallest int40 or
     * greater than largest int40).
     *
     * Counterpart to Solidity's `int40` operator.
     *
     * Requirements:
     *
     * - input must fit into 40 bits
     *
     * _Available since v4.7._
     */
    function toInt40(int256 value) internal pure returns (int40 downcasted) {
        downcasted = int40(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 40 bits");
    }

    /**
     * @dev Returns the downcasted int32 from int256, reverting on
     * overflow (when the input is less than smallest int32 or
     * greater than largest int32).
     *
     * Counterpart to Solidity's `int32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v3.1._
     */
    function toInt32(int256 value) internal pure returns (int32 downcasted) {
        downcasted = int32(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 32 bits");
    }

    /**
     * @dev Returns the downcasted int24 from int256, reverting on
     * overflow (when the input is less than smallest int24 or
     * greater than largest int24).
     *
     * Counterpart to Solidity's `int24` operator.
     *
     * Requirements:
     *
     * - input must fit into 24 bits
     *
     * _Available since v4.7._
     */
    function toInt24(int256 value) internal pure returns (int24 downcasted) {
        downcasted = int24(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 24 bits");
    }

    /**
     * @dev Returns the downcasted int16 from int256, reverting on
     * overflow (when the input is less than smallest int16 or
     * greater than largest int16).
     *
     * Counterpart to Solidity's `int16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v3.1._
     */
    function toInt16(int256 value) internal pure returns (int16 downcasted) {
        downcasted = int16(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 16 bits");
    }

    /**
     * @dev Returns the downcasted int8 from int256, reverting on
     * overflow (when the input is less than smallest int8 or
     * greater than largest int8).
     *
     * Counterpart to Solidity's `int8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8 downcasted) {
        downcasted = int8(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 8 bits");
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     *
     * _Available since v3.0._
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        // Note: Unsafe cast below is okay because `type(int256).max` is guaranteed to be positive
        require(value <= uint256(type(int256).max), "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}

// File: contracts/libraries/math/InterestRates.sol


pragma solidity 0.8.20;





library InterestRates {
    using SafeCast for uint256;

    /// @notice Adds interest to given value using continuous compounding formula: v2 = value * e^(interestRate * time)
    /// @param value value to which interest is added, value represented in 18 decimals
    /// @param interestRatePeriodMultiplication interest rate * time, interest rate in 18 decimals, time in seconds
    /// @return value with interest, value represented in 18 decimals
    function addContinuousCompoundInterestUsingRatePeriodMultiplication(
        uint256 value,
        uint256 interestRatePeriodMultiplication
    ) internal pure returns (uint256) {
        uint256 interestRateYearsMultiplication = IporMath.division(
            interestRatePeriodMultiplication,
            Constants.YEAR_IN_SECONDS
        );
        bytes16 floatValue = _toQuadruplePrecision(value, 1e18);
        bytes16 floatIpm = _toQuadruplePrecision(interestRateYearsMultiplication, 1e18);
        bytes16 valueWithInterest = ABDKMathQuad.mul(floatValue, ABDKMathQuad.exp(floatIpm));
        return _toUint256(valueWithInterest);
    }

    /// @notice Adds interest to given value using continuous compounding formula: v2 = value * e^(interestRate * time)
    /// @param value value to which interest is added, value represented in 18 decimals
    /// @param interestRatePeriodMultiplication interest rate * time, interest rate in 18 decimals, time in seconds
    /// @return value with interest, value represented in 18 decimals
    function addContinuousCompoundInterestUsingRatePeriodMultiplicationInt(
        int256 value,
        int256 interestRatePeriodMultiplication
    ) internal pure returns (int256) {
        int256 interestRateYearsMultiplication = IporMath.divisionInt(
            interestRatePeriodMultiplication,
            Constants.YEAR_IN_SECONDS.toInt256()
        );
        bytes16 floatValue = _toQuadruplePrecisionInt(value, 1e18);
        bytes16 floatIpm = _toQuadruplePrecisionInt(interestRateYearsMultiplication, 1e18);
        bytes16 valueWithInterest = ABDKMathQuad.mul(floatValue, ABDKMathQuad.exp(floatIpm));
        return _toInt256(valueWithInterest);
    }

    /// @notice Calculates interest to given value using continuous compounding formula: v2 = value * e^(interestRate * time)
    /// @param value value to which interest is added, value represented in 18 decimals
    /// @param interestRatePeriodMultiplication interest rate * time, interest rate in 18 decimals, time in seconds
    /// @return interest, value represented in 18 decimals
    function calculateContinuousCompoundInterestUsingRatePeriodMultiplication(
        uint256 value,
        uint256 interestRatePeriodMultiplication
    ) internal pure returns (uint256) {
        return
            addContinuousCompoundInterestUsingRatePeriodMultiplication(value, interestRatePeriodMultiplication) - value;
    }

    /// @notice Calculates interest to given value using continuous compounding formula: v2 = value * e^(interestRate * time)
    /// @param value value to which interest is added, value represented in 18 decimals
    /// @param interestRatePeriodMultiplication interest rate * time, interest rate in 18 decimals, time in seconds
    /// @return interest, value represented in 18 decimals
    function calculateContinuousCompoundInterestUsingRatePeriodMultiplicationInt(
        int256 value,
        int256 interestRatePeriodMultiplication
    ) internal pure returns (int256) {
        return
            addContinuousCompoundInterestUsingRatePeriodMultiplicationInt(value, interestRatePeriodMultiplication) -
            value;
    }

    /// @dev Quadruple precision, 128 bits
    function _toQuadruplePrecision(uint256 number, uint256 decimals) private pure returns (bytes16) {
        if (number % decimals > 0) {
            /// @dev during calculation this value is lost in the conversion
            number += 1;
        }
        bytes16 nominator = ABDKMathQuad.fromUInt(number);
        bytes16 denominator = ABDKMathQuad.fromUInt(decimals);
        bytes16 fraction = ABDKMathQuad.div(nominator, denominator);
        return fraction;
    }

    /// @dev Quadruple precision, 128 bits
    function _toQuadruplePrecisionInt(int256 number, int256 decimals) private pure returns (bytes16) {
        if (number % decimals > 0) {
            /// @dev during calculation this value is lost in the conversion
            number += 1;
        }
        bytes16 nominator = ABDKMathQuad.fromInt(number);
        bytes16 denominator = ABDKMathQuad.fromInt(decimals);
        bytes16 fraction = ABDKMathQuad.div(nominator, denominator);
        return fraction;
    }

    function _toUint256(bytes16 value) private pure returns (uint256) {
        bytes16 decimals = ABDKMathQuad.fromUInt(1e18);
        bytes16 resultD18 = ABDKMathQuad.mul(value, decimals);
        return ABDKMathQuad.toUInt(resultD18);
    }

    function _toInt256(bytes16 value) private pure returns (int256) {
        bytes16 decimals = ABDKMathQuad.fromUInt(1e18);
        bytes16 resultD18 = ABDKMathQuad.mul(value, decimals);
        return ABDKMathQuad.toInt(resultD18);
    }
}

// File: contracts/amm/libraries/SoapIndicatorLogic.sol


pragma solidity 0.8.20;






/// @title Basic logic related with SOAP indicators
library SoapIndicatorLogic {
    using SafeCast for uint256;
    using InterestRates for uint256;

    /// @notice Calculate the SOAP for pay fixed leg
    /// @param si SOAP indicators
    /// @param calculateTimestamp timestamp to calculate the SOAP
    /// @param ibtPrice IBT price
    /// @return SOAP for pay fixed leg
    function calculateSoapPayFixed(
        AmmStorageTypes.SoapIndicators memory si,
        uint256 calculateTimestamp,
        uint256 ibtPrice
    ) internal pure returns (int256) {
        return
            IporMath.division(si.totalIbtQuantity * ibtPrice, 1e18).toInt256() -
            (si.totalNotional + calculateHyphoteticalInterestTotal(si, calculateTimestamp)).toInt256();
    }

    /// @notice Calculate the SOAP for receive fixed leg
    /// @param si SOAP indicators
    /// @param calculateTimestamp timestamp to calculate the SOAP
    /// @param ibtPrice IBT price
    /// @return SOAP for receive fixed leg
    function calculateSoapReceiveFixed(
        AmmStorageTypes.SoapIndicators memory si,
        uint256 calculateTimestamp,
        uint256 ibtPrice
    ) internal pure returns (int256) {
        return
            (si.totalNotional + calculateHyphoteticalInterestTotal(si, calculateTimestamp)).toInt256() -
            IporMath.division(si.totalIbtQuantity * ibtPrice, 1e18).toInt256();
    }

    /// @notice Calculate hypothetical interest total, value that is used to calculate the SOAP
    /// @param si SOAP indicators
    /// @param calculateTimestamp timestamp to calculate the value
    /// @return hypothetical interest total
    function calculateHyphoteticalInterestTotal(
        AmmStorageTypes.SoapIndicators memory si,
        uint256 calculateTimestamp
    ) internal pure returns (uint256) {
        return
            si.hypotheticalInterestCumulative +
            calculateHypotheticalInterestDelta(
                calculateTimestamp,
                si.rebalanceTimestamp,
                si.totalNotional + si.hypotheticalInterestCumulative,
                si.averageInterestRate
            );
    }

    /// @notice Calculate hypothetical interest delta, value that is used to calculate the SOAP
    /// @param calculateTimestamp timestamp to calculate the value
    /// @param lastRebalanceTimestamp last rebalance timestamp
    /// @param totalNotional total notional
    /// @param averageInterestRate average interest rate
    /// @return hypothetical interest delta
    function calculateHypotheticalInterestDelta(
        uint256 calculateTimestamp,
        uint256 lastRebalanceTimestamp,
        uint256 totalNotional,
        uint256 averageInterestRate
    ) internal pure returns (uint256) {
        require(
            calculateTimestamp >= lastRebalanceTimestamp,
            AmmErrors.CALC_TIMESTAMP_LOWER_THAN_SOAP_REBALANCE_TIMESTAMP
        );
        return
            totalNotional.calculateContinuousCompoundInterestUsingRatePeriodMultiplication(
                averageInterestRate * (calculateTimestamp - lastRebalanceTimestamp)
            );
    }
}

// File: contracts/amm/libraries/SoapIndicatorRebalanceLogic.sol


pragma solidity 0.8.20;







/// @title Basic logic related with SOAP indicators when rebalance
library SoapIndicatorRebalanceLogic {
    using SafeCast for uint256;
    using InterestRates for uint256;

    /// @notice Update SOAP indicators when open swap
    /// @param si SOAP indicators
    /// @param rebalanceTimestamp timestamp when the rebalance is executed
    /// @param swapNotional notional of the swap which is going to be opened and influence the SOAP
    /// @param swapFixedInterestRate fixed interest rate of the swap
    /// @param swapIbtQuantity IBT quantity of the swap
    /// @return updated SOAP indicators
    function rebalanceWhenOpenSwap(
        AmmStorageTypes.SoapIndicators memory si,
        uint256 rebalanceTimestamp,
        uint256 swapNotional,
        uint256 swapFixedInterestRate,
        uint256 swapIbtQuantity
    ) external pure returns (AmmStorageTypes.SoapIndicators memory) {
        uint256 averageInterestRate = calculateAverageInterestRateWhenOpenSwap(
            si.totalNotional,
            si.averageInterestRate,
            swapNotional,
            swapFixedInterestRate
        );

        uint256 hypotheticalInterestTotal = SoapIndicatorLogic.calculateHyphoteticalInterestTotal(
            si,
            rebalanceTimestamp
        );

        si.rebalanceTimestamp = rebalanceTimestamp;
        si.totalNotional = si.totalNotional + swapNotional;
        si.totalIbtQuantity = si.totalIbtQuantity + swapIbtQuantity;
        si.averageInterestRate = averageInterestRate;
        si.hypotheticalInterestCumulative = hypotheticalInterestTotal;

        return si;
    }

    /// @notice Update SOAP indicators when close swap
    /// @param si SOAP indicators
    /// @param rebalanceTimestamp timestamp when the rebalance is executed
    /// @param swapOpenTimestamp timestamp when the swap was opened
    /// @param swapNotional notional of the swap which is going to be closed and influence the SOAP
    /// @param swapFixedInterestRate fixed interest rate of the swap
    /// @param swapIbtQuantity IBT quantity of the swap
    /// @return updated SOAP indicators
    function rebalanceWhenCloseSwap(
        AmmStorageTypes.SoapIndicators memory si,
        uint256 rebalanceTimestamp,
        uint256 swapOpenTimestamp,
        uint256 swapNotional,
        uint256 swapFixedInterestRate,
        uint256 swapIbtQuantity
    ) external pure returns (AmmStorageTypes.SoapIndicators memory) {
        uint256 newAverageInterestRate = calculateAverageInterestRateWhenCloseSwap(
            si.totalNotional,
            si.averageInterestRate,
            swapNotional,
            swapFixedInterestRate
        );

        if (si.totalNotional != swapNotional) {
            uint256 currentHypoteticalInterestTotal = SoapIndicatorLogic.calculateHyphoteticalInterestTotal(
                si,
                rebalanceTimestamp
            );

            uint256 interestPaidOut = calculateInterestPaidOut(
                rebalanceTimestamp,
                swapOpenTimestamp,
                swapNotional,
                swapFixedInterestRate
            );

            if (currentHypoteticalInterestTotal >= interestPaidOut) {
                si.hypotheticalInterestCumulative = currentHypoteticalInterestTotal - interestPaidOut;
            } else {
                si.hypotheticalInterestCumulative = 0;
            }
            si.totalNotional = si.totalNotional - swapNotional;
            si.totalIbtQuantity = si.totalIbtQuantity - swapIbtQuantity;
            si.averageInterestRate = newAverageInterestRate;
            si.rebalanceTimestamp = rebalanceTimestamp;
        } else {
            /// @dev when newAverageInterestRate = 0 it means in IPOR Protocol is closing the LAST derivative on this leg.
            si.hypotheticalInterestCumulative = 0;
            si.totalNotional = 0;
            si.totalIbtQuantity = 0;
            si.averageInterestRate = 0;
            si.rebalanceTimestamp = rebalanceTimestamp;
        }

        return si;
    }

    /// @notice Calculate the interest paid out of the swap when close it
    /// @param calculateTimestamp timestamp when the rebalance is executed
    /// @param swapOpenTimestamp timestamp when the swap was opened
    /// @param swapNotional notional of the swap
    /// @param swapFixedInterestRate fixed interest rate of the swap
    /// @return interest paid out, represented in 18 decimals
    function calculateInterestPaidOut(
        uint256 calculateTimestamp,
        uint256 swapOpenTimestamp,
        uint256 swapNotional,
        uint256 swapFixedInterestRate
    ) internal pure returns (uint256) {
        require(calculateTimestamp >= swapOpenTimestamp, AmmErrors.CALC_TIMESTAMP_LOWER_THAN_SWAP_OPEN_TIMESTAMP);
        return
            swapNotional.calculateContinuousCompoundInterestUsingRatePeriodMultiplication(
                swapFixedInterestRate * (calculateTimestamp - swapOpenTimestamp)
            );
    }

    /// @notice Calculate the average interest rate when open a swap
    /// @param totalNotional total notional balance
    /// @param averageInterestRate average interest rate
    /// @param swapNotional notional of the swap
    /// @param swapFixedInterestRate fixed interest rate of the swap
    /// @return newAverageInterestRate average interest rate, represented in 18 decimals
    function calculateAverageInterestRateWhenOpenSwap(
        uint256 totalNotional,
        uint256 averageInterestRate,
        uint256 swapNotional,
        uint256 swapFixedInterestRate
    ) internal pure returns (uint256 newAverageInterestRate) {
        newAverageInterestRate = IporMath.division(
            (totalNotional * averageInterestRate + swapNotional * swapFixedInterestRate),
            (totalNotional + swapNotional)
        );

        if (averageInterestRate != 0) {
            require(newAverageInterestRate > 0, AmmErrors.AVERAGE_INTEREST_RATE_WHEN_OPEN_SWAP_CANNOT_BE_ZERO);
        }
    }

    /// @notice Calculate the average interest rate when close a swap
    /// @param totalNotional total notional balance
    /// @param averageInterestRate average interest rate for all opened swaps in AMM
    /// @param swapNotional notional of the swap
    /// @param swapFixedInterestRate fixed interest rate of the swap
    /// @return newAverageInterestRate average interest rate, represented in 18 decimals
    function calculateAverageInterestRateWhenCloseSwap(
        uint256 totalNotional,
        uint256 averageInterestRate,
        uint256 swapNotional,
        uint256 swapFixedInterestRate
    ) internal pure returns (uint256 newAverageInterestRate) {
        require(swapNotional <= totalNotional, AmmErrors.SWAP_NOTIONAL_HIGHER_THAN_TOTAL_NOTIONAL);

        if (swapNotional == totalNotional) {
            return 0;
        } else {
            uint256 totalNotionalAndAverageInterestRate = totalNotional * averageInterestRate;
            uint256 swapNotionalAndSwapFixedInterestRate = swapNotional * swapFixedInterestRate;

            if (totalNotionalAndAverageInterestRate <= swapNotionalAndSwapFixedInterestRate) {
                return 0;
            } else {
                newAverageInterestRate = IporMath.division(
                    (totalNotionalAndAverageInterestRate - swapNotionalAndSwapFixedInterestRate),
                    (totalNotional - swapNotional)
                );
                if (averageInterestRate > 0) {
                    require(newAverageInterestRate > 0, AmmErrors.AVERAGE_INTEREST_RATE_WHEN_CLOSE_SWAP_CANNOT_BE_ZERO);
                }
            }
        }
    }
}

// File: @openzeppelin/contracts-upgradeable/utils/StorageSlotUpgradeable.sol


// OpenZeppelin Contracts (last updated v4.9.0) (utils/StorageSlot.sol)
// This file was procedurally generated from scripts/generate/templates/StorageSlot.js.

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```solidity
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, `uint256`._
 * _Available since v4.9 for `string`, `bytes`._
 */
library StorageSlotUpgradeable {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    struct StringSlot {
        string value;
    }

    struct BytesSlot {
        bytes value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `StringSlot` with member `value` located at `slot`.
     */
    function getStringSlot(bytes32 slot) internal pure returns (StringSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `StringSlot` representation of the string storage pointer `store`.
     */
    function getStringSlot(string storage store) internal pure returns (StringSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := store.slot
        }
    }

    /**
     * @dev Returns an `BytesSlot` with member `value` located at `slot`.
     */
    function getBytesSlot(bytes32 slot) internal pure returns (BytesSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BytesSlot` representation of the bytes storage pointer `store`.
     */
    function getBytesSlot(bytes storage store) internal pure returns (BytesSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := store.slot
        }
    }
}

// File: @openzeppelin/contracts-upgradeable/interfaces/IERC1967Upgradeable.sol


// OpenZeppelin Contracts (last updated v4.9.0) (interfaces/IERC1967.sol)

pragma solidity ^0.8.0;

/**
 * @dev ERC-1967: Proxy Storage Slots. This interface contains the events defined in the ERC.
 *
 * _Available since v4.8.3._
 */
interface IERC1967Upgradeable {
    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Emitted when the beacon is changed.
     */
    event BeaconUpgraded(address indexed beacon);
}

// File: @openzeppelin/contracts-upgradeable/proxy/beacon/IBeaconUpgradeable.sol


// OpenZeppelin Contracts v4.4.1 (proxy/beacon/IBeacon.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeaconUpgradeable {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}

// File: @openzeppelin/contracts-upgradeable/interfaces/draft-IERC1822Upgradeable.sol


// OpenZeppelin Contracts (last updated v4.5.0) (interfaces/draft-IERC1822.sol)

pragma solidity ^0.8.0;

/**
 * @dev ERC1822: Universal Upgradeable Proxy Standard (UUPS) documents a method for upgradeability through a simplified
 * proxy whose upgrades are fully controlled by the current implementation.
 */
interface IERC1822ProxiableUpgradeable {
    /**
     * @dev Returns the storage slot that the proxiable contract assumes is being used to store the implementation
     * address.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy.
     */
    function proxiableUUID() external view returns (bytes32);
}

// File: @openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol


// OpenZeppelin Contracts (last updated v4.9.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     *
     * Furthermore, `isContract` will also return true if the target contract within
     * the same transaction is already scheduled for destruction by `SELFDESTRUCT`,
     * which only has an effect at the end of a transaction.
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.8.0/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}

// File: @openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol


// OpenZeppelin Contracts (last updated v4.9.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;


/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```solidity
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 *
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * Similar to `reinitializer(1)`, except that functions marked with `initializer` can be nested in the context of a
     * constructor.
     *
     * Emits an {Initialized} event.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * A reinitializer may be used after the original initialization step. This is essential to configure modules that
     * are added through upgrades and that require initialization.
     *
     * When `version` is 1, this modifier is similar to `initializer`, except that functions marked with `reinitializer`
     * cannot be nested. If one is invoked in the context of another, execution will revert.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     *
     * WARNING: setting the version to 255 will prevent any future reinitialization.
     *
     * Emits an {Initialized} event.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     *
     * Emits an {Initialized} event the first time it is successfully executed.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized != type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /**
     * @dev Returns the highest version that has been initialized. See {reinitializer}.
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Returns `true` if the contract is currently initializing. See {onlyInitializing}.
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
}

// File: @openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol


// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;


/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// File: @openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol


// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

pragma solidity ^0.8.0;



/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// File: contracts/security/IporOwnableUpgradeable.sol


pragma solidity 0.8.20;



/// @title Extended version of OpenZeppelin OwnableUpgradeable contract with appointed owner
abstract contract IporOwnableUpgradeable is OwnableUpgradeable {
    address private _appointedOwner;

    /// @notice Emitted when account is appointed to transfer ownership
    /// @param appointedOwner Address of appointed owner
    event AppointedToTransferOwnership(address indexed appointedOwner);

    modifier onlyAppointedOwner() {
        require(_appointedOwner == msg.sender, IporErrors.SENDER_NOT_APPOINTED_OWNER);
        _;
    }

    /// @notice Oppoint account to transfer ownership
    /// @param appointedOwner Address of appointed owner
    function transferOwnership(address appointedOwner) public override onlyOwner {
        require(appointedOwner != address(0), IporErrors.WRONG_ADDRESS);
        _appointedOwner = appointedOwner;
        emit AppointedToTransferOwnership(appointedOwner);
    }

    /// @notice Confirm transfer ownership
    /// @dev This is real transfer ownership in second step by appointed account
    function confirmTransferOwnership() external onlyAppointedOwner {
        _appointedOwner = address(0);
        _transferOwnership(msg.sender);
    }

    /// @notice Renounce ownership
    function renounceOwnership() public virtual override onlyOwner {
        _transferOwnership(address(0));
        _appointedOwner = address(0);
    }
}

// File: @openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;



/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    function __Pausable_init() internal onlyInitializing {
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal onlyInitializing {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// File: @openzeppelin/contracts-upgradeable/proxy/ERC1967/ERC1967UpgradeUpgradeable.sol


// OpenZeppelin Contracts (last updated v4.9.0) (proxy/ERC1967/ERC1967Upgrade.sol)

pragma solidity ^0.8.2;







/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 */
abstract contract ERC1967UpgradeUpgradeable is Initializable, IERC1967Upgradeable {
    function __ERC1967Upgrade_init() internal onlyInitializing {
    }

    function __ERC1967Upgrade_init_unchained() internal onlyInitializing {
    }
    // This is the keccak-256 hash of "eip1967.proxy.rollback" subtracted by 1
    bytes32 private constant _ROLLBACK_SLOT = 0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Returns the current implementation address.
     */
    function _getImplementation() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(AddressUpgradeable.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
    }

    /**
     * @dev Perform implementation upgrade
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Perform implementation upgrade with additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCall(address newImplementation, bytes memory data, bool forceCall) internal {
        _upgradeTo(newImplementation);
        if (data.length > 0 || forceCall) {
            AddressUpgradeable.functionDelegateCall(newImplementation, data);
        }
    }

    /**
     * @dev Perform implementation upgrade with security checks for UUPS proxies, and additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCallUUPS(address newImplementation, bytes memory data, bool forceCall) internal {
        // Upgrades from old implementations will perform a rollback test. This test requires the new
        // implementation to upgrade back to the old, non-ERC1822 compliant, implementation. Removing
        // this special case will break upgrade paths from old UUPS implementation to new ones.
        if (StorageSlotUpgradeable.getBooleanSlot(_ROLLBACK_SLOT).value) {
            _setImplementation(newImplementation);
        } else {
            try IERC1822ProxiableUpgradeable(newImplementation).proxiableUUID() returns (bytes32 slot) {
                require(slot == _IMPLEMENTATION_SLOT, "ERC1967Upgrade: unsupported proxiableUUID");
            } catch {
                revert("ERC1967Upgrade: new implementation is not UUPS");
            }
            _upgradeToAndCall(newImplementation, data, forceCall);
        }
    }

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Returns the current admin.
     */
    function _getAdmin() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "ERC1967: new admin is the zero address");
        StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     */
    function _changeAdmin(address newAdmin) internal {
        emit AdminChanged(_getAdmin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev The storage slot of the UpgradeableBeacon contract which defines the implementation for this proxy.
     * This is bytes32(uint256(keccak256('eip1967.proxy.beacon')) - 1)) and is validated in the constructor.
     */
    bytes32 internal constant _BEACON_SLOT = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    /**
     * @dev Returns the current beacon.
     */
    function _getBeacon() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        require(AddressUpgradeable.isContract(newBeacon), "ERC1967: new beacon is not a contract");
        require(
            AddressUpgradeable.isContract(IBeaconUpgradeable(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value = newBeacon;
    }

    /**
     * @dev Perform beacon upgrade with additional setup call. Note: This upgrades the address of the beacon, it does
     * not upgrade the implementation contained in the beacon (see {UpgradeableBeacon-_setImplementation} for that).
     *
     * Emits a {BeaconUpgraded} event.
     */
    function _upgradeBeaconToAndCall(address newBeacon, bytes memory data, bool forceCall) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);
        if (data.length > 0 || forceCall) {
            AddressUpgradeable.functionDelegateCall(IBeaconUpgradeable(newBeacon).implementation(), data);
        }
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// File: @openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol


// OpenZeppelin Contracts (last updated v4.9.0) (proxy/utils/UUPSUpgradeable.sol)

pragma solidity ^0.8.0;




/**
 * @dev An upgradeability mechanism designed for UUPS proxies. The functions included here can perform an upgrade of an
 * {ERC1967Proxy}, when this contract is set as the implementation behind such a proxy.
 *
 * A security mechanism ensures that an upgrade does not turn off upgradeability accidentally, although this risk is
 * reinstated if the upgrade retains upgradeability but removes the security mechanism, e.g. by replacing
 * `UUPSUpgradeable` with a custom implementation of upgrades.
 *
 * The {_authorizeUpgrade} function must be overridden to include access restriction to the upgrade mechanism.
 *
 * _Available since v4.1._
 */
abstract contract UUPSUpgradeable is Initializable, IERC1822ProxiableUpgradeable, ERC1967UpgradeUpgradeable {
    function __UUPSUpgradeable_init() internal onlyInitializing {
    }

    function __UUPSUpgradeable_init_unchained() internal onlyInitializing {
    }
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable state-variable-assignment
    address private immutable __self = address(this);

    /**
     * @dev Check that the execution is being performed through a delegatecall call and that the execution context is
     * a proxy contract with an implementation (as defined in ERC1967) pointing to self. This should only be the case
     * for UUPS and transparent proxies that are using the current contract as their implementation. Execution of a
     * function through ERC1167 minimal proxies (clones) would not normally pass this test, but is not guaranteed to
     * fail.
     */
    modifier onlyProxy() {
        require(address(this) != __self, "Function must be called through delegatecall");
        require(_getImplementation() == __self, "Function must be called through active proxy");
        _;
    }

    /**
     * @dev Check that the execution is not being performed through a delegate call. This allows a function to be
     * callable on the implementing contract but not through proxies.
     */
    modifier notDelegated() {
        require(address(this) == __self, "UUPSUpgradeable: must not be called through delegatecall");
        _;
    }

    /**
     * @dev Implementation of the ERC1822 {proxiableUUID} function. This returns the storage slot used by the
     * implementation. It is used to validate the implementation's compatibility when performing an upgrade.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy. This is guaranteed by the `notDelegated` modifier.
     */
    function proxiableUUID() external view virtual override notDelegated returns (bytes32) {
        return _IMPLEMENTATION_SLOT;
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     *
     * @custom:oz-upgrades-unsafe-allow-reachable delegatecall
     */
    function upgradeTo(address newImplementation) public virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, new bytes(0), false);
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`, and subsequently execute the function call
     * encoded in `data`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     *
     * @custom:oz-upgrades-unsafe-allow-reachable delegatecall
     */
    function upgradeToAndCall(address newImplementation, bytes memory data) public payable virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, data, true);
    }

    /**
     * @dev Function that should revert when `msg.sender` is not authorized to upgrade the contract. Called by
     * {upgradeTo} and {upgradeToAndCall}.
     *
     * Normally, this function will use an xref:access.adoc[access control] modifier such as {Ownable-onlyOwner}.
     *
     * ```solidity
     * function _authorizeUpgrade(address) internal override onlyOwner {}
     * ```
     */
    function _authorizeUpgrade(address newImplementation) internal virtual;

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// File: contracts/amm/AmmStorage.sol


pragma solidity 0.8.20;

















//@dev all stored values related to tokens are in 18 decimals.
contract AmmStorage is
    Initializable,
    PausableUpgradeable,
    UUPSUpgradeable,
    IporOwnableUpgradeable,
    IAmmStorage,
    IProxyImplementation,
    IIporContractCommonGov
{
    using IporContractValidator for address;
    using SafeCast for uint256;
    using SafeCast for int256;

    using SoapIndicatorRebalanceLogic for AmmStorageTypes.SoapIndicators;

    int256 private constant INTEREST_THRESHOLD = -1e18;

    address private immutable _iporProtocolRouter;
    address private immutable _ammTreasury;

    uint32 private _lastSwapId;

    /// @dev DEPRECATED in V2
    address public miltonDeprecated;

    /// @dev DEPRECATED in V2
    address public josephDeprecated;

    StorageInternalTypes.Balances internal _balances;
    StorageInternalTypes.SoapIndicatorsStorage internal _soapIndicatorsPayFixed;
    StorageInternalTypes.SoapIndicatorsStorage internal _soapIndicatorsReceiveFixed;
    StorageInternalTypes.SwapContainer internal _swapsPayFixed;
    StorageInternalTypes.SwapContainer internal _swapsReceiveFixed;

    /// @dev DEPRECATED in V2
    mapping(address => uint128) private _liquidityPoolAccountContributionDeprecated;

    mapping(IporTypes.SwapTenor => AmmInternalTypes.OpenSwapList) private _openedSwapsPayFixed;
    mapping(IporTypes.SwapTenor => AmmInternalTypes.OpenSwapList) private _openedSwapsReceiveFixed;

    modifier onlyPauseGuardian() {
        require(PauseManager.isPauseGuardian(msg.sender), IporErrors.CALLER_NOT_GUARDIAN);
        _;
    }

    modifier onlyRouter() {
        require(msg.sender == _iporProtocolRouter, IporErrors.CALLER_NOT_IPOR_PROTOCOL_ROUTER);
        _;
    }

    modifier onlyAmmTreasury() {
        require(msg.sender == _ammTreasury, IporErrors.CALLER_NOT_AMM_TREASURY);
        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(address iporProtocolRouterInput, address ammTreasury) {
        _iporProtocolRouter = iporProtocolRouterInput.checkAddress();
        _ammTreasury = ammTreasury.checkAddress();
        _disableInitializers();
    }

    function initialize() public initializer {
        __Pausable_init();
        __Ownable_init();
        __UUPSUpgradeable_init();
    }

    /// @dev In v1 name of field was quasiHypotheticalInterestCumulative in v2 in that slot is stored hypotheticalInterestCumulative calculated in different way.
    /// In V1 quasiHypotheticalInterestCumulative is a sum of chunks: totalNotional * averageInterestRate * (calculateTimestamp - lastRebalanceTimestamp) * Constants.D18;
    /// stored value is without division by 1e36 * Constants.YEAR_IN_SECONDS - that is why it is called quasi.
    /// In V2 hypotheticalInterestCumulative store sum chunks v2 = value * e^(averageInterestRate * time). This value is not quasi, so we don't need to divide by 1e36 * Constants.YEAR_IN_SECONDS.
    /// After upgrade V1 to V2 code operates on non-quasi value, so we need to divide by 1e36 * Constants.YEAR_IN_SECONDS to achieve current hypothetical interest cumulative from v1.
    /// This value is base value for further calculation including continuous compounding formula in v2.
    function postUpgrade() public onlyOwner {
        _soapIndicatorsPayFixed.hypotheticalInterestCumulative = IporMath.division(
            _soapIndicatorsPayFixed.hypotheticalInterestCumulative,
            1e36 * Constants.YEAR_IN_SECONDS
        );
        _soapIndicatorsReceiveFixed.hypotheticalInterestCumulative = IporMath.division(
            _soapIndicatorsReceiveFixed.hypotheticalInterestCumulative,
            1e36 * Constants.YEAR_IN_SECONDS
        );
    }

    function getVersion() external pure virtual override returns (uint256) {
        return 2_000;
    }

    function getConfiguration() external view override returns (address, address) {
        return (_ammTreasury, _iporProtocolRouter);
    }

    function getLastSwapId() external view override returns (uint256) {
        return _lastSwapId;
    }

    function getLastOpenedSwap(
        IporTypes.SwapTenor tenor,
        uint256 direction
    ) external view override returns (AmmInternalTypes.OpenSwapItem memory) {
        return
            direction == 0
                ? _openedSwapsPayFixed[tenor].swaps[_openedSwapsPayFixed[tenor].headSwapId]
                : _openedSwapsReceiveFixed[tenor].swaps[_openedSwapsReceiveFixed[tenor].headSwapId];
    }

    function getBalance() external view virtual override returns (IporTypes.AmmBalancesMemory memory) {
        return
            IporTypes.AmmBalancesMemory(
                _balances.totalCollateralPayFixed,
                _balances.totalCollateralReceiveFixed,
                _balances.liquidityPool,
                _balances.vault
            );
    }

    function getBalancesForOpenSwap() external view override returns (IporTypes.AmmBalancesForOpenSwapMemory memory) {
        return
            IporTypes.AmmBalancesForOpenSwapMemory({
                totalCollateralPayFixed: _balances.totalCollateralPayFixed,
                totalNotionalPayFixed: _soapIndicatorsPayFixed.totalNotional,
                totalCollateralReceiveFixed: _balances.totalCollateralReceiveFixed,
                totalNotionalReceiveFixed: _soapIndicatorsReceiveFixed.totalNotional,
                liquidityPool: _balances.liquidityPool
            });
    }

    function getExtendedBalance() external view override returns (AmmStorageTypes.ExtendedBalancesMemory memory) {
        return
            AmmStorageTypes.ExtendedBalancesMemory(
                _balances.totalCollateralPayFixed,
                _balances.totalCollateralReceiveFixed,
                _balances.liquidityPool,
                _balances.vault,
                _balances.iporPublicationFee,
                _balances.treasury
            );
    }

    function getSwap(
        AmmTypes.SwapDirection direction,
        uint256 swapId
    ) external view override returns (AmmTypes.Swap memory) {
        uint32 id = swapId.toUint32();
        StorageInternalTypes.Swap storage swap;

        if (direction == AmmTypes.SwapDirection.PAY_FIXED_RECEIVE_FLOATING) {
            swap = _swapsPayFixed.swaps[id];
        } else if (direction == AmmTypes.SwapDirection.PAY_FLOATING_RECEIVE_FIXED) {
            swap = _swapsReceiveFixed.swaps[id];
        } else {
            revert(AmmErrors.UNSUPPORTED_DIRECTION);
        }

        return
            AmmTypes.Swap(
                swap.id,
                swap.buyer,
                swap.openTimestamp,
                swap.tenor,
                swap.idsIndex,
                swap.collateral,
                swap.notional,
                swap.ibtQuantity,
                swap.fixedInterestRate,
                uint256(swap.liquidationDepositAmount) * 1e18,
                swap.state
            );
    }

    function getSwapsPayFixed(
        address account,
        uint256 offset,
        uint256 chunkSize
    ) external view override returns (uint256 totalCount, AmmTypes.Swap[] memory swaps) {
        uint32[] storage ids = _swapsPayFixed.ids[account];
        return (ids.length, _getPositions(_swapsPayFixed.swaps, ids, offset, chunkSize));
    }

    function getSwapsReceiveFixed(
        address account,
        uint256 offset,
        uint256 chunkSize
    ) external view override returns (uint256 totalCount, AmmTypes.Swap[] memory swaps) {
        uint32[] storage ids = _swapsReceiveFixed.ids[account];
        return (ids.length, _getPositions(_swapsReceiveFixed.swaps, ids, offset, chunkSize));
    }

    function getSwapIds(
        address account,
        uint256 offset,
        uint256 chunkSize
    ) external view override returns (uint256 totalCount, AmmStorageTypes.IporSwapId[] memory ids) {
        require(chunkSize > 0, IporErrors.CHUNK_SIZE_EQUAL_ZERO);
        require(chunkSize <= Constants.MAX_CHUNK_SIZE, IporErrors.CHUNK_SIZE_TOO_BIG);

        uint32[] storage payFixedIdsRef = _swapsPayFixed.ids[account];
        uint256 payFixedLength = payFixedIdsRef.length;

        uint32[] storage receiveFixedIdsRef = _swapsReceiveFixed.ids[account];
        uint256 receiveFixedLength = receiveFixedIdsRef.length;

        totalCount = payFixedLength + receiveFixedLength;

        uint256 resultSetSize = PaginationUtils.resolveResultSetSize(totalCount, offset, chunkSize);

        ids = new AmmStorageTypes.IporSwapId[](resultSetSize);

        for (uint256 i; i != resultSetSize; ) {
            if (offset + i < payFixedLength) {
                ids[i] = AmmStorageTypes.IporSwapId(payFixedIdsRef[offset + i], 0);
            } else {
                ids[i] = AmmStorageTypes.IporSwapId(receiveFixedIdsRef[offset + i - payFixedLength], 1);
            }
            unchecked {
                ++i;
            }
        }
    }

    function addLiquidityInternal(
        address account,
        uint256 assetAmount,
        uint256 cfgMaxLiquidityPoolBalance
    ) external override onlyRouter {
        require(assetAmount > 0, AmmErrors.DEPOSIT_AMOUNT_IS_TOO_LOW);

        uint128 newLiquidityPoolBalance = _balances.liquidityPool + assetAmount.toUint128();
        require(newLiquidityPoolBalance <= cfgMaxLiquidityPoolBalance, AmmErrors.LIQUIDITY_POOL_BALANCE_IS_TOO_HIGH);

        _balances.liquidityPool = newLiquidityPoolBalance;
    }

    function subtractLiquidityInternal(uint256 assetAmount) external override onlyRouter {
        _balances.liquidityPool = _balances.liquidityPool - assetAmount.toUint128();
    }

    function updateStorageWhenOpenSwapPayFixedInternal(
        AmmTypes.NewSwap memory newSwap,
        uint256 cfgIporPublicationFee
    ) external override onlyRouter returns (uint256) {
        uint256 id = _updateSwapsWhenOpen(AmmTypes.SwapDirection.PAY_FIXED_RECEIVE_FLOATING, newSwap);
        _updateBalancesWhenOpenSwapPayFixed(
            newSwap.collateral,
            newSwap.openingFeeLPAmount,
            newSwap.openingFeeTreasuryAmount,
            cfgIporPublicationFee
        );

        _updateSoapIndicatorsWhenOpenSwapPayFixed(
            newSwap.openTimestamp,
            newSwap.notional,
            newSwap.fixedInterestRate,
            newSwap.ibtQuantity
        );
        _updateOpenedSwapWhenOpenPayFixed(newSwap.tenor, id, newSwap.openTimestamp);
        return id;
    }

    function updateStorageWhenOpenSwapReceiveFixedInternal(
        AmmTypes.NewSwap memory newSwap,
        uint256 cfgIporPublicationFee
    ) external override onlyRouter returns (uint256) {
        uint256 id = _updateSwapsWhenOpen(AmmTypes.SwapDirection.PAY_FLOATING_RECEIVE_FIXED, newSwap);
        _updateBalancesWhenOpenSwapReceiveFixed(
            newSwap.collateral,
            newSwap.openingFeeLPAmount,
            newSwap.openingFeeTreasuryAmount,
            cfgIporPublicationFee
        );
        _updateSoapIndicatorsWhenOpenSwapReceiveFixed(
            newSwap.openTimestamp,
            newSwap.notional,
            newSwap.fixedInterestRate,
            newSwap.ibtQuantity
        );
        _updateOpenedSwapWhenOpenReceiveFixed(newSwap.tenor, id, newSwap.openTimestamp);
        return id;
    }

    function updateStorageWhenCloseSwapPayFixedInternal(
        AmmTypes.Swap memory swap,
        int256 pnlValue,
        uint256 swapUnwindFeeLPAmount,
        uint256 swapUnwindFeeTreasuryAmount,
        uint256 closingTimestamp
    ) external override onlyRouter returns (AmmInternalTypes.OpenSwapItem memory closedSwap) {
        _updateSwapsWhenClosePayFixed(swap);
        _updateBalancesWhenCloseSwapPayFixed(swap, pnlValue, swapUnwindFeeLPAmount, swapUnwindFeeTreasuryAmount);
        _updateSoapIndicatorsWhenCloseSwapPayFixed(swap, closingTimestamp);
        return _updateOpenedSwapWhenClosePayFixed(swap.tenor, swap.id);
    }

    function updateStorageWhenCloseSwapReceiveFixedInternal(
        AmmTypes.Swap memory swap,
        int256 pnlValue,
        uint256 swapUnwindFeeLPAmount,
        uint256 swapUnwindFeeTreasuryAmount,
        uint256 closingTimestamp
    ) external override onlyRouter returns (AmmInternalTypes.OpenSwapItem memory closedSwap) {
        _updateSwapsWhenCloseReceiveFixed(swap);
        _updateBalancesWhenCloseSwapReceiveFixed(swap, pnlValue, swapUnwindFeeLPAmount, swapUnwindFeeTreasuryAmount);
        _updateSoapIndicatorsWhenCloseSwapReceiveFixed(swap, closingTimestamp);
        return _updateOpenedSwapWhenCloseReceiveFixed(swap.tenor, swap.id);
    }

    /// @dev vaultBalance is the balance of the vault after the withdraw
    function updateStorageWhenWithdrawFromAssetManagement(
        uint256 withdrawnAmount,
        uint256 vaultBalance
    ) external override onlyAmmTreasury {
        uint256 currentVaultBalance = _balances.vault;
        uint256 currentLiquidityPoolBalance = _balances.liquidityPool;

        int256 interest = (vaultBalance + withdrawnAmount).toInt256() - currentVaultBalance.toInt256();

        _updateStorageWhenInteractionWithAssetManagement(currentLiquidityPoolBalance, vaultBalance, interest);
    }

    function updateStorageWhenDepositToAssetManagement(
        uint256 depositAmount,
        uint256 vaultBalance
    ) external override onlyAmmTreasury {
        /// @dev vaultBalance is the balance of the vault after the deposit depositAmount, so should always be vaultBalance >= depositAmount
        require(vaultBalance >= depositAmount, AmmErrors.VAULT_BALANCE_LOWER_THAN_DEPOSIT_VALUE);

        uint256 currentVaultBalance = _balances.vault;
        uint256 currentLiquidityPoolBalance = _balances.liquidityPool;

        int256 interest = (vaultBalance - depositAmount).toInt256() - currentVaultBalance.toInt256();

        _updateStorageWhenInteractionWithAssetManagement(currentLiquidityPoolBalance, vaultBalance, interest);
    }

    function updateStorageWhenTransferToCharlieTreasuryInternal(
        uint256 transferredAmount
    ) external override onlyRouter {
        require(transferredAmount > 0, IporErrors.NOT_ENOUGH_AMOUNT_TO_TRANSFER);

        uint256 balance = _balances.iporPublicationFee;

        require(transferredAmount <= balance, AmmErrors.PUBLICATION_FEE_BALANCE_IS_TOO_LOW);

        balance = balance - transferredAmount;

        _balances.iporPublicationFee = balance.toUint128();
    }

    function updateStorageWhenTransferToTreasuryInternal(uint256 transferredAmount) external override onlyRouter {
        require(transferredAmount > 0, IporErrors.NOT_ENOUGH_AMOUNT_TO_TRANSFER);

        uint256 balance = _balances.treasury;

        require(transferredAmount <= balance, AmmErrors.TREASURY_BALANCE_IS_TOO_LOW);

        balance = balance - transferredAmount;

        _balances.treasury = balance.toUint128();
    }

    function pause() external override onlyPauseGuardian {
        _pause();
    }

    function unpause() external override onlyOwner {
        _unpause();
    }

    function isPauseGuardian(address account) external view override returns (bool) {
        return PauseManager.isPauseGuardian(account);
    }

    function addPauseGuardians(address[] calldata guardians) external override onlyOwner {
        PauseManager.addPauseGuardians(guardians);
    }

    function removePauseGuardians(address[] calldata guardians) external override onlyOwner {
        PauseManager.removePauseGuardians(guardians);
    }

    function getImplementation() external view override returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    function getSoapIndicators()
        external
        view
        returns (
            AmmStorageTypes.SoapIndicators memory indicatorsPayFixed,
            AmmStorageTypes.SoapIndicators memory indicatorsReceiveFixed
        )
    {
        StorageInternalTypes.SoapIndicatorsStorage memory soapIndicatorsPayFixed = _soapIndicatorsPayFixed;
        StorageInternalTypes.SoapIndicatorsStorage memory soapIndicatorsReceiveFixed = _soapIndicatorsReceiveFixed;

        indicatorsPayFixed = AmmStorageTypes.SoapIndicators({
            hypotheticalInterestCumulative: soapIndicatorsPayFixed.hypotheticalInterestCumulative,
            totalNotional: soapIndicatorsPayFixed.totalNotional,
            totalIbtQuantity: soapIndicatorsPayFixed.totalIbtQuantity,
            averageInterestRate: soapIndicatorsPayFixed.averageInterestRate,
            rebalanceTimestamp: soapIndicatorsPayFixed.rebalanceTimestamp
        });

        indicatorsReceiveFixed = AmmStorageTypes.SoapIndicators({
            hypotheticalInterestCumulative: soapIndicatorsReceiveFixed.hypotheticalInterestCumulative,
            totalNotional: soapIndicatorsReceiveFixed.totalNotional,
            totalIbtQuantity: soapIndicatorsReceiveFixed.totalIbtQuantity,
            averageInterestRate: soapIndicatorsReceiveFixed.averageInterestRate,
            rebalanceTimestamp: soapIndicatorsReceiveFixed.rebalanceTimestamp
        });
    }

    function _updateStorageWhenInteractionWithAssetManagement(
        uint256 ammLiquidityPoolBalance,
        uint256 vaultBalance,
        int256 interest
    ) internal {
        /// @dev allow to have negative interest but not lower than INTEREST_THRESHOLD
        require(interest >= INTEREST_THRESHOLD, AmmErrors.INTEREST_FROM_STRATEGY_EXCEEDED_THRESHOLD);
        require(ammLiquidityPoolBalance.toInt256() >= -interest, AmmErrors.LIQUIDITY_POOL_AMOUNT_TOO_LOW);

        ammLiquidityPoolBalance = (ammLiquidityPoolBalance.toInt256() + interest).toUint256();

        _balances.liquidityPool = ammLiquidityPoolBalance.toUint128();
        _balances.vault = vaultBalance.toUint128();
    }

    function _getPositions(
        mapping(uint32 => StorageInternalTypes.Swap) storage swaps,
        uint32[] storage ids,
        uint256 offset,
        uint256 chunkSize
    ) internal view returns (AmmTypes.Swap[] memory) {
        require(chunkSize > 0, IporErrors.CHUNK_SIZE_EQUAL_ZERO);
        require(chunkSize <= Constants.MAX_CHUNK_SIZE, IporErrors.CHUNK_SIZE_TOO_BIG);

        uint256 swapsIdsLength = PaginationUtils.resolveResultSetSize(ids.length, offset, chunkSize);
        AmmTypes.Swap[] memory derivatives = new AmmTypes.Swap[](swapsIdsLength);

        uint32 id;

        for (uint256 i; i != swapsIdsLength; ) {
            id = ids[i + offset];
            StorageInternalTypes.Swap storage swap = swaps[id];
            derivatives[i] = AmmTypes.Swap(
                swap.id,
                swap.buyer,
                swap.openTimestamp,
                swap.tenor,
                swap.idsIndex,
                swap.collateral,
                swap.notional,
                swap.ibtQuantity,
                swap.fixedInterestRate,
                uint256(swap.liquidationDepositAmount) * 1e18,
                swaps[id].state
            );
            unchecked {
                ++i;
            }
        }
        return derivatives;
    }

    function _updateBalancesWhenOpenSwapPayFixed(
        uint256 collateral,
        uint256 openingFeeLPAmount,
        uint256 openingFeeTreasuryAmount,
        uint256 cfgIporPublicationFee
    ) internal {
        _balances.totalCollateralPayFixed = _balances.totalCollateralPayFixed + collateral.toUint128();

        _balances.iporPublicationFee = _balances.iporPublicationFee + cfgIporPublicationFee.toUint128();

        _balances.liquidityPool = _balances.liquidityPool + openingFeeLPAmount.toUint128();
        _balances.treasury = _balances.treasury + openingFeeTreasuryAmount.toUint128();
    }

    function _updateBalancesWhenOpenSwapReceiveFixed(
        uint256 collateral,
        uint256 openingFeeLPAmount,
        uint256 openingFeeTreasuryAmount,
        uint256 cfgIporPublicationFee
    ) internal {
        _balances.totalCollateralReceiveFixed = _balances.totalCollateralReceiveFixed + collateral.toUint128();

        _balances.iporPublicationFee = _balances.iporPublicationFee + cfgIporPublicationFee.toUint128();

        _balances.liquidityPool = _balances.liquidityPool + openingFeeLPAmount.toUint128();
        _balances.treasury = _balances.treasury + openingFeeTreasuryAmount.toUint128();
    }

    function _updateBalancesWhenCloseSwapPayFixed(
        AmmTypes.Swap memory swap,
        int256 pnlValue,
        uint256 swapUnwindFeeLPAmount,
        uint256 swapUnwindFeeTreasuryAmount
    ) internal {
        _updateBalancesWhenCloseSwap(pnlValue, swapUnwindFeeLPAmount, swapUnwindFeeTreasuryAmount);
        _balances.totalCollateralPayFixed = _balances.totalCollateralPayFixed - swap.collateral.toUint128();
    }

    function _updateBalancesWhenCloseSwapReceiveFixed(
        AmmTypes.Swap memory swap,
        int256 pnlValue,
        uint256 swapUnwindFeeLPAmount,
        uint256 swapUnwindFeeTreasuryAmount
    ) internal {
        _updateBalancesWhenCloseSwap(pnlValue, swapUnwindFeeLPAmount, swapUnwindFeeTreasuryAmount);
        _balances.totalCollateralReceiveFixed = _balances.totalCollateralReceiveFixed - swap.collateral.toUint128();
    }

    function _updateBalancesWhenCloseSwap(
        int256 pnlValue,
        uint256 swapUnwindFeeLPAmount,
        uint256 swapUnwindFeeTreasuryAmount
    ) internal {
        uint256 absPnlValue = IporMath.absoluteValue(pnlValue);

        if (pnlValue > 0) {
            /// @dev Buyer earns, AMM (LP) looses
            require(_balances.liquidityPool >= absPnlValue, AmmErrors.CANNOT_CLOSE_SWAP_LP_IS_TOO_LOW);
            /// @dev When AMM (LP) looses, then  always substract all pnlValue
            _balances.liquidityPool =
                _balances.liquidityPool -
                absPnlValue.toUint128() +
                swapUnwindFeeLPAmount.toUint128();
        } else {
            /// @dev AMM earns, Buyer looses,
            _balances.liquidityPool =
                _balances.liquidityPool +
                absPnlValue.toUint128() +
                swapUnwindFeeLPAmount.toUint128();
        }
        _balances.treasury = _balances.treasury + swapUnwindFeeTreasuryAmount.toUint128();
    }

    function _updateSwapsWhenOpen(
        AmmTypes.SwapDirection direction,
        AmmTypes.NewSwap memory newSwap
    ) internal returns (uint256) {
        _lastSwapId++;
        uint32 id = _lastSwapId;

        StorageInternalTypes.Swap storage swap;
        uint32 idsIndexLocal;

        if (direction == AmmTypes.SwapDirection.PAY_FIXED_RECEIVE_FLOATING) {
            swap = _swapsPayFixed.swaps[id];
            idsIndexLocal = _swapsPayFixed.ids[newSwap.buyer].length.toUint32();
        } else if (direction == AmmTypes.SwapDirection.PAY_FLOATING_RECEIVE_FIXED) {
            swap = _swapsReceiveFixed.swaps[id];
            idsIndexLocal = _swapsReceiveFixed.ids[newSwap.buyer].length.toUint32();
        } else {
            revert(AmmErrors.UNSUPPORTED_DIRECTION);
        }

        swap.id = id;
        swap.buyer = newSwap.buyer;
        swap.openTimestamp = newSwap.openTimestamp.toUint32();
        swap.idsIndex = idsIndexLocal;
        swap.collateral = newSwap.collateral.toUint128();
        swap.notional = newSwap.notional.toUint128();
        swap.ibtQuantity = newSwap.ibtQuantity.toUint128();
        swap.fixedInterestRate = newSwap.fixedInterestRate.toUint64();
        swap.liquidationDepositAmount = newSwap.liquidationDepositAmount.toUint32();
        swap.state = IporTypes.SwapState.ACTIVE;
        swap.tenor = newSwap.tenor;

        if (direction == AmmTypes.SwapDirection.PAY_FIXED_RECEIVE_FLOATING) {
            _swapsPayFixed.ids[newSwap.buyer].push(id);
        } else if (direction == AmmTypes.SwapDirection.PAY_FLOATING_RECEIVE_FIXED) {
            _swapsReceiveFixed.ids[newSwap.buyer].push(id);
        } else {
            revert(AmmErrors.UNSUPPORTED_DIRECTION);
        }

        _lastSwapId = id;

        return id;
    }

    function _updateSwapsWhenClosePayFixed(AmmTypes.Swap memory swap) internal {
        require(swap.id > 0, AmmErrors.INCORRECT_SWAP_ID);
        require(swap.state != IporTypes.SwapState.INACTIVE, AmmErrors.INCORRECT_SWAP_STATUS);

        uint32 idsIndexToDelete = swap.idsIndex.toUint32();
        address buyer = swap.buyer;
        uint256 idsLength = _swapsPayFixed.ids[buyer].length - 1;
        if (idsIndexToDelete < idsLength) {
            uint32 accountDerivativeIdToMove = _swapsPayFixed.ids[buyer][idsLength];

            _swapsPayFixed.swaps[accountDerivativeIdToMove].idsIndex = idsIndexToDelete;

            _swapsPayFixed.ids[buyer][idsIndexToDelete] = accountDerivativeIdToMove;
        }

        _swapsPayFixed.swaps[swap.id.toUint32()].state = IporTypes.SwapState.INACTIVE;
        _swapsPayFixed.ids[buyer].pop();
    }

    function _updateSwapsWhenCloseReceiveFixed(AmmTypes.Swap memory swap) internal {
        require(swap.id > 0, AmmErrors.INCORRECT_SWAP_ID);
        require(swap.state != IporTypes.SwapState.INACTIVE, AmmErrors.INCORRECT_SWAP_STATUS);

        uint32 idsIndexToDelete = swap.idsIndex.toUint32();
        address buyer = swap.buyer;
        uint256 idsLength = _swapsReceiveFixed.ids[buyer].length - 1;

        if (idsIndexToDelete < idsLength) {
            uint32 accountDerivativeIdToMove = _swapsReceiveFixed.ids[buyer][idsLength];

            _swapsReceiveFixed.swaps[accountDerivativeIdToMove].idsIndex = idsIndexToDelete;

            _swapsReceiveFixed.ids[buyer][idsIndexToDelete] = accountDerivativeIdToMove;
        }

        _swapsReceiveFixed.swaps[swap.id.toUint32()].state = IporTypes.SwapState.INACTIVE;
        _swapsReceiveFixed.ids[buyer].pop();
    }

    function _updateSoapIndicatorsWhenOpenSwapPayFixed(
        uint256 openTimestamp,
        uint256 swapNotional,
        uint256 fixedInterestRate,
        uint256 ibtQuantity
    ) internal {
        AmmStorageTypes.SoapIndicators memory pf = AmmStorageTypes.SoapIndicators(
            _soapIndicatorsPayFixed.hypotheticalInterestCumulative,
            _soapIndicatorsPayFixed.totalNotional,
            _soapIndicatorsPayFixed.totalIbtQuantity,
            _soapIndicatorsPayFixed.averageInterestRate,
            _soapIndicatorsPayFixed.rebalanceTimestamp
        );

        pf = pf.rebalanceWhenOpenSwap(openTimestamp, swapNotional, fixedInterestRate, ibtQuantity);

        _soapIndicatorsPayFixed.rebalanceTimestamp = pf.rebalanceTimestamp.toUint32();
        _soapIndicatorsPayFixed.totalNotional = pf.totalNotional.toUint128();
        _soapIndicatorsPayFixed.averageInterestRate = pf.averageInterestRate.toUint64();
        _soapIndicatorsPayFixed.totalIbtQuantity = pf.totalIbtQuantity.toUint128();
        _soapIndicatorsPayFixed.hypotheticalInterestCumulative = pf.hypotheticalInterestCumulative;
    }

    function _updateSoapIndicatorsWhenOpenSwapReceiveFixed(
        uint256 openTimestamp,
        uint256 swapNotional,
        uint256 fixedInterestRate,
        uint256 ibtQuantity
    ) internal {
        AmmStorageTypes.SoapIndicators memory rf = AmmStorageTypes.SoapIndicators(
            _soapIndicatorsReceiveFixed.hypotheticalInterestCumulative,
            _soapIndicatorsReceiveFixed.totalNotional,
            _soapIndicatorsReceiveFixed.totalIbtQuantity,
            _soapIndicatorsReceiveFixed.averageInterestRate,
            _soapIndicatorsReceiveFixed.rebalanceTimestamp
        );
        rf = rf.rebalanceWhenOpenSwap(openTimestamp, swapNotional, fixedInterestRate, ibtQuantity);

        _soapIndicatorsReceiveFixed.rebalanceTimestamp = rf.rebalanceTimestamp.toUint32();
        _soapIndicatorsReceiveFixed.totalNotional = rf.totalNotional.toUint128();
        _soapIndicatorsReceiveFixed.averageInterestRate = rf.averageInterestRate.toUint64();
        _soapIndicatorsReceiveFixed.totalIbtQuantity = rf.totalIbtQuantity.toUint128();
        _soapIndicatorsReceiveFixed.hypotheticalInterestCumulative = rf.hypotheticalInterestCumulative;
    }

    function _updateSoapIndicatorsWhenCloseSwapPayFixed(AmmTypes.Swap memory swap, uint256 closingTimestamp) internal {
        AmmStorageTypes.SoapIndicators memory pf = AmmStorageTypes.SoapIndicators(
            _soapIndicatorsPayFixed.hypotheticalInterestCumulative,
            _soapIndicatorsPayFixed.totalNotional,
            _soapIndicatorsPayFixed.totalIbtQuantity,
            _soapIndicatorsPayFixed.averageInterestRate,
            _soapIndicatorsPayFixed.rebalanceTimestamp
        );

        pf = pf.rebalanceWhenCloseSwap(
            closingTimestamp,
            swap.openTimestamp,
            swap.notional,
            swap.fixedInterestRate,
            swap.ibtQuantity
        );

        _soapIndicatorsPayFixed = StorageInternalTypes.SoapIndicatorsStorage(
            pf.hypotheticalInterestCumulative,
            pf.totalNotional.toUint128(),
            pf.totalIbtQuantity.toUint128(),
            pf.averageInterestRate.toUint64(),
            pf.rebalanceTimestamp.toUint32()
        );
    }

    function _updateSoapIndicatorsWhenCloseSwapReceiveFixed(
        AmmTypes.Swap memory swap,
        uint256 closingTimestamp
    ) internal {
        AmmStorageTypes.SoapIndicators memory rf = AmmStorageTypes.SoapIndicators(
            _soapIndicatorsReceiveFixed.hypotheticalInterestCumulative,
            _soapIndicatorsReceiveFixed.totalNotional,
            _soapIndicatorsReceiveFixed.totalIbtQuantity,
            _soapIndicatorsReceiveFixed.averageInterestRate,
            _soapIndicatorsReceiveFixed.rebalanceTimestamp
        );

        rf = rf.rebalanceWhenCloseSwap(
            closingTimestamp,
            swap.openTimestamp,
            swap.notional,
            swap.fixedInterestRate,
            swap.ibtQuantity
        );

        _soapIndicatorsReceiveFixed = StorageInternalTypes.SoapIndicatorsStorage(
            rf.hypotheticalInterestCumulative,
            rf.totalNotional.toUint128(),
            rf.totalIbtQuantity.toUint128(),
            rf.averageInterestRate.toUint64(),
            rf.rebalanceTimestamp.toUint32()
        );
    }

    function _updateOpenedSwapWhenOpenPayFixed(
        IporTypes.SwapTenor tenor,
        uint256 swapId,
        uint256 openTimestamp
    ) internal {
        uint32 headSwapId = _openedSwapsPayFixed[tenor].headSwapId;
        _openedSwapsPayFixed[tenor].swaps[swapId.toUint32()] = AmmInternalTypes.OpenSwapItem(
            swapId.toUint32(),
            0,
            headSwapId,
            openTimestamp.toUint32()
        );
        _openedSwapsPayFixed[tenor].headSwapId = swapId.toUint32();
        _openedSwapsPayFixed[tenor].swaps[headSwapId].nextSwapId = swapId.toUint32();
    }

    function _updateOpenedSwapWhenClosePayFixed(
        IporTypes.SwapTenor tenor,
        uint256 swapId
    ) internal returns (AmmInternalTypes.OpenSwapItem memory closedSwap) {
        uint32 headSwapId = _openedSwapsPayFixed[tenor].headSwapId;
        AmmInternalTypes.OpenSwapItem memory swap = _openedSwapsPayFixed[tenor].swaps[swapId.toUint32()];
        if (swap.openSwapTimestamp == 0) {
            return swap;
        }
        if (swapId.toUint32() == headSwapId) {
            AmmInternalTypes.OpenSwapItem memory swapPrev = _openedSwapsPayFixed[tenor].swaps[swap.previousSwapId];
            swapPrev.nextSwapId = 0;
            _openedSwapsPayFixed[tenor].headSwapId = swapPrev.swapId;
            _openedSwapsPayFixed[tenor].swaps[swapPrev.swapId] = swapPrev;
            delete _openedSwapsPayFixed[tenor].swaps[swapId.toUint32()];
        } else {
            AmmInternalTypes.OpenSwapItem memory swapPrev = _openedSwapsPayFixed[tenor].swaps[swap.previousSwapId];
            AmmInternalTypes.OpenSwapItem memory swapNext = _openedSwapsPayFixed[tenor].swaps[swap.nextSwapId];
            swapPrev.nextSwapId = swapNext.swapId;
            swapNext.previousSwapId = swapPrev.swapId;
            _openedSwapsPayFixed[tenor].swaps[swap.previousSwapId] = swapPrev;
            _openedSwapsPayFixed[tenor].swaps[swap.nextSwapId] = swapNext;
            delete _openedSwapsPayFixed[tenor].swaps[swapId.toUint32()];
        }
        return swap;
    }

    function _updateOpenedSwapWhenOpenReceiveFixed(
        IporTypes.SwapTenor tenor,
        uint256 swapId,
        uint256 openTimestamp
    ) internal {
        uint32 headSwapId = _openedSwapsReceiveFixed[tenor].headSwapId;
        _openedSwapsReceiveFixed[tenor].swaps[swapId.toUint32()] = AmmInternalTypes.OpenSwapItem(
            swapId.toUint32(),
            0,
            headSwapId,
            openTimestamp.toUint32()
        );
        _openedSwapsReceiveFixed[tenor].headSwapId = swapId.toUint32();
        _openedSwapsReceiveFixed[tenor].swaps[headSwapId].nextSwapId = swapId.toUint32();
    }

    function _updateOpenedSwapWhenCloseReceiveFixed(
        IporTypes.SwapTenor tenor,
        uint256 swapId
    ) internal returns (AmmInternalTypes.OpenSwapItem memory closedSwap) {
        uint32 headSwapId = _openedSwapsReceiveFixed[tenor].headSwapId;
        AmmInternalTypes.OpenSwapItem memory swap = _openedSwapsReceiveFixed[tenor].swaps[swapId.toUint32()];
        if (swap.openSwapTimestamp == 0) {
            return swap;
        }
        if (swapId.toUint32() == headSwapId) {
            AmmInternalTypes.OpenSwapItem memory swapPrev = _openedSwapsReceiveFixed[tenor].swaps[swap.previousSwapId];
            swapPrev.nextSwapId = 0;
            _openedSwapsReceiveFixed[tenor].headSwapId = swapPrev.swapId;
            _openedSwapsReceiveFixed[tenor].swaps[swapPrev.swapId] = swapPrev;
            delete _openedSwapsReceiveFixed[tenor].swaps[swapId.toUint32()];
        } else {
            AmmInternalTypes.OpenSwapItem memory swapPrev = _openedSwapsReceiveFixed[tenor].swaps[swap.previousSwapId];
            AmmInternalTypes.OpenSwapItem memory swapNext = _openedSwapsReceiveFixed[tenor].swaps[swap.nextSwapId];
            swapPrev.nextSwapId = swapNext.swapId;
            swapNext.previousSwapId = swapPrev.swapId;
            _openedSwapsReceiveFixed[tenor].swaps[swap.previousSwapId] = swapPrev;
            _openedSwapsReceiveFixed[tenor].swaps[swap.nextSwapId] = swapNext;
            delete _openedSwapsReceiveFixed[tenor].swaps[swapId.toUint32()];
        }
        return swap;
    }

    //solhint-disable no-empty-blocks
    function _authorizeUpgrade(address) internal override onlyOwner {}
}