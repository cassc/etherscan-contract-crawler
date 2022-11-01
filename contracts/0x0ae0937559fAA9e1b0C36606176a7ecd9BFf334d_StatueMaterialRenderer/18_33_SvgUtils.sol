// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;
import "@openzeppelin/contracts/utils/Strings.sol";

library SvgUtils {
  using Strings for uint256;

  uint public constant DECIMALS = 4;
  uint public constant ONE_UNIT = 10 ** DECIMALS;

  function padZeros(string memory s, uint len) public pure returns (string memory) {
    uint local_len = bytes(s).length;
    string memory local_s = s;
    while(local_len < len) {
      local_s = string(abi.encodePacked('0', local_s));
      local_len++;
    }
    return local_s;
  }

  function wholeNumber(uint n) public pure returns (uint) {
    return n / ONE_UNIT;
  }

  function decimals(uint n) public pure returns (uint) {
    return n % ONE_UNIT;
  }

  function toDecimalString(uint n) public pure returns (string memory s) {
    if (n == 0) return '0';

    s = string(abi.encodePacked(
      (n / (ONE_UNIT)).toString(), '.' , padZeros((n % ONE_UNIT).toString(), DECIMALS)
    ));
  }

  function lerpWithDecimals(uint min, uint max, bytes1 scale) public pure returns (uint) {
    if (scale == 0x0) return min * ONE_UNIT;
    if (scale == 0xff) return max * ONE_UNIT;
    uint delta = ((max - min) * ONE_UNIT * uint(uint8(scale))) / 255; 
    return (min * ONE_UNIT) + delta;
  }

  bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

  function toColorHexString(uint256 value) public pure returns (string memory) {
      bytes memory buffer = new bytes(2 * 3 + 1);
      buffer[0] = "#";
      for (uint256 i = 2 * 3; i > 0; --i) {
          buffer[i] = _HEX_SYMBOLS[value & 0xf];
          value >>= 4;
      }
      require(value == 0, "Strings: hex length insufficient");
      return string(buffer);
  }

  function toColorHexStringByBytes(bytes1 r, bytes1 g, bytes1 b) public pure returns (string memory) {
    bytes memory buffer = new bytes(7);
    buffer[0] = "#";
    buffer[2] = _HEX_SYMBOLS[uint8(r) & 0xf];
    r >>= 4;
    buffer[1] = _HEX_SYMBOLS[uint8(r) & 0xf];
    buffer[4] = _HEX_SYMBOLS[uint8(g) & 0xf];
    g >>= 4;
    buffer[3] = _HEX_SYMBOLS[uint8(g) & 0xf];
    buffer[6] = _HEX_SYMBOLS[uint8(b) & 0xf];
    b >>= 4;
    buffer[5] = _HEX_SYMBOLS[uint8(b) & 0xf];
    return string(buffer);
  }
  
  function toColorHexStringByBytes3(bytes3 rgb) public pure returns (string memory) {
    return toColorHexStringByBytes(rgb[0], rgb[1], rgb[2]);
  }

}