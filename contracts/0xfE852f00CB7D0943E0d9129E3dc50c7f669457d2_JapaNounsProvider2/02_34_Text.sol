// SPDX-License-Identifier: MIT

/*
 * This is a part of fully-on-chain.sol, a npm package that allows developers
 * to create fully on-chain generative art.
 *
 * Created by Satoshi Nakajima (@snakajima)
 */

pragma solidity ^0.8.6;

library Text {
  function extractLine(
    string memory _text,
    uint _index,
    uint _ch
  ) internal pure returns (string memory line, uint index) {
    uint length = bytes(_text).length;
    assembly {
      line := mload(0x40)
      let wbuf := add(line, 0x20)
      let rbuf := add(add(_text, 0x20), _index)
      let word := 0
      let shift := 0
      let i
      for {
        i := _index
      } lt(i, length) {
        i := add(i, 1)
      } {
        if eq(shift, 0) {
          word := mload(rbuf)
          mstore(wbuf, word)
          rbuf := add(rbuf, 0x20)
          wbuf := add(wbuf, 0x20)
          shift := 256
        }
        shift := sub(shift, 8)
        if eq(and(shr(shift, word), 0xff), _ch) {
          length := i
        }
      }

      index := i
      length := sub(i, _index)
      mstore(line, length) //sub(i, _index))
      mstore(0x40, add(add(line, 0x20), length))
    }
  }

  function split(string memory _str, uint _ch) internal pure returns (string[] memory strs) {
    uint length = bytes(_str).length;
    uint count;
    for (uint i = 0; i < length; ) {
      (, i) = extractLine(_str, i, _ch);
      count += 1;
    }
    strs = new string[](count);
    count = 0;
    for (uint i = 0; i < length; ) {
      (strs[count], i) = extractLine(_str, i, _ch);
      count += 1;
    }
  }
}