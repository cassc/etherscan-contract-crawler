// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

library Utils {
  // convert a uint to str
  function uint2str(uint _i) internal pure returns (string memory str) {
      if (_i == 0) {
          return "0";
      }
      uint j = _i;
      uint len;
      while (j != 0) {
          len++;
          j /= 10;
      }
      bytes memory bstr = new bytes(len);
      uint k = len;
      j = _i;
      while (j != 0) {
          bstr[--k] = bytes1(48 + uint8(_i - _i / 10 * 10));
          j /= 10;
      }
      str = string(bstr);
  }

  function uint32ToString(uint32 v) pure internal returns (string memory str) {
    if (v == 0) {
        return "0";
    }
    // max uint32 4294967295 so 10 digits
    uint maxlength = 10;
    bytes memory reversed = new bytes(maxlength);
    uint i = 0;
    while (v != 0) {
        uint remainder = v % 10;
        v = v / 10;
        reversed[i++] = bytes1(uint8(48 + remainder));
    }
    bytes memory s = new bytes(i);
    for (uint j = 0; j < i; j++) {
        s[j] = reversed[i - j - 1];
    }
    str = string(s);
  }

  function addressToString(address x) internal pure returns (string memory) {
    bytes memory s = new bytes(40);
    for (uint i = 0; i < 20; i++) {
        bytes1 b = bytes1(uint8(uint(uint160(x)) / (2**(8*(19 - i)))));
        bytes1 hi = bytes1(uint8(b) / 16);
        bytes1 lo = bytes1(uint8(b) - 16 * uint8(hi));
        s[2*i] = char(hi);
        s[2*i+1] = char(lo);            
    }
    return string(s);
   }

   function char(bytes1 b) internal pure returns (bytes1 c) {
        if (uint8(b) < 10) return bytes1(uint8(b) + 0x30);
        else return bytes1(uint8(b) + 0x57);
    }
}