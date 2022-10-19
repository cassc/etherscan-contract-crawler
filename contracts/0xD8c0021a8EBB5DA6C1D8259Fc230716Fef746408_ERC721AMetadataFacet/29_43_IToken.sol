// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/// @notice the definition for a token.
struct TokenDefinition {
    address token;
    string name;
    string symbol;
    string description;
    uint256 totalSupply;
    string imageName;
    string[] imagePalette;
    string externalUrl;
}

enum TokenType {
    ERC20,
    ERC721,
    ERC1155
}