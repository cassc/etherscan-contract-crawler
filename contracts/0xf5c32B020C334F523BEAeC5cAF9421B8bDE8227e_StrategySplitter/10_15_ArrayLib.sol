// SPDX-License-Identifier: ISC
/**
* By using this software, you understand, acknowledge and accept that Tetu
* and/or the underlying software are provided “as is” and “as available”
* basis and without warranties or representations of any kind either expressed
* or implied. Any use of this open source software released under the ISC
* Internet Systems Consortium license is done at your own risk to the fullest
* extent permissible pursuant to applicable law any and all liability as well
* as all warranties, including any fitness for a particular purpose with respect
* to Tetu and/or the underlying software and the use thereof are disclaimed.
*/

pragma solidity 0.8.4;

/// @title Library for useful functions for address and uin256 arrays
/// @author bogdoslav, belbix
library ArrayLib {

  string constant INDEX_OUT_OF_BOUND = "ArrayLib: Index out of bounds";
  string constant NOT_UNIQUE_ITEM = "ArrayLib: Not unique item";
  string constant ITEM_NOT_FOUND = "ArrayLib: Item not found";

  /// @dev Return true if given item found in address array
  function contains(address[] storage array, address _item) internal view returns (bool) {
    for (uint256 i = 0; i < array.length; i++) {
      if (array[i] == _item) return true;
    }
    return false;
  }

  /// @dev Return true if given item found in uin256 array
  function contains(uint256[] storage array, uint256 _item) internal view returns (bool) {
    for (uint256 i = 0; i < array.length; i++) {
      if (array[i] == _item) return true;
    }
    return false;
  }

  // -----------------------------------

  /// @dev If token not exist in the array push it, otherwise throw an error
  function addUnique(address[] storage array, address _item) internal {
    require(!contains(array, _item), NOT_UNIQUE_ITEM);
    array.push(_item);
  }

  /// @dev If token not exist in the array push it, otherwise throw an error
  function addUnique(uint256[] storage array, uint256 _item) internal {
    require(!contains(array, _item), NOT_UNIQUE_ITEM);
    array.push(_item);
  }

  // -----------------------------------

  /// @dev Call addUnique for the given items array
  function addUniqueArray(address[] storage array, address[] memory _items) internal {
    for (uint256 i = 0; i < _items.length; i++) {
      addUnique(array, _items[i]);
    }
  }

  /// @dev Call addUnique for the given items array
  function addUniqueArray(uint256[] storage array, uint256[] memory _items) internal {
    for (uint i = 0; i < _items.length; i++) {
      addUnique(array, _items[i]);
    }
  }

  // -----------------------------------

  /// @dev Remove an item by given index.
  /// @param keepSorting If true the function will shift elements to the place of removed item
  ///                    If false will move the last element on the place of removed item
  function removeByIndex(address[] storage array, uint256 index, bool keepSorting) internal {
    require(index < array.length, INDEX_OUT_OF_BOUND);

    if (keepSorting) {
      // shift all elements to the place of removed item
      // the loop must not include the last element
      for (uint256 i = index; i < array.length - 1; i++) {
        array[i] = array[i + 1];
      }
    } else {
      // copy the last address in the array
      array[index] = array[array.length - 1];
    }
    array.pop();
  }

  /// @dev Remove an item by given index.
  /// @param keepSorting If true the function will shift elements to the place of removed item
  ///                    If false will move the last element on the place of removed item
  function removeByIndex(uint256[] storage array, uint256 index, bool keepSorting) internal {
    require(index < array.length, INDEX_OUT_OF_BOUND);

    if (keepSorting) {
      // shift all elements to the place of removed item
      // the loop must not include the last element
      for (uint256 i = index; i < array.length - 1; i++) {
        array[i] = array[i + 1];
      }
    } else {
      // copy the last address in the array
      array[index] = array[array.length - 1];
    }
    array.pop();
  }

  // -----------------------------------

  /// @dev Find given item in the array and call removeByIndex function if exist. If not throw an error
  function findAndRemove(address[] storage array, address _item, bool keepSorting) internal {
    for (uint256 i = 0; i < array.length; i++) {
      if (array[i] == _item) {
        removeByIndex(array, i, keepSorting);
        return;
      }
    }
    revert(ITEM_NOT_FOUND);
  }

  /// @dev Find given item in the array and call removeByIndex function if exist. If not throw an error
  function findAndRemove(uint256[] storage array, uint256 _item, bool keepSorting) internal {
    for (uint256 i = 0; i < array.length; i++) {
      if (array[i] == _item) {
        removeByIndex(array, i, keepSorting);
        return;
      }
    }
    revert(ITEM_NOT_FOUND);
  }

  // -----------------------------------

  /// @dev Call findAndRemove function for given item array
  function findAndRemoveArray(address[] storage array, address[] memory _items, bool keepSorting) internal {
    for (uint256 i = 0; i < _items.length; i++) {
      findAndRemove(array, _items[i], keepSorting);
    }
  }

  /// @dev Call findAndRemove function for given item array
  function findAndRemoveArray(uint256[] storage array, uint256[] memory _items, bool keepSorting) internal {
    for (uint256 i = 0; i < _items.length; i++) {
      findAndRemove(array, _items[i], keepSorting);
    }
  }

  // -----------------------------------

  /// @dev Remove from array the item with given id and move the last item on it place
  ///      Use with mapping for keeping indexes in correct ordering
  function removeIndexed(
    uint256[] storage array,
    mapping(uint256 => uint256) storage indexes,
    uint256 id
  ) internal {
    uint256 lastId = array[array.length - 1];
    uint256 index = indexes[id];
    indexes[lastId] = index;
    indexes[id] = type(uint256).max;
    array[index] = lastId;
    array.pop();
  }

  // ************* SORTING *******************

  /// @dev Insertion sorting algorithm for using with arrays fewer than 10 elements
  ///      Based on https://medium.com/coinmonks/sorting-in-solidity-without-comparison-4eb47e04ff0d
  function sortAddressesByUint(address[] storage addressArray, mapping(address => uint) storage uintMap) internal {
    for (uint i = 1; i < addressArray.length; i++) {
      address key = addressArray[i];
      uint j = i - 1;
      while ((int(j) >= 0) && uintMap[addressArray[j]] > uintMap[key]) {
        addressArray[j + 1] = addressArray[j];
      unchecked {j--;}
      }
    unchecked {
      addressArray[j + 1] = key;
    }
    }
  }

  /// @dev Insertion sorting algorithm for using with arrays fewer than 10 elements
  ///      Based on https://medium.com/coinmonks/sorting-in-solidity-without-comparison-4eb47e04ff0d
  function sortAddressesByUintReverted(address[] storage addressArray, mapping(address => uint) storage uintMap) internal {
    for (uint i = 1; i < addressArray.length; i++) {
      address key = addressArray[i];
      uint j = i - 1;
      while ((int(j) >= 0) && uintMap[addressArray[j]] < uintMap[key]) {
        addressArray[j + 1] = addressArray[j];
      unchecked {j--;}
      }
    unchecked {
      addressArray[j + 1] = key;
    }
    }
  }

}