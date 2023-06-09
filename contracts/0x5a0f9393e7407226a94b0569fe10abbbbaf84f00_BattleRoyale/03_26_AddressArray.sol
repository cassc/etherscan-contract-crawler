// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.9.0;

library AddressArray {
  using AddressArray for Addresses;

  struct Addresses {
    address payable[] _items;
  }

  /**
   * @notice push an address to the array
   * @dev if the address already exists, it will not be added again
   * @param self Storage array containing address type variables
   * @param element the element to add in the array
   */
  function push(Addresses storage self, address payable element) internal returns (bool) {
    if (!exists(self, element)) {
      self._items.push(element);
      return true;
    }
    return false;
  }
  /**
   * @notice remove an address from the array
   * @dev finds the element, swaps it with the last element, and then deletes it;
   *      returns a boolean whether the element was found and deleted
   * @param self Storage array containing address type variables
   * @param element the element to remove from the array
   */
  function remove(Addresses storage self, address payable element) internal returns (bool) {
    int256 i = getIndex(self, element);

    if (i >= 0) {
      return removeByIndex(self, uint256(i));
    }
    return false;
  }

  /**
   * @notice get the address at a specific index from array
   * @dev revert if the index is out of bounds
   * @param self Storage array containing address type variables
   * @param index the index in the array
   */
  function atIndex(Addresses storage self, uint256 index) internal view returns (address payable) {
    require(index < size(self), "the index is out of bounds");
    return self._items[index];
  }

  /**
   * @notice get the size of the array
   * @param self Storage array containing address type variables
   */
  function size(Addresses storage self) internal view returns (uint256) {
    return self._items.length;
  }

  /**
   * @notice check if an element exist in the array
   * @param self Storage array containing address type variables
   * @param element the element to check if it exists in the array
   */
  function exists(Addresses storage self, address payable element) internal view returns (bool) {
    return getIndex(self, element) >= 0;
  }
  /**
   * @notice get the array
   * @param self Storage array containing address type variables
   */
  function getAll(Addresses storage self) internal view returns(address payable[] memory) {
    return self._items;
  }
  /*
   * @notice get index of address
   * @param self Storage array containing address type variables
   * @param element the element to get index in array
   */
  function getIndex(Addresses storage self, address payable element) internal view returns(int256) {
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
   * @notice get index of address
   * @param self Storage array containing address type variables
   * @param i index of element to remove
   */
  function removeByIndex(Addresses storage self, uint256 i) internal returns (bool) {
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