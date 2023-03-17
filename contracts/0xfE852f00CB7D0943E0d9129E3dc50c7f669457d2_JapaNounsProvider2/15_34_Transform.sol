// SPDX-License-Identifier: MIT

/*
 * This is a part of fully-on-chain.sol, a npm package that allows developers
 * to create fully on-chain generative art.
 *
 * Created by Satoshi Nakajima (@snakajima)
 */

pragma solidity ^0.8.6;

import '@openzeppelin/contracts/utils/Strings.sol';
import 'bytes-array.sol/BytesArray.sol';

library TX {
  using Strings for uint;
  using BytesArray for bytes[];

  function toString(int _value) internal pure returns (string memory) {
    if (_value > 0) {
      return uint(_value).toString();
    }
    return string(abi.encodePacked('-', uint(-_value).toString()));
  }

  function translate(int x, int y) internal pure returns (string memory) {
    return string(abi.encodePacked('translate(', toString(x), ' ', toString(y), ')'));
  }

  function rotate(string memory _base, string memory _value) internal pure returns (string memory) {
    return string(abi.encodePacked(_base, ' rotate(', _value, ')'));
  }

  function scale(string memory _base, string memory _scale) internal pure returns (string memory) {
    return string(abi.encodePacked(_base, ' scale(', _scale, ')'));
  }

  function scale1000(uint _value) internal pure returns (string memory) {
    return string(abi.encodePacked('scale(', fixed1000(_value), ')'));
  }

  function scale1000(string memory _base, uint _value) internal pure returns (string memory) {
    return string(abi.encodePacked(_base, ' scale(', fixed1000(_value), ')'));
  }

  function fixed1000(uint _value) internal pure returns (string memory) {
    bytes[] memory array = new bytes[](3);
    if (_value > 1000) {
      array[0] = bytes((_value / 1000).toString());
    } else {
      array[0] = '0';
    }
    if (_value < 10) {
      array[1] = '.00';
    } else if (_value < 100) {
      array[1] = '.0';
    } else {
      array[1] = '.';
    }
    array[2] = bytes(_value.toString());
    return string(array.packed());
  }
}