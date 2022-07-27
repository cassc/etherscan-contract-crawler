// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

/**
 * @dev Library for using a uint256 as a bitmap, effectively an extremely gas efficient uint8 to bool mapping.
 */
library BitMap {
  /// @notice Either sets a bit in a bitmap to on or off
  /// @param bitmap the bitmap being set
  /// @param bit which bit is being set
  /// @param status whether the bit is being set to on or off
  function setBit(
    uint256 bitmap,
    uint8 bit,
    bool status
  ) internal pure returns (uint256 updatedBitmap) {
    if (status) {
      return bitmap | (1 << bit);
    } else {
      return bitmap & (~(1 << bit));
    }
  }


  /// @notice Sets several bits at once
  /// @param bitmap the bitmap being set
  /// @param bits which bets are being set
  function setBits(
    uint256 bitmap,
    uint8[] memory bits
  ) internal pure returns (uint256 updatedBitmap) {
    uint256 _bitmap = bitmap;
    for (uint256 i = 0; i < bits.length; i++) {
      _bitmap = setBit(_bitmap, bits[i], true);
    }
    updatedBitmap = _bitmap;
  }

  /// @notice Checks whether a bit in a bitmap is on or off
  /// @param bitmap the bitmap being checked
  /// @param bit which bit is being checked
  function checkBit(uint256 bitmap, uint8 bit)
    internal
    pure
    returns (bool status)
  {
    return (bitmap & (1 << bit)) != 0;
  }
}