// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IBridge {
  /**
   * @dev Replaces the old bridge operator list by the new one.
   *
   * Requirements:
   * - The method caller is admin.
   *
   * Emitted the event `BridgeOperatorsReplaced`.
   *
   */
  function replaceBridgeOperators(address[] calldata) external;

  /**
   * @dev Returns the bridge operator list.
   */
  function getBridgeOperators() external view returns (address[] memory);
}