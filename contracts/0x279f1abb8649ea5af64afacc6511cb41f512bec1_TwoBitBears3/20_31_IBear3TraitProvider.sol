// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IBear3Traits.sol";

/// @title Gen 3 TwoBitBear traits provider
/// @notice Provides IBear3Traits to the blockchain
interface IBear3TraitProvider{

    /// Returns the traits associated with a given token ID
    /// @dev Throws if the token ID is not valid
    /// @param tokenId The ID of the token that represents the Bear
    /// @return traits memory
    function bearTraits(uint256 tokenId) external view returns (IBear3Traits.Traits memory);

    /// Returns whether a Gen 2 Bear (TwoBitCubs) has breeded a Gen 3 TwoBitBear
    /// @dev Does not throw if the tokenId is not valid
    /// @param tokenId The token ID of the Gen 2 bear
    /// @return Returns whether the Gen 2 Bear has mated
    function hasGen2Mated(uint256 tokenId) external view returns (bool);

    /// Returns whether a Gen 3 Bear has produced a Gen 4 TwoBitBear
    /// @dev Throws if the token ID is not valid
    /// @param tokenId The token ID of the Gen 3 bear
    /// @return Returns whether the Gen 3 Bear has been used for Gen 4 minting
    function generation4Claimed(uint256 tokenId) external view returns (bool);

    /// Returns the scar colors of a given token Id
    /// @dev Throws if the token ID is not valid or if not revealed
    /// @param tokenId The token ID of the Gen 3 bear
    /// @return Returns the scar colors
    function scarColors(uint256 tokenId) external view returns (IBear3Traits.ScarColor[] memory);
}