// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/** @notice influenced by OpenZeppelin SafeCast lib, which is missing to uint72 cast
 * @author BGD Labs
 */
library SafeCast72 {
  /**
   * @dev Returns the downcasted uint72 from uint256, reverting on
   * overflow (when the input is greater than largest uint72).
   *
   * Counterpart to Solidity's `uint16` operator.
   *
   * Requirements:
   *
   * - input must fit into 72 bits
   */
  function toUint72(uint256 value) internal pure returns (uint72) {
    require(value <= type(uint72).max, "SafeCast: value doesn't fit in 72 bits");
    return uint72(value);
  }
}