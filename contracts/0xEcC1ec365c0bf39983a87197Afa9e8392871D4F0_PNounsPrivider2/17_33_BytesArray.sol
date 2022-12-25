// SPDX-License-Identifier: MIT

/*
 * Created by Satoshi Nakajima (@snakajima)
 */

pragma solidity ^0.8.6;

library BytesArray {
  /**
   * Equivalent to abi.encodedPacked(parts[0], parts[1], ..., parts[N-1]), where
   * N is the length of bytes.
   *
   * The complexty of this algorithm is O(M), where M is the number of total bytes.
   * Calling abi.encodePacked() in a loop reallocates memory N times, therefore,
   * the complexity will become O(M * N). 
   */
  function packed(bytes[] memory parts) internal pure returns (bytes memory ret) {
    uint count = parts.length;
    assembly {
      ret := mload(0x40)
      let retMemory := add(ret, 0x20)
      let bufParts := add(parts, 0x20)
      for {let i := 0} lt(i, count) {i := add(i, 1)} {
        let src := mload(bufParts) // read the address
        let dest := retMemory
        let length := mload(src)
        // copy 0x20 bytes each (and let it overrun)
        for {let j := 0} lt(j, length) {j := add(j, 0x20)} {
          src := add(src, 0x20) // dual purpose
          mstore(dest, mload(src))
          dest := add(dest, 0x20)
        }
        retMemory := add(retMemory, length)
        bufParts := add(bufParts, 0x20)
      }
      mstore(ret, sub(sub(retMemory, ret), 0x20))
      mstore(0x40, retMemory)
    }
  }

}