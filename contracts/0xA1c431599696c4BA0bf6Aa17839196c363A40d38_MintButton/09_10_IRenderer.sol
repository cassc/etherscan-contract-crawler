// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

/// @author  frolic.eth
/// @title   IRenderer
/// @notice  Upgradeable tokenURI interface
interface IRenderer {
    function tokenURI(uint256 tokenId) external view returns (string memory);
}