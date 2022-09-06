// SPDX-License-Identifier: GPL-3.0

/// @title IToken interface

pragma solidity ^0.8.6;

interface IToken {
    function saleActive() external returns (bool);
    function maxMintsPerTx() external returns (uint256);
    function maxTokens() external returns (uint256);
    function price() external returns (uint256);
    function mintAdmin(uint256 quantity, address to) external;
    function battleTransfer(address from, address to, uint256 tokenId) external;
}