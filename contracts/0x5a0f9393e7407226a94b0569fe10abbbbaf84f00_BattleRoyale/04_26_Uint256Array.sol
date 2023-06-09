// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.9.0;

library Uint256Array {
  using Uint256Array for Uint256s;

  struct Uint256s {
    uint256[]  _items;
  }

  /**
   * @notice push an uint256 to the array
   * @dev if the uint256 already exists, it will not be added again
   * @param self Storage array containing uint256 type variables
   * @param element the element to add in the array
   */
  function push(Uint256s storage self, uint256 element) internal returns (bool) {
    if (!exists(self, element)) {
      self._items.push(element);
      return true;
    }
    return false;
  }
  /**
   * @notice remove a uint256 from the array
   * @dev finds the element, swaps it with the last element, and then deletes it;
   *      returns a boolean whether the element was found and deleted
   * @param self Storage array containing uint256 type variables
   * @param element the element to remove from the array
   */
  function remove(Uint256s storage self, uint256 element) internal returns (bool) {
    int256 i = getIndex(self, element);

    if (i >= 0) {
      return removeByIndex(self, uint256(i));
    }
    return false;
  }

  /**
   * @notice get the uint256 at a specific index from array
   * @dev revert if the index is out of bounds
   * @param self Storage array containing uint256 type variables
   * @param index the index in the array
   */
  function atIndex(Uint256s storage self, uint256 index) internal view returns (uint256) {
    require(index < size(self), "the index is out of bounds");
    return self._items[index];
  }

  /**
   * @notice get the size of the array
   * @param self Storage array containing uint256 type variables
   */
  function size(Uint256s storage self) internal view returns (uint256) {
    return self._items.length;
  }

  /**
   * @notice check if an element exist in the array
   * @param self Storage array containing uint256 type variables
   * @param element the element to check if it exists in the array
   */
  function exists(Uint256s storage self, uint256 element) internal view returns (bool) {
    return getIndex(self, element) >= 0;
  }
  /**
   * @notice get the array
   * @param self Storage array containing uint256 type variables
   */
  function getAll(Uint256s storage self) internal view returns(uint256[] memory) {
    return self._items;
  }
  /*
   * @notice get index of uint256
   * @param self Storage array containing uint256 type variables
   * @param element the element to get index in array
   */
  function getIndex(Uint256s storage self, uint256 element) internal view returns(int256) {
    for (uint256 i = 0; i < size(self); i++){
      if(self._items[i] == element) {
        return int256(i);
      }

      uint256 j = size(self) - 1 - i;
      if (self._items[j] == element) {
        return int256(j);
      }

      if (i >= j) {
        break;
      }
    }
    return -1;
  }
  /*
   * @notice get index of uint256
   * @param self Storage array containing uint256 type variables
   * @param i index of element to remove
   */
  function removeByIndex(Uint256s storage self, uint256 i) internal returns (bool) {
    if (i < size(self)) {
      uint last = size(self) - 1;
      if (i < last) {
        self._items[i] = self._items[last];
      }
      self._items.pop();
      return true;
    }
    return false;
  }
}