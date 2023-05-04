// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

library Epochs {
  uint256 internal constant EPOCH_SECONDS = 7 days;

  /**
   * @notice Get the epoch containing the timestamp `s`
   * @param s the timestamp
   * @return corresponding epoch
   */
  function fromSeconds(uint256 s) internal pure returns (uint256) {
    return s / EPOCH_SECONDS;
  }

  /**
   * @notice Get the current epoch for the block.timestamp
   * @return current epoch
   */
  function current() internal view returns (uint256) {
    return fromSeconds(block.timestamp);
  }

  /**
   * @notice Get the start timestamp for the current epoch
   * @return current epoch start timestamp
   */
  function currentEpochStartTimestamp() internal view returns (uint256) {
    return startOf(current());
  }

  /**
   * @notice Get the previous epoch given block.timestamp
   * @return previous epoch
   */
  function previous() internal view returns (uint256) {
    return current() - 1;
  }

  /**
   * @notice Get the next epoch given block.timestamp
   * @return next epoch
   */
  function next() internal view returns (uint256) {
    return current() + 1;
  }

  /**
   * @notice Get the Unix timestamp of the start of `epoch`
   * @param epoch the epoch
   * @return unix timestamp
   */
  function startOf(uint256 epoch) internal pure returns (uint256) {
    return epoch * EPOCH_SECONDS;
  }
}