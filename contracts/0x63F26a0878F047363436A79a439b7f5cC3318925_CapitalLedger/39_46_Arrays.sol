// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

library Arrays {
  /**
   * @notice Removes an item from an array and replaces it with the (previously) last element in the array so
   *  there are no empty spaces. Assumes that `array` is not empty and index is valid.
   * @param array the array to remove from
   * @param index index of the item to remove
   * @return newLength length of the resulting array
   * @return replaced whether or not the index was replaced. Only false if the removed item was the last item
   *  in the array.
   */
  function reorderingRemove(
    uint256[] storage array,
    uint256 index
  ) internal returns (uint256 newLength, bool replaced) {
    newLength = array.length - 1;
    replaced = newLength != index;

    if (replaced) {
      array[index] = array[newLength];
    }

    array.pop();
  }
}