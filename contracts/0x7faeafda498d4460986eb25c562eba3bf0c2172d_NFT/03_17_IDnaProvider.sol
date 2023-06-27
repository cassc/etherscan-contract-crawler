// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

/// @title Simple interface for fetching the DNA of a token.
/// @dev to be implemented for GameController.
interface IDnaProvider {
    /// @notice get the token ID.
    function getDna(uint256 tokenId) external view returns (uint256);
}