// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.14;

// Generated code. Do not modify!

/// @title  AlphaDogs Chromossome Generator Library
/// @author Aleph Retamal <github.com/alephao>
/// @notice Library containing functions to pick AlphaDogs chromossomes from an uint256 seed.
library Chromossomes {
    // Each of those seedTo{Trait} function select 4 bytes from the seed
    // and use those selected bytes to pick a trait using the A.J. Walker
    // algorithm. The rarity and aliases are calculated beforehand.

    function seedToBackground(uint256 seed) internal pure returns (uint256) {
        unchecked {
            uint256 traitSeed = (seed >> 16) & 0xFFFF;
            uint256 trait = traitSeed % 21;
            if (
                traitSeed >> 8 <
                [
                    154,
                    222,
                    166,
                    200,
                    150,
                    333,
                    97,
                    158,
                    33,
                    162,
                    44,
                    170,
                    93,
                    234,
                    123,
                    94,
                    345,
                    134,
                    66,
                    255,
                    99
                ][trait]
            ) return trait;
            return
                [
                    1,
                    20,
                    1,
                    2,
                    1,
                    3,
                    3,
                    3,
                    5,
                    5,
                    13,
                    9,
                    16,
                    11,
                    16,
                    16,
                    13,
                    16,
                    19,
                    16,
                    19
                ][trait];
        }
    }

    function seedToFur(uint256 seed) internal pure returns (uint256) {
        unchecked {
            uint256 traitSeed = (seed >> 32) & 0xFFFF;
            uint256 trait = traitSeed % 12;
            if (
                traitSeed >> 8 <
                [44, 345, 299, 450, 460, 88, 166, 177, 369, 470, 188, 277][
                    trait
                ]
            ) return trait;
            return [3, 11, 1, 2, 3, 4, 9, 9, 4, 8, 9, 9][trait];
        }
    }

    function seedToNeck(uint256 seed) internal pure returns (uint256) {
        unchecked {
            uint256 traitSeed = (seed >> 48) & 0xFFFF;
            uint256 trait = traitSeed % 34;
            if (
                traitSeed >> 8 <
                [
                    140,
                    333,
                    147,
                    134,
                    878,
                    92,
                    53,
                    100,
                    25,
                    115,
                    90,
                    122,
                    40,
                    6,
                    9,
                    130,
                    3,
                    5,
                    222,
                    4,
                    45,
                    52,
                    57,
                    23,
                    98,
                    50,
                    48,
                    95,
                    27,
                    21,
                    55,
                    47,
                    32,
                    35
                ][trait]
            ) return trait;
            return
                [
                    33,
                    0,
                    1,
                    2,
                    3,
                    0,
                    1,
                    4,
                    1,
                    7,
                    1,
                    9,
                    1,
                    2,
                    4,
                    11,
                    4,
                    4,
                    15,
                    4,
                    4,
                    4,
                    4,
                    4,
                    4,
                    4,
                    4,
                    4,
                    4,
                    4,
                    9,
                    15,
                    18,
                    18
                ][trait];
        }
    }

    function seedToEyes(uint256 seed) internal pure returns (uint256) {
        unchecked {
            uint256 traitSeed = (seed >> 64) & 0xFFFF;
            uint256 trait = traitSeed % 43;
            if (
                traitSeed >> 8 <
                [
                    30,
                    21,
                    89,
                    7,
                    500,
                    135,
                    52,
                    59,
                    125,
                    88,
                    22,
                    81,
                    120,
                    228,
                    15,
                    90,
                    32,
                    39,
                    17,
                    83,
                    42,
                    12,
                    82,
                    100,
                    84,
                    20,
                    58,
                    56,
                    28,
                    180,
                    40,
                    35,
                    54,
                    55,
                    86,
                    85,
                    24,
                    53,
                    240,
                    80,
                    44,
                    26,
                    16
                ][trait]
            ) return trait;
            return
                [
                    4,
                    4,
                    42,
                    4,
                    2,
                    4,
                    4,
                    4,
                    5,
                    8,
                    4,
                    9,
                    11,
                    12,
                    4,
                    13,
                    4,
                    4,
                    5,
                    15,
                    8,
                    12,
                    19,
                    22,
                    23,
                    13,
                    13,
                    13,
                    13,
                    24,
                    22,
                    29,
                    29,
                    29,
                    29,
                    34,
                    35,
                    38,
                    35,
                    38,
                    38,
                    38,
                    39
                ][trait];
        }
    }

    function seedToHat(uint256 seed) internal pure returns (uint256) {
        unchecked {
            uint256 traitSeed = (seed >> 80) & 0xFFFF;
            uint256 trait = traitSeed % 68;
            if (
                traitSeed >> 8 <
                [
                    18,
                    4,
                    30,
                    35,
                    28,
                    45,
                    46,
                    25,
                    48,
                    22,
                    20,
                    1260,
                    38,
                    43,
                    24,
                    59,
                    38,
                    29,
                    56,
                    30,
                    7,
                    18,
                    25,
                    23,
                    58,
                    42,
                    22,
                    9,
                    6,
                    15,
                    35,
                    22,
                    12,
                    66,
                    27,
                    27,
                    44,
                    46,
                    37,
                    11,
                    28,
                    38,
                    15,
                    42,
                    40,
                    60,
                    37,
                    28,
                    53,
                    50,
                    15,
                    12,
                    5,
                    40,
                    30,
                    8,
                    18,
                    49,
                    48,
                    29,
                    30,
                    10,
                    44,
                    3,
                    35,
                    35,
                    46,
                    35
                ][trait]
            ) return trait;
            return
                [
                    11,
                    11,
                    11,
                    11,
                    11,
                    11,
                    11,
                    11,
                    11,
                    11,
                    11,
                    67,
                    11,
                    11,
                    11,
                    11,
                    11,
                    11,
                    15,
                    11,
                    11,
                    11,
                    11,
                    11,
                    18,
                    11,
                    11,
                    11,
                    11,
                    11,
                    11,
                    11,
                    11,
                    24,
                    11,
                    11,
                    11,
                    11,
                    11,
                    11,
                    11,
                    11,
                    11,
                    11,
                    11,
                    33,
                    11,
                    11,
                    45,
                    48,
                    11,
                    11,
                    11,
                    11,
                    11,
                    11,
                    11,
                    11,
                    11,
                    11,
                    11,
                    11,
                    11,
                    18,
                    33,
                    33,
                    45,
                    49
                ][trait];
        }
    }

    function seedToMouth(uint256 seed) internal pure returns (uint256) {
        unchecked {
            uint256 traitSeed = (seed >> 96) & 0xFFFF;
            uint256 trait = traitSeed % 18;
            if (
                traitSeed >> 8 <
                [
                    156,
                    96,
                    1480,
                    48,
                    333,
                    96,
                    84,
                    32,
                    156,
                    72,
                    24,
                    60,
                    72,
                    84,
                    120,
                    120,
                    168,
                    132
                ][trait]
            ) return trait;
            return
                [2, 2, 17, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 4, 4, 4, 4][trait];
        }
    }

    function seedToNosering(uint256 seed) internal pure returns (uint256) {
        unchecked {
            uint256 traitSeed = (seed >> 112) & 0xFFFF;
            uint256 trait = traitSeed % 4;
            if (traitSeed >> 8 < [3201, 12, 84, 36][trait]) return trait;
            return [3, 0, 0, 0][trait];
        }
    }
}