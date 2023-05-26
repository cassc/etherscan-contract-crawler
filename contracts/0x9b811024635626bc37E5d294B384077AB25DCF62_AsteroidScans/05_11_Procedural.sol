// SPDX-License-Identifier: UNLICENSED
// Portions licensed under NovakDistribute license (ref LICENSE file)
pragma solidity ^0.7.0;

import "abdk-libraries-solidity/ABDKMath64x64.sol";

library Procedural {
  using ABDKMath64x64 for *;

  /**
   * @dev Mix string data into a hash and return a new one.
   */
  function derive(bytes32 _self, string memory _entropy) public pure returns (bytes32) {
    return sha256(abi.encodePacked(_self, _entropy));
  }

  /**
   * @dev Mix signed int data into a hash and return a new one.
   */
  function derive(bytes32 _self, int256 _entropy) public pure returns (bytes32) {
    return sha256(abi.encodePacked(_self, _entropy));
  }

  /**
  * @dev Mix unsigned int data into a hash and return a new one.
  */
  function derive(bytes32 _self, uint _entropy) public pure returns (bytes32) {
    return sha256(abi.encodePacked(_self, _entropy));
  }

  /**
   * @dev Returns the base pseudorandom hash for the given RandNode. Does another round of hashing
   * in case an un-encoded string was passed.
   */
  function getHash(bytes32 _self) public pure returns (bytes32) {
    return sha256(abi.encodePacked(_self));
  }

  /**
   * @dev Get an int128 full of random bits.
   */
  function getInt128(bytes32 _self) public pure returns (int128) {
    return int128(int256(getHash(_self)));
  }

  /**
   * @dev Get a 64.64 fixed point (see ABDK math) where: 0 <= return value < 1
   */
  function getReal(bytes32 _self) public pure returns (int128) {
    int128 fixedOne = int128(1 << 64);
    return getInt128(_self).abs() % fixedOne;
  }

  /**
   * @dev Get an integer between low, inclusive, and high, exclusive. Represented as a normal int, not a real.
   */
  function getIntBetween(bytes32 _self, int128 _low, int128 _high) public pure returns (int64) {
    _low = _low.fromInt();
    _high = _high.fromInt();
    int128 range = _high.sub(_low);
    int128 result = getReal(_self).mul(range).add(_low);
    return result.toInt();
  }

  /**
   * @dev Returns a normal int (roughly) normally distributed value between low and high
   */
  function getNormalIntBetween(bytes32 _self, int128 _low, int128 _high) public pure returns (int64) {
    int128 accumulator = 0;

    for (uint i = 0; i < 5; i++) {
      accumulator += getIntBetween(derive(_self, i), _low, _high);
    }

    return accumulator.fromInt().div(5.fromUInt()).toInt();
  }

  /**
   * @dev "Folds" a normal int distribution in half to generate an approx decay function
   * Only takes a high value (exclusive) as the simplistic approximation relies on low being zero
   * Returns a normal int, not a real
   */
  function getDecayingIntBelow(bytes32 _self, uint _high) public pure returns (int64) {
    require(_high < uint(1 << 64));
    int64 normalInt = getNormalIntBetween(_self, 0, int128(_high * 2 - 1));
    int128 adjusted = int128(normalInt) - int128(_high);
    return adjusted.fromInt().abs().toInt();
  }
}