// SPDX-License-Identifier: GPL-3.0

/// @title IToken interface

pragma solidity ^0.8.6;

interface IToken {
    function mintAdmin(uint256 quantity, address to) external;
    function battleTransfer(address from, address to, uint256 tokenId) external;
}