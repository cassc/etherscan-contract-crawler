// SPDX-License-Identifier: MIT
// Copyright (c) 2023 Fellowship

pragma solidity ^0.8.7;

abstract contract MintableById {
    function mint(address to, uint256 tokenId) external virtual;
}