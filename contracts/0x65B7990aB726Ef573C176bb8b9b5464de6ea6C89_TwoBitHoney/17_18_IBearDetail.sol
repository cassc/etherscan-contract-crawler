// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title TwoBitBears NFT Detail Interface
interface IBearDetail {

    /// Represents the colors of a TwoBitBear
    struct Color {
        uint8 red;
        uint8 green;
        uint8 blue;
    }

    /// Represents the details of a TwoBitBear
    struct Detail {
        uint256 timestamp;
        uint8 nameIndex;
        uint8 moodIndex;
        uint8 familyIndex;
        uint8 speciesIndex;
        Color topColor;
        Color bottomColor;
    }
    
    /// Returns the details associated with a given token ID.
    /// @dev Throws if the token ID is not valid.
    /// @param tokenId The ID of the token that represents the Bear
    /// @return detail memory
    function details(uint256 tokenId) external view returns (Detail memory detail);
}