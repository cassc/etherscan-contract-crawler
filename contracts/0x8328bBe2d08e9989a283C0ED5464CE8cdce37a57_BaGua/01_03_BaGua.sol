// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import "./BytesLib.sol";
import "./Base64.sol";

/** @title BaGua Contract
  * @author @0xAnimist
  * @notice First Onchain GIF, collaboration between Cai Guo-Qiang and Kanon
  */
contract BaGua {

  constructor() { }

  /**
    * @dev Determines if cell in 3x3 grid should be illuminated
    * @param _input input seed
    * @param _totalColors total number of colors
    */
  function map(bytes32 _input, uint8 _totalColors) public pure returns (bytes2 bitstream, uint8 colorIndex) {
    bytes1 bitstream1;
    bytes memory input = abi.encodePacked(_input);

    for(uint8 i = 0; i < 8; i++){
      bitstream1 = bitstream1 | bytes1(uint8(BytesLib.toUint8(input, i*4) % 2 * (2**i)));
    }

    bytes1 bitstream2 = bytes1(uint8(BytesLib.toUint256(input,0) % 2 * (2**8)));
    bitstream = bytes2(abi.encodePacked(bitstream2, bitstream1));

    colorIndex = (BytesLib.toUint8(input,0) % (_totalColors-1)) + 1;//[1,_totalColors]; index 0 used for transparency
  }

  /**
    * @dev Translates an _input seed into 3x3 grid (Gua)
    * @param _input input seed
    */
  function cast(bytes32 _input, uint8 _totalColors) public pure returns(uint8[][] memory gua, uint8 colorIndex, bytes2 bitstream) {
    (bitstream, colorIndex) = map(_input, _totalColors);

    gua = new uint8[][](3);
    for(uint8 i = 0; i < 3; i++){
      gua[i] = new uint8[](3);
      for(uint8 j = 0; j < 3; j++){
        uint8 idx = 3*i + j;
        if((bitstream & bytes2(uint16((2**idx)))) == bytes2(uint16((2**idx)))) {
          gua[i][j] = 1;
        }
      }
    }



  }//end cast()


}//end