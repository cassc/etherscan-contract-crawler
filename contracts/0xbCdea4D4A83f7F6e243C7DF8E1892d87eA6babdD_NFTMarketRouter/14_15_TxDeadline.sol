// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.12;

import "../../libraries/TimeLibrary.sol";

error TxDeadline_Tx_Deadline_Expired();

/**
 * @title A mixin that provides a modifier to check that a transaction deadline has not expired.
 * @author HardlyDifficult
 */
abstract contract TxDeadline {
  using TimeLibrary for uint256;

  /// @notice Requires the deadline provided is 0, now, or in the future.
  modifier txDeadlineNotExpired(uint256 txDeadlineTime) {
    // No transaction deadline when set to 0.
    if (txDeadlineTime != 0 && txDeadlineTime.hasExpired()) {
      revert TxDeadline_Tx_Deadline_Expired();
    }
    _;
  }

  // This mixin does not use any storage.
}