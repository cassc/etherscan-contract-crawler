// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library ToHairColor {
    bytes16 internal constant ALPHABET = '0123456789abcdef';

    function toColor(bytes3 value) internal pure returns (string memory) {
        bytes memory buffer = new bytes(6);
        for (uint256 i = 0; i < 3; i++) {
            buffer[i*2+1] = ALPHABET[uint8(value[i]) & 0xf];
            buffer[i*2] = ALPHABET[uint8(value[i]>>4) & 0xf];
        }
        return string(buffer);
        }

    function toHairColor(bytes3 value) internal view returns (string memory) {
      uint r = uint256(uint8(value[0]));
      if(r > 5 && r < 30){
        bytes32 predictableRandom = keccak256(abi.encodePacked( value ));
        bytes3 value2 = bytes2(predictableRandom[3]) | ( bytes2(predictableRandom[4]) >> 8 ) | ( bytes3(predictableRandom[5]) >> 16 );
        return toColor(value2);
        }
      if(r <= 5){
        bytes32 predictableRandom = keccak256(abi.encodePacked( value, block.timestamp ));
        bytes3 value2 = bytes2(predictableRandom[3]) | ( bytes2(predictableRandom[4]) >> 8 ) | ( bytes3(predictableRandom[5]) >> 16 );
        return toColor(value2);
      }
      uint g = r >= 80 ? r - (256 - r)/3 : r - 5;
      
      uint b = 
        r >= 121 ? g - (47 + ((28 * uint256(uint8(value[1])))/255)) : 
        r >  80 ? (g * uint256(uint8(value[1])))/255 :
        g - 5;

      //this gives better brunette shades
      if(g > 88 && r + 50 - (14 * b / 10) > 88){
        g = g -20;
      }

      //gingers
      if(r + 50 - (14 * b / 10) <= 88 && r <= 220 && r >= 80){
        g = g * 10 / 16;
        b = b / 2;
      }

      bytes3 newValue = uints2bytes(r,g,b);

      bytes memory buffer = new bytes(6);
      for (uint256 i = 0; i < 3; i++) {
          buffer[i*2+1] = ALPHABET[uint8(newValue[i]) & 0xf];
          buffer[i*2] = ALPHABET[uint8(newValue[i]>>4) & 0xf];
      }
      return string(buffer);
    }

    function uint2Bytes(uint num) internal pure returns(bytes2) {
        return abi.encodePacked(num)[31];
    }

    function uints2bytes(uint r, uint g, uint b) internal pure returns(bytes3) {
        return (uint2Bytes(r) | (uint2Bytes(g) >> 8) | (bytes3(uint2Bytes(b)) >> 16));
        
    }
    
}