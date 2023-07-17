// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

abstract contract TermUtils {
  error ValueIsZero(uint256 value);
  error AddressIsZero(address addr);
  error SameAddress(address addr1, address addr2);
  error NotOwner(address sender);
  error WrongBoundaries(uint256 min, uint256 max);

  modifier notZeroAddr(address addr) {
    if (addr == address(0)) {
      revert AddressIsZero(addr);
    }
    _;
  }
  modifier notSameAddr(address addr1, address addr2) {
    if (addr1 == addr2) {
      revert SameAddress(addr1, addr2);
    }
    _;
  }

  /// @notice Internal function that converts uint256 to bytes
  /// @param _i uint256 to convert
  function uint2bytes(uint256 _i) internal pure returns (bytes memory _uintAsString) {
    if (_i == 0) {
      return '0';
    }
    uint256 j = _i;
    uint256 len;
    while (j != 0) {
      ++len;
      j /= 10;
    }
    _uintAsString = new bytes(len);
    uint256 k = len;
    while (_i != 0) {
      k = k - 1;
      uint8 temp = (48 + uint8(_i - (_i / 10) * 10));
      bytes1 b1 = bytes1(temp);
      _uintAsString[k] = b1;
      _i /= 10;
    }
    return _uintAsString;
  }

  function sliceString(string memory input) internal pure returns (string memory, string memory) {
    bytes memory inputBytes = bytes(input);
    uint256 delimiterIndex = findDelimiter(inputBytes, '-');

    if (delimiterIndex == inputBytes.length) {
      // Delimiter not found, return the whole string as the first part and an empty string as the second part
      return (input, '');
    } else {
      // Split the string into two parts based on the delimiter index
      bytes memory firstPart = new bytes(delimiterIndex);
      bytes memory secondPart = new bytes(inputBytes.length - delimiterIndex - 1);

      for (uint256 i = 0; i < delimiterIndex; i++) {
        firstPart[i] = inputBytes[i];
      }

      for (uint256 j = 0; j < inputBytes.length - delimiterIndex - 1; j++) {
        secondPart[j] = inputBytes[delimiterIndex + j + 1];
      }

      return (string(firstPart), string(secondPart));
    }
  }

  function findDelimiter(
    bytes memory input,
    string memory delimiter
  ) private pure returns (uint256) {
    bytes memory delimiterBytes = bytes(delimiter);

    for (uint256 i = 0; i < input.length - delimiterBytes.length; i++) {
      bool isDelimiter = true;

      for (uint256 j = 0; j < delimiterBytes.length; j++) {
        if (input[i + j] != delimiterBytes[j]) {
          isDelimiter = false;
          break;
        }
      }

      if (isDelimiter) {
        return i;
      }
    }

    return input.length;
  }

  function store3Chars(bytes memory data) internal pure returns (bytes3) {
    bytes memory result = new bytes(6);

    for (uint256 i = 0; i < 3; i++) {
      uint8 b = uint8(data[i]);

      result[i * 2] = charToHex(b >> 4);
      result[i * 2 + 1] = charToHex(b & 0x0F);
    }
    return bytes3(result);
  }

  function charToHex(uint8 c) internal pure returns (bytes1) {
    return bytes1(c < 10 ? c + 48 : c + 87);
  }
}