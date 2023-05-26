// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ISVG.sol";

/// @title Interface for accessing official TwoBitBears data
interface IBearable {

    /// Represents the species of a TwoBitBear
    enum BearSpeciesType {
        Brown, Black, Polar, Panda
    }

    /// Represents the mood of a TwoBitBear
    enum BearMoodType {
        Happy, Hungry, Sleepy, Grumpy
    }

    /// Returns whether the TwoBitBear at tokenId currently belongs to the owner
    /// @dev Throws if the token ID is not valid.
    function ownsBear(address possibleOwner, uint256 tokenId) external view returns (bool);

    /// Returns the total tokens in the TwoBitBear contract
    function totalBears() external view returns (uint256);

    /// Returns the realistic body fur color of the TwoBitBear at tokenId
    /// @dev Throws if the token ID is not valid.
    function bearBottomColor(uint256 tokenId) external view returns (ISVG.Color memory color);

    /// Returns the all-important `BearMoodType` of the TwoBitBear at tokenId (be nice)
    /// @dev Throws if the token ID is not valid.
    function bearMood(uint256 tokenId) external view returns (BearMoodType);

    /// Returns the BearSpeciesType of the TwoBitBear at tokenId
    /// @dev Throws if the token ID is not valid.
    function bearSpecies(uint256 tokenId) external view returns (BearSpeciesType);

    /// Returns the realistic head fur color of the TwoBitBear at tokenId
    /// @dev Throws if the token ID is not valid.
    function bearTopColor(uint256 tokenId) external view returns (ISVG.Color memory color);
}