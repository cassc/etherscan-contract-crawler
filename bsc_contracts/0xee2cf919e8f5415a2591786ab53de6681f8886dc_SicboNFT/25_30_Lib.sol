// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

library Strings {
  bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

  // via https://github.com/oraclize/ethereum-api/blob/master/oraclizeAPI_0.5.sol
  function strConcat(
    string memory _a,
    string memory _b,
    string memory _c,
    string memory _d,
    string memory _e
  ) internal pure returns (string memory) {
    bytes memory _ba = bytes(_a);
    bytes memory _bb = bytes(_b);
    bytes memory _bc = bytes(_c);
    bytes memory _bd = bytes(_d);
    bytes memory _be = bytes(_e);
    string memory abcde = new string(
      _ba.length + _bb.length + _bc.length + _bd.length + _be.length
    );
    bytes memory babcde = bytes(abcde);
    uint256 k = 0;
    for (uint256 i = 0; i < _ba.length; i++) babcde[k++] = _ba[i];
    for (uint256 i = 0; i < _bb.length; i++) babcde[k++] = _bb[i];
    for (uint256 i = 0; i < _bc.length; i++) babcde[k++] = _bc[i];
    for (uint256 i = 0; i < _bd.length; i++) babcde[k++] = _bd[i];
    for (uint256 i = 0; i < _be.length; i++) babcde[k++] = _be[i];
    return string(babcde);
  }

  function strConcat(
    string memory _a,
    string memory _b,
    string memory _c,
    string memory _d
  ) internal pure returns (string memory) {
    return strConcat(_a, _b, _c, _d, "");
  }

  function strConcat(
    string memory _a,
    string memory _b,
    string memory _c
  ) internal pure returns (string memory) {
    return strConcat(_a, _b, _c, "", "");
  }

  function strConcat(string memory _a, string memory _b)
    internal
    pure
    returns (string memory)
  {
    return strConcat(_a, _b, "", "", "");
  }

  /**
   * @dev Converts a `uint256` to its ASCII `string` decimal representation.
   */
  function toString(uint256 value) internal pure returns (string memory) {
    // Inspired by OraclizeAPI's implementation - MIT licence
    // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

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
    while (value != 0) {
      digits -= 1;
      buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
      value /= 10;
    }
    return string(buffer);
  }

  /**
   * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
   */
  function toHexString(uint256 value) internal pure returns (string memory) {
    if (value == 0) {
      return "0x00";
    }
    uint256 temp = value;
    uint256 length = 0;
    while (temp != 0) {
      length++;
      temp >>= 8;
    }
    return toHexString(value, length);
  }

  /**
   * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
   */
  function toHexString(uint256 value, uint256 length)
    internal
    pure
    returns (string memory)
  {
    bytes memory buffer = new bytes(2 * length + 2);
    buffer[0] = "0";
    buffer[1] = "x";
    for (uint256 i = 2 * length + 1; i > 1; --i) {
      buffer[i] = _HEX_SYMBOLS[value & 0xf];
      value >>= 4;
    }
    require(value == 0, "Strings: hex length insufficient");
    return string(buffer);
  }
}