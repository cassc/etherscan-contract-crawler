// SPDX-License-Identifier: MIT

pragma solidity 0.8.11;

/** @notice Handle setting zero value in a storage word as uint128 max value.
  *
  *  @dev
  *  The purpose of this is to avoid resetting a storage word to the zero value; 
  *  the gas cost of re-initializing the value is the same as setting the word originally.
  *  so instead, if word is to be set to zero, we set it to uint128 max.
  *
  *   - anytime a word is loaded from storage: call "get"
  *   - anytime a word is written to storage: call "set"
  *   - common operations on uints are also bundled here.
  *
  * NOTE: This library should ONLY be used when reading or writing *directly* from storage.
 */
library Max128Bit {
    uint128 internal constant ZERO = type(uint128).max;

    function get(uint128 a) internal pure returns(uint128) {
        return (a == ZERO) ? 0 : a;
    }

    function set(uint128 a) internal pure returns(uint128){
        return (a == 0) ? ZERO : a;
    }

    function add(uint128 a, uint128 b) internal pure returns(uint128 c){
        a = get(a);
        c = set(a + b);
    }
}