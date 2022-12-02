// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

library ArrayUtil {
  function removeElementFromArray(uint[] storage _array, uint _element) internal returns (uint[] memory) {
    uint index = _getElementIndex(_array, _element);
    if (index >= 0 && index < _array.length) {
      _array[index] = _array[_array.length - 1];
      _array.pop();
    }
    return _array;
  }

  function _getElementIndex(uint[] memory _array, uint _element) private pure returns (uint) {
    for(uint i = 0; i < _array.length; i++) {
      if (_array[i] == _element) return i;
    }
    return type(uint).max;
  }
}