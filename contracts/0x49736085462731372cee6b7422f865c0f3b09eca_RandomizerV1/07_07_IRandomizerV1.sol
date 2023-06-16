// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/// @title Interface for the Randomizer contract version 1
/// @author Particle Collection - valdi.eth
/// @notice Sets the random prime seeds for the collection on the core ERC721 contract
interface IRandomizerV1 {
    /// @notice Sets random prime seeds for the collection
    /// @dev Only callable by the core ERC721 contract
    function setCollectionSeeds(uint256 _collectionId) external;
}