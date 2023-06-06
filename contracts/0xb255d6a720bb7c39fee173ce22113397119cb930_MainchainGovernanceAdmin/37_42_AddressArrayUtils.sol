// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

library AddressArrayUtils {
  /**
   * @dev Returns whether or not there's a duplicate. Runs in O(n^2).
   * @param A Array to search
   * @return Returns true if duplicate, false otherwise
   */
  function hasDuplicate(address[] memory A) internal pure returns (bool) {
    if (A.length == 0) {
      return false;
    }
    for (uint256 i = 0; i < A.length - 1; i++) {
      for (uint256 j = i + 1; j < A.length; j++) {
        if (A[i] == A[j]) {
          return true;
        }
      }
    }
    return false;
  }

  /**
   * @dev Returns whether two arrays of addresses are equal or not.
   */
  function isEqual(address[] memory _this, address[] memory _other) internal pure returns (bool) {
    bytes32 _thisHash;
    bytes32 _otherHash;

    assembly {
      _thisHash := keccak256(add(_this, 32), mul(mload(_this), 32))
      _otherHash := keccak256(add(_other, 32), mul(mload(_other), 32))
    }

    return _thisHash == _otherHash;
  }
}