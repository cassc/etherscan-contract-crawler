// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import '@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol';
import '@openzeppelin/contracts/utils/Strings.sol';

library ERC20Metadata {
  function bytes32ToString(bytes32 x) private pure returns (string memory) {
    bytes memory bytesString = new bytes(32);
    uint256 charCount = 0;
    for (uint256 j = 0; j < 32; j++) {
      bytes1 char = x[j];
      if (char != 0) {
        bytesString[charCount] = char;
        charCount++;
      }
    }
    bytes memory bytesStringTrimmed = new bytes(charCount);
    for (uint256 j = 0; j < charCount; j++) {
      bytesStringTrimmed[j] = bytesString[j];
    }
    return string(bytesStringTrimmed);
  }

  // calls an external view token contract method that returns a symbol or name, and parses the output into a string
  function callAndParseStringReturn(address token, bytes4 selector)
    private
    view
    returns (string memory)
  {
    (bool success, bytes memory data) = token.staticcall(abi.encodeWithSelector(selector));
    // if not implemented, or returns empty data, return empty string
    if (!success || data.length == 0) {
      return '';
    }
    // bytes32 data always has length 32
    if (data.length == 32) {
      bytes32 decoded = abi.decode(data, (bytes32));
      return bytes32ToString(decoded);
    } else if (data.length > 64) {
      return abi.decode(data, (string));
    }
    return '';
  }

  // attempts to extract the token symbol. if it does not implement symbol, returns a symbol derived from the address
  function tokenSymbol(address token) external view returns (string memory) {
    string memory symbol = callAndParseStringReturn(token, IERC20Metadata.symbol.selector);
    if (bytes(symbol).length == 0) {
      // fallback to 6 uppercase hex of address
      return Strings.toHexString(uint256(keccak256(abi.encode(token))), 32);
    }
    return symbol;
  }

  // attempts to extract the token name. if it does not implement name, returns a name derived from the address
  function tokenName(address token) external view returns (string memory) {
    string memory name = callAndParseStringReturn(token, IERC20Metadata.name.selector);
    if (bytes(name).length == 0) {
      // fallback to full hex of address
      return Strings.toHexString(uint256(keccak256(abi.encode(token))), 32);
    }
    return name;
  }
}