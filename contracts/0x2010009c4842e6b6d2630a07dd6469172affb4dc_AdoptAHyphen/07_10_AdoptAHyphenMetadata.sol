// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {LibString} from "solady/utils/LibString.sol";
import {AdoptAHyphenArt} from "./AdoptAHyphenArt.sol";

/// @title adopt-a-hyphen metadata
/// @notice A library for generating metadata for {AdoptAHyphen}.
/// @dev For this library to be correct, all `_seed` values must be consistent
/// with every function in both {AdoptAHyphenArt} and {AdoptAHyphenMetadata}.
library AdoptAHyphenMetadata {
    using LibString for string;
    using LibString for uint256;

    /// @notice Number of bits used to generate the art. We take note of this
    /// because we don't want to use the same bits to generate the metadata.
    uint256 constant BITS_USED = 47;

    /// @notice Joined list of adjectives to use when generating the name with
    /// `_` as the delimiter.
    /// @dev To read from this constant, use
    /// `LibString.split(string(ADJECTIVES), "_")`.
    bytes constant ADJECTIVES =
        "All-Important_Angel-Faced_Awe-Inspiring_Battle-Scarred_Big-Boned_Bird-"
        "Like_Black-and-White_Breath-Taking_Bright-Eyed_Broad-Shouldered_Bull-H"
        "eaded_Butter-Soft_Cat-Eyed_Cool-Headed_Cross-Eyed_Death-Defying_Devil-"
        "May-Care_Dew-Fresh_Dim-Witted_Down-to-Earth_Eagle-Nosed_Easy-Going_Eve"
        "r-Changing_Faint-Hearted_Feather-Brained_Fish-Eyed_Fly-by-Night_Free-T"
        "hinking_Fun-Loving_Half-Baked_Hawk-Eyed_Heart-Breaking_High-Spirited_H"
        "oney-Dipped_Honey-Tongued_Ice-Cold_Ill-Gotten_Iron-Grey_Iron-Willed_Ke"
        "en-Eyed_Kind-Hearted_Left-Handed_Lion-Hearted_Off-the-Grid_Open-Faced_"
        "Pale-Faced_Razor-Sharp_Red-Faced_Rosy-Cheeked_Ruby-Red_Self-Satisfied_"
        "Sharp-Nosed_Short-Sighted_Silky-Haired_Silver-Tongued_Sky-Blue_Slow-Fo"
        "oted_Smooth-as-Silk_Smooth-Talking_Snake-Like_Snow-Cold_Snow-White_Sof"
        "t-Voiced_Sour-Faced_Steel-Blue_Stiff-Necked_Straight-Laced_Strong-Mind"
        "ed_Sugar-Sweet_Thick-Headed_Tight-Fisted_Tongue-in-Cheek_Tough-Minded_"
        "Trigger-Happy_Velvet-Voiced_Water-Washed_White-Faced_Wide-Ranging_Wild"
        "-Haired_Wishy-Washy_Work-Weary_Yellow-Bellied_Camera-Shy_Cold-as-Ice_E"
        "mpty-Handed_Fair-Weather_Fire-Breathing_Jaw-Dropping_Mind-Boggling_No-"
        "Nonsense_Rough-and-ready_Slap-Happy_Smooth-Faced_Snail-Paced_Soul-Sear"
        "ching_Star-Studded_Tongue-Tied_Too-Good-to-be-True_Turtle-Necked_Diamo"
        "nd-Handed";

    /// @notice Joined list of first names to use when generating the name with
    /// `_` as the delimiter.
    /// @dev To read from this constant, use
    /// `LibString.split(string(FIRST_NAMES), "_")`.
    bytes constant FIRST_NAMES =
        "Alexis_Ali_Alicia_Andres_Asha_Barb_Betty_Bruce_Charles_Chris_Coco_Dan_"
        "David_Dennis_Elijah_Eugene_James_Jayden_Jenny_Jess_Joe_John_Jose_Karen"
        "_Linda_Lisa_Liz_Marco_Mark_Mary_Matt_Mert_Mike_Mirra_Nancy_Noor_Novak_"
        "Patty_Peggy_Ravi_Richard_Robert_Sandra_Sarah_Sue_Tayne_Tom_Tony_Will_Y"
        "ana";

    /// @notice Joined list of hue names to use when generating the name with
    /// `_` as the delimiter.
    /// @dev To read from this constant, use
    /// `LibString.split(string(HUES), "_")`.
    bytes constant HUES = "red_blue_orange_teal_pink_green_purple_gray";

    /// @notice Joined list of hobbies to use when generating the name with `_`
    /// as the delimiter.
    /// @dev To read from this constant, use
    /// `LibString.split(string(HOBBIES), "_")`.
    bytes constant HOBBIES =
        "blit-mapp_terra-form_shield-build_loot-bagg_OKPC-draw_mooncat-rescu_au"
        "to-glyph_animal-color_ava-starr_party-card_chain-runn_forgotten-run_bi"
        "bo-glint";

    /// @notice Generates a Hyphen Guy name.
    /// @param _seed Seed to select traits for the Hyphen Guy.
    /// @return Hyphen Guy's name.
    function generateName(uint256 _seed) internal pure returns (string memory) {
        string[] memory adjectives = string(ADJECTIVES).split("_");
        string[] memory firstNames = string(FIRST_NAMES).split("_");

        _seed >>= BITS_USED;

        return
            string.concat(
                firstNames[(_seed >> 7) % 50], // Adjectives used 7 bits
                " ",
                adjectives[_seed % 100]
            );
    }

    /// @notice Generates a Hyphen Guy's attributes.
    /// @param _seed Seed to select traits for the Hyphen Guy.
    /// @return Hyphen Guy's attributes.
    function generateAttributes(
        uint256 _seed
    ) internal pure returns (string memory) {
        string[] memory hues = string(HUES).split("_");
        string[] memory hobbies = string(HOBBIES).split("_");

        // We directly use the value of `_seed` because we don't need further
        // randomness.
        // The bits used to determine the color value are bits [24, 27]
        // (0-indexed). See {AdoptAHyphenArt.render} for more information.
        uint256 background = (_seed >> 24) % 9;

        // The bits used to determine whether the background is in ``intensity
        // mode'' or not are bits [30, 31] (0-indexed). See
        // {AdoptAHyphenArt.render} for more information.
        bool intensityMode = ((_seed >> 30) & 3) == 0;

        // The bits used to determine the color value are bits [43, 45]
        // (0-indexed). See {AdoptAHyphenArt.render} for more information.
        uint256 color = (_seed >> 43) & 7;

        // The art renderer uses the last `BITS_USED` bits to generate its
        // traits, and `generateName` uses 12 bits to generate the name, so we
        // shift those portions off.
        _seed >>= BITS_USED;
        _seed >>= 12;
        uint256 rizz = _seed % 101; // [0, 100] (7 bits)
        _seed >>= 7;
        uint256 hobby = _seed % 13; // 13 hobbies (4 bits)
        _seed >>= 4;

        return
            string.concat(
                '[{"trait_type":"hue","value":"',
                hues[color],
                '"},',
                '{"trait_type":"vibe","value":"',
                background == 6
                    ? "\\\\"
                    : string(
                        abi.encodePacked(
                            AdoptAHyphenArt.BACKGROUNDS[background]
                        )
                    ),
                '"},{"trait_type":"demeanor","value":"',
                intensityMode ? "ex" : "in",
                'troverted"},{"trait_type":"hobby","value":"',
                hobbies[hobby],
                'ing"},{"trait_type":"rizz","value":',
                rizz.toString(),
                "}]"
            );
    }
}