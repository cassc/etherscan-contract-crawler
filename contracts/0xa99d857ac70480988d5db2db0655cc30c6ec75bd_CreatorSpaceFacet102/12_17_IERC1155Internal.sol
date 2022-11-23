// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/**
 * @title Partial ERC1155 interface needed by internal functions
 */
interface IERC1155Internal {
  event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);
}
