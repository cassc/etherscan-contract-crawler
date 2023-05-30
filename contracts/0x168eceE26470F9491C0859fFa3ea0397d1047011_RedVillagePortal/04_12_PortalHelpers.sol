// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

library TokenHolder {
  struct Holders {
    address[] accounts;
    mapping(address => uint256) indexes; // account value to index
  }

  function addHolder(Holders storage _holders, address _account) internal {
    if (_holders.indexes[_account] != 0) return; // already exists
    _holders.accounts.push(_account);
    // The value is stored at length-1, but adding 1 to all indexes
    // and use 0 as a sentinel value
    _holders.indexes[_account] = _holders.accounts.length;
  }

  function removeHolder(Holders storage _holders, address _account) internal {
    uint256 valueIndex = _holders.indexes[_account];

    if (valueIndex == 0) return; // removed not exists value

    uint256 toDeleteIndex = valueIndex - 1; // when add we not sub for 1 so now must sub 1 (for not out of bound)
    uint256 lastIndex = _holders.accounts.length - 1;

    if (lastIndex != toDeleteIndex) {
      // swap
      address lastvalue = _holders.accounts[lastIndex];

      // Move the last value to the index where the value to delete is
      _holders.accounts[toDeleteIndex] = lastvalue;
      // Update the index for the moved value
      _holders.indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
    }

    // Delete the slot where the moved value was stored
    _holders.accounts.pop();

    // Delete the index for the deleted slot
    _holders.indexes[_account] = 0; // set to 0
  }

  function containsHolder(Holders storage _holders, address _account) internal view returns (bool) {
    return _holders.indexes[_account] != 0;
  }
}