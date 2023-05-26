// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ISVG.sol";

/// @title ICubTraits interface
interface ICubTraits {

    /// Represents the species of a TwoBitCub
    enum CubSpeciesType {
        Brown, Black, Polar, Panda
    }

    /// Represents the mood of a TwoBitCub
    enum CubMoodType {
        Happy, Hungry, Sleepy, Grumpy, Cheerful, Excited, Snuggly, Confused, Ravenous, Ferocious, Hangry, Drowsy, Cranky, Furious
    }

    // Represents the DNA for a TwoBitCub
    struct DNA {
        uint256 genes;
        uint16 firstParentTokenId;
        uint16 secondParentTokenId;
    }

    /// Represents the v1 traits of a TwoBitCub
    /// @dev so...there'll be more?
    struct TraitsV1 {
        uint256 age;
        ISVG.Color topColor;
        ISVG.Color bottomColor;
        uint8 nameIndex;
        uint8 familyIndex;
        CubMoodType mood;
        CubSpeciesType species;
    }
}