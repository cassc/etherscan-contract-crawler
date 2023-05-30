// SPDX-License-Identifier: MIT
// Written by Tim Kang <> illestrater
// Thought innovation by Monstercat
// Product by universe.xyz

pragma solidity >=0.6.0 <0.8.0;
pragma experimental ABIEncoderV2;

library HelperFunctions {
    function toString(uint256 value) internal pure returns (string memory) {
    if (value == 0) {
        return "0";
    }
    uint256 temp = value;
    uint256 digits;
    while (temp != 0) {
        digits++;
        temp /= 10;
    }
    bytes memory buffer = new bytes(digits);
    uint256 index = digits - 1;
    temp = value;
    while (temp != 0) {
        buffer[index--] = bytes1(uint8(48 + temp % 10));
        temp /= 10;
    }
    return string(buffer);
  }

  function safeParseInt(string memory _a) internal pure returns (uint _parsedInt) {
    return safeParseInt(_a, 0);
  }

  function safeParseInt(string memory _a, uint _b) internal pure returns (uint _parsedInt) {
    bytes memory bresult = bytes(_a);
    uint mint = 0;
    bool decimals = false;
    for (uint i = 0; i < bresult.length; i++) {
      if ((uint(uint8(bresult[i])) >= 48) && (uint(uint8(bresult[i])) <= 57)) {
        if (decimals) {
            if (_b == 0) break;
            else _b--;
        }
        mint *= 10;
        mint += uint(uint8(bresult[i])) - 48;
      } else if (uint(uint8(bresult[i])) == 46) {
        require(!decimals, 'ERR: More than one decimal');
        decimals = true;
      } else {
        revert("ERR: Non-numeral character");
      }
    }
    if (_b > 0) {
      mint *= 10 ** _b;
    }
    return mint;
  }

  function substring(string memory str, uint startIndex, uint endIndex) internal pure returns (string memory) {
    bytes memory strBytes = bytes(str);
    bytes memory result = new bytes(endIndex-startIndex);
    for(uint i = startIndex; i < endIndex; i++) {
        result[i-startIndex] = strBytes[i];
    }
    return string(result);
  }

  function addressToString(address _address) internal pure returns(string memory) {
    bytes32 _bytes = bytes32(uint256(_address));
    bytes memory HEX = "0123456789abcdef";
    bytes memory _string = new bytes(42);
    _string[0] = '0';
    _string[1] = 'x';
    for(uint i = 0; i < 20; i++) {
        _string[2+i*2] = HEX[uint8(_bytes[i + 12] >> 4)];
        _string[3+i*2] = HEX[uint8(_bytes[i + 12] & 0x0f)];
    }
    return string(_string);
  }
}