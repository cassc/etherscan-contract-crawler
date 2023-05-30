// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library ToColor {
    bytes16 internal constant ALPHABET = '0123456789abcdef';

    function toColor(bytes3 value) internal pure returns (string memory) {
      bytes memory buffer = new bytes(6);
      for (uint256 i = 0; i < 3; i++) {
          buffer[i*2+1] = ALPHABET[uint8(value[i]) & 0xf];
          buffer[i*2] = ALPHABET[uint8(value[i]>>4) & 0xf];
      }
      return string(buffer);
    }

    function toRace(bytes3 value) internal pure returns (string memory) {
      uint r = 120 + ((135*uint256(uint8(value[0])))/255);
      uint gRandom = 89 + uint256(uint8(value[1]))/10;
      uint g = gRandom + (r ** 2 * 5 / 1000) - (r * 8 / 10);
      uint bRandom = 230 + ((40 * uint256(uint8(value[2])))/255);
      uint b = bRandom + (r ** 2 * 105 / 10000) - 3 * r;

      bytes3 newValue = uints2bytes(r,g,b);

      bytes memory buffer = new bytes(6);
      for (uint256 i = 0; i < 3; i++) {
          buffer[i*2+1] = ALPHABET[uint8(newValue[i]) & 0xf];
          buffer[i*2] = ALPHABET[uint8(newValue[i]>>4) & 0xf];
      }
      return string(buffer);
    }

    function toPigment(bytes3 value) internal pure returns (uint) {
        return 20 + 8 * (uint256(uint8(value[1])) % 100) / 10;
    }


    function uint2Bytes(uint num) internal pure returns(bytes2) {
        return abi.encodePacked(num)[31];
    }

    function uints2bytes(uint r, uint g, uint b) internal pure returns(bytes3) {
        return (uint2Bytes(r) | (uint2Bytes(g) >> 8) | (bytes3(uint2Bytes(b)) >> 16));
        
    }
    
}