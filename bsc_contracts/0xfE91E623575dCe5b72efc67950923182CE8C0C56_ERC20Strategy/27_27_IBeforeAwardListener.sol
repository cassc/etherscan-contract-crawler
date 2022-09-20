// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/// @notice The interface for the Periodic Prize Strategy before award listener.  This listener will be called immediately before the award is distributed.
interface IBeforeAwardListener is IERC165 {
  /// @notice Called immediately before the award is distributed
  function beforePrizePoolAwarded(uint256 randomNumber, uint256 prizePeriodStartedAt) external;
}