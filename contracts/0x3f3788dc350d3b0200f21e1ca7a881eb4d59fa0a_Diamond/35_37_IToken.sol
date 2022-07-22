// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/// @notice the definition for a token.
struct TokenDefinition {
    // the host multitoken
    address token;
    // the name of the token
    string name;
    // the symbol of the token
    string symbol;
    // the description of the token
    string description;
    // the total supply of the token
    uint256 totalSupply;
    // probability of the item being awarded
    uint256 probability;
    // the index of the probability in its array
    uint256 probabilityIndex;
    // the index of the probability in its array
    uint256 probabilityRoll;
}