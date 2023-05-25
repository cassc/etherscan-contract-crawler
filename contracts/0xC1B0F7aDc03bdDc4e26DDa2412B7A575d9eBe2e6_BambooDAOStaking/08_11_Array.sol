// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Array
 * @author artpumpkin
 * @notice Adds utility functions to an array of integers
 */
library Array {
  /**
   * @notice Removes an array item by index
   * @dev This is a O(1) time-complexity algorithm without persiting the order
   * @param array_ A reference value to the array
   * @param index_ An item index to be removed
   */
  function remove(uint256[] storage array_, uint256 index_) internal {
    require(index_ < array_.length, "index out of bound");
    array_[index_] = array_[array_.length - 1];
    array_.pop();
  }
}