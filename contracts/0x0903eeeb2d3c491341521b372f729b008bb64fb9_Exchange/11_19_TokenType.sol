// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

/// @title types of tokens supported in the exchange contract in bytes format
library TokenType {
    bytes4 constant public ETH = bytes4(keccak256("ETH"));
    bytes4 constant public ERC20 = bytes4(keccak256("ERC20"));
    bytes4 constant public ERC721 = bytes4(keccak256("ERC721"));
    bytes4 constant public ERC1155 = bytes4(keccak256("ERC1155"));
}