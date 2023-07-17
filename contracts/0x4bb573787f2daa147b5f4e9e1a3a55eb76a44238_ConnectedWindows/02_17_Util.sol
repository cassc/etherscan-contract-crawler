// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

contract Util {
  function bytes32ToHexString(bytes32 _bytes32)
    public
    pure
    returns (string memory)
  {
    bytes memory byteArray = new bytes(64);
    for (uint8 i = 0; i < 32; i++) {
      uint8 currentByte = uint8(_bytes32[i]);
      uint8 highNibble = currentByte >> 4;
      uint8 lowNibble = currentByte & 0x0f;
      byteArray[i * 2] = toByte(highNibble);
      byteArray[i * 2 + 1] = toByte(lowNibble);
    }
    return string(byteArray);
  }

  function toByte(uint8 _value) private pure returns (bytes1) {
    if (_value < 10) {
      return bytes1(uint8(bytes1("0")) + _value);
    } else {
      return bytes1(uint8(bytes1("a")) + _value - 10);
    }
  }
}