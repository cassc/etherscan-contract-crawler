pragma solidity ^0.5.0;

/**
 * @title Calculates the square root of a given value.
 * @dev Results may be off by 1.
 */
library Sqrt {
  /// @notice The max possible value
  uint private constant MAX_UINT = 2**256 - 1;

  // Source: https://github.com/ethereum/dapp-bin/pull/50
  function sqrt(uint x) internal pure returns (uint y) {
    if (x == 0) {
      return 0;
    } else if (x <= 3) {
      return 1;
    } else if (x == MAX_UINT) {
      // Without this we fail on x + 1 below
      return 2**128 - 1;
    }

    uint z = (x + 1) / 2;
    y = x;
    while (z < y) {
      y = z;
      z = (x / z + z) / 2;
    }
  }
}