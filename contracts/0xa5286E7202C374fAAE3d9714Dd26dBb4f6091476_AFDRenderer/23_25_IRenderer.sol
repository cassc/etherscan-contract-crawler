// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

/// @author frolic.eth
/// @title  Upgradeable renderer interface
/// @notice This leaves room for us to change how we return token metadata and
///         unlocks future capability like fully on-chain storage.
interface IRenderer {
    function tokenURI(uint256 tokenId) external view returns (string memory);
}