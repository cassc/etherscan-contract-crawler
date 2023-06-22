// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.9;

/**
 * @title PreciseUnitMath
 * @author Synthereum Protocol
 *
 * Arithmetic for fixed-point numbers with 18 decimals of precision.
 *
 */
library PreciseUnitMath {
  // The number One in precise units.
  uint256 internal constant PRECISE_UNIT = 10**18;

  // The number One in precise units multiplied for 10^18.
  uint256 internal constant DOUBLE_PRECISE_UNIT = 10**36;

  // Max unsigned integer value
  uint256 internal constant MAX_UINT_256 = type(uint256).max;

  /**
   * @dev Getter function since constants can't be read directly from libraries.
   */
  function preciseUnit() internal pure returns (uint256) {
    return PRECISE_UNIT;
  }

  /**
   * @dev Getter function since constants can't be read directly from libraries.
   */
  function maxUint256() internal pure returns (uint256) {
    return MAX_UINT_256;
  }

  /**
   * @dev Multiplies value a by value b (result is rounded down). It's assumed that the value b is the significand
   * of a number with 18 decimals precision.
   */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    return (a * b) / PRECISE_UNIT;
  }

  /**
   * @dev Multiplies value a by value b (result is rounded up). It's assumed that the value b is the significand
   * of a number with 18 decimals precision.
   */
  function mulCeil(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0 || b == 0) {
      return 0;
    }
    return (((a * b) - 1) / PRECISE_UNIT) + 1;
  }

  /**
   * @dev Divides value a by value b (result is rounded down).
   */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    return (a * PRECISE_UNIT) / b;
  }

  /**
   * @dev Divides value a by value b (result is rounded up or away from 0).
   */
  function divCeil(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0, 'Cant divide by 0');

    return a > 0 ? (((a * PRECISE_UNIT) - 1) / b) + 1 : 0;
  }

  /**
   * @dev Performs the power on a specified value, reverts on overflow.
   */
  function safePower(uint256 a, uint256 pow) internal pure returns (uint256) {
    require(a > 0, 'Value must be positive');

    uint256 result = 1;
    for (uint256 i = 0; i < pow; i++) {
      uint256 previousResult = result;

      result = previousResult * a;
    }

    return result;
  }

  /**
   * @dev The minimum of `a` and `b`.
   */
  function min(uint256 a, uint256 b) internal pure returns (uint256) {
    return a < b ? a : b;
  }

  /**
   * @dev The maximum of `a` and `b`.
   */
  function max(uint256 a, uint256 b) internal pure returns (uint256) {
    return a > b ? a : b;
  }
}