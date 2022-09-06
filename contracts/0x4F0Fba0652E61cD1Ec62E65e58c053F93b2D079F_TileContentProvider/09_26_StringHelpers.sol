// SPDX-License-Identifier: MIT
import {Strings} from '@openzeppelin/contracts/utils/Strings.sol';

pragma solidity ^0.8.6;

library StringHelpers {
  function toAsciiString(address x) internal pure returns (string memory) {
    bytes memory s = new bytes(40);
    for (uint256 i = 0; i < 20; i++) {
      bytes1 b = bytes1(uint8(uint256(uint160(x)) / (2**(8 * (19 - i)))));
      bytes1 hi = bytes1(uint8(b) / 16);
      bytes1 lo = bytes1(uint8(b) - 16 * uint8(hi));
      s[2 * i] = char(hi);
      s[2 * i + 1] = char(lo);
    }
    return string(s);
  }

  function char(bytes1 b) internal pure returns (bytes1 c) {
    if (uint8(b) < 10) return bytes1(uint8(b) + 0x30);
    else return bytes1(uint8(b) + 0x57);
  }

  function divide(
    uint256 _a,
    uint256 _b,
    uint256 n
  ) internal pure returns (string memory) {
    uint256 c = _a / _b;
    uint256 d = (_a * (10**n)) / _b;

    bytes memory _cBytes = abi.encodePacked(c != 0 ? Strings.toString(c) : '');
    bytes memory _dBytes = abi.encodePacked(d != 0 ? Strings.toString(d) : '0');
    bytes memory _finalBytes = new bytes(_cBytes.length + 1 + n);

    for (uint256 i = 0; i <= _cBytes.length; i++) {
      if (i < _cBytes.length) {
        _finalBytes[i] = _cBytes[i];
      } else if (i == _cBytes.length) {
        _finalBytes[i] = bytes1(uint8(46));
      }
    }

    for (uint256 i = 0; i < (_dBytes.length > n ? n : _dBytes.length); i++) {
      _finalBytes[i + _cBytes.length + 1] = _dBytes[_cBytes.length + i];
    }
    return string(_finalBytes);
  }

  function replace(
    string memory _str,
    string memory _from,
    string memory _to
  ) public pure returns (string memory) {
    bytes memory _strBytes = abi.encodePacked(_str);
    bytes memory _fromBytes = abi.encodePacked(_from);
    bytes memory _toBytes = abi.encodePacked(_to);
    uint256 i;
    while (i <= _strBytes.length - _fromBytes.length) {
      for (uint256 j = 0; j < _fromBytes.length; j++) {
        if (_strBytes[i + j] != _fromBytes[j]) {
          break;
        }
        if (j == _fromBytes.length - 1) {
          bytes memory _newStrBytes = new bytes(
            _strBytes.length - _fromBytes.length + _toBytes.length
          );
          for (uint256 k = 0; k < i; k++) {
            _newStrBytes[k] = _strBytes[k];
          }
          for (uint256 k = 0; k < _toBytes.length; k++) {
            _newStrBytes[i + k] = _toBytes[k];
          }
          for (uint256 k = i + _fromBytes.length; k < _strBytes.length; k++) {
            _newStrBytes[k - _fromBytes.length + _toBytes.length] = _strBytes[k];
          }
          return string(_newStrBytes);
        }
      }
      i++;
    }

    return _str;
  }

  function stringStartsWith(string memory _str, string memory _prefix) public pure returns (bool) {
    bytes memory _strBytes = bytes(_str);
    bytes memory _prefixBytes = bytes(_prefix);
    bytes memory _tempString = new bytes(_prefixBytes.length);
    for (uint32 i = 0; i < _prefixBytes.length; i++) {
      _tempString[i] = _strBytes[i];
    }
    return keccak256(abi.encodePacked(_prefixBytes)) == keccak256(abi.encodePacked(_tempString));
  }
}