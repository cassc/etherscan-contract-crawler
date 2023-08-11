// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.20;

/// @dev Token type used for payment tokens to specify payment is in the blockchain native token
uint256 constant TOKEN_TYPE_NATIVE  = 0;
/// @dev Token type used for payments, mints and burns to specify the token is an ERC20
uint256 constant TOKEN_TYPE_ERC20 = 1;
/// @dev Token type used for mints and burns to specify the token is an ERC721
uint256 constant TOKEN_TYPE_ERC721 = 2;
/// @dev Token type used for mints and burns to specify the token is an ERC1155
uint256 constant TOKEN_TYPE_ERC1155 = 3;