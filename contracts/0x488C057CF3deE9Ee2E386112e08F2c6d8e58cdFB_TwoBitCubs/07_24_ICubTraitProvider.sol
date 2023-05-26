// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma abicoder v2;

import "./ICubTraits.sol";

/// @title TwoBitCubs NFT Interface for provided ICubTraits
interface ICubTraitProvider{

    /// Returns the family of a TwoBitCub as a string
    /// @param traits The traits of the Cub
    /// @return The family text
    function familyForTraits(ICubTraits.TraitsV1 memory traits) external pure returns (string memory);

    /// Returns whether the TwoBitCub with the given DNA is adopted
    /// @param dna The DNA of the Cub
    /// @return Whether the cub is adopted
    function isAdopted(ICubTraits.DNA memory dna) external pure returns (bool);

    /// Returns the text of a mood based on the supplied type
    /// @param moodType The CubMoodType
    /// @return The mood text
    function moodForType(ICubTraits.CubMoodType moodType) external pure returns (string memory);

    /// Returns the mood of a TwoBitCub based on its TwoBitBear parents
    /// @param firstParentTokenId The ID of the token that represents the first parent
    /// @param secondParentTokenId The ID of the token that represents the second parent
    /// @return The mood type
    function moodFromParents(uint256 firstParentTokenId, uint256 secondParentTokenId) external view returns (ICubTraits.CubMoodType);

    /// Returns the name of a TwoBitCub as a string
    /// @param traits The traits of the Cub
    /// @return The name text
    function nameForTraits(ICubTraits.TraitsV1 memory traits) external pure returns (string memory);
    
    /// Returns the text of a species based on the supplied type
    /// @param speciesType The CubSpeciesType
    /// @return The species text
    function speciesForType(ICubTraits.CubSpeciesType speciesType) external pure returns (string memory);

    /// Returns the v1 traits associated with a given token ID.
    /// @dev Throws if the token ID is not valid.
    /// @param tokenId The ID of the token that represents the Cub
    /// @return traits memory
    function traitsV1(uint256 tokenId) external view returns (ICubTraits.TraitsV1 memory traits);
}