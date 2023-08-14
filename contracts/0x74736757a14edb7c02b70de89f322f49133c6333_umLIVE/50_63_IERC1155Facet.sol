// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

abstract contract IERC1155Facet {
    error ExceedsMaxSupply();
    error InvalidTokenID();
    error InvalidAmount();
    error InvalidMaxSupply();
}