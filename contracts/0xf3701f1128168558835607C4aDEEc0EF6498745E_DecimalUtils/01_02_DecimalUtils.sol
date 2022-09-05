// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;
import '@openzeppelin/contracts/utils/Strings.sol';

library DecimalUtils {
  using Strings for uint256;

  function padZeros(string memory s, uint256 len)
    public
    pure
    returns (string memory)
  {
    uint256 local_len = bytes(s).length;
    string memory local_s = s;
    while (local_len < len) {
      local_s = string(abi.encodePacked('0', local_s));
      local_len++;
    }
    return local_s;
  }

  function wholeNumber(uint256 n, uint256 numDecimals)
    public
    pure
    returns (uint256)
  {
    return n / oneUnit(numDecimals);
  }

  function decimals(uint256 n, uint256 numDecimals)
    public
    pure
    returns (uint256)
  {
    return n % oneUnit(numDecimals);
  }

  function oneUnit(uint256 numDecimals) public pure returns (uint256) {
    return 10**numDecimals;
  }

  function toDecimalString(uint256 n, uint256 numDecimals)
    public
    pure
    returns (string memory s)
  {
    if (n == 0) return '0';
    uint256 unit = oneUnit(numDecimals);
    s = string(
      abi.encodePacked(
        (n / (unit)).toString(),
        '.',
        padZeros((n % unit).toString(), numDecimals)
      )
    );
  }
}