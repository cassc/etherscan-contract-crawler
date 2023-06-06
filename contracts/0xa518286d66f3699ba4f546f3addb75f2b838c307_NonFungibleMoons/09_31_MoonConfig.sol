// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {LibPRNG} from "../utils/LibPRNG.sol";
import {Traits} from "../utils/Traits.sol";
import {Utils} from "../utils/Utils.sol";
import {MoonImageConfig, MoonImageColors} from "./MoonStructs.sol";

/// @title MoonConfig
/// @author Aspyn Palatnick (aspyn.eth, stuckinaboot.eth)
library MoonConfig {
    using LibPRNG for LibPRNG.PRNG;

    function getMoonSeed(uint256 tokenId) internal view returns (bytes32) {
        return keccak256(abi.encodePacked(tokenId, block.difficulty));
    }

    function getFrameTraits(
        MoonImageConfig memory moonConfig
    ) internal pure returns (string memory) {
        bool hasFrame = moonConfig.borderWidth > 0;
        return
            string.concat(
                Traits.getTrait(
                    "Frame roundness",
                    moonConfig.borderRadius,
                    true
                ),
                Traits.getTrait(
                    "Frame thickness",
                    moonConfig.borderWidth,
                    true
                ),
                Traits.getTrait(
                    "Frame type",
                    hasFrame ? moonConfig.borderType : "Invisible",
                    true
                ),
                hasFrame ? Traits.getTrait(
                    "Frame tint",
                    uint256(moonConfig.colors.borderSaturation),
                    true
                ) : ""
            );
    }

    function getMoonTraits(
        bytes32 moonSeed,
        string memory alienArtTrait,
        string memory alienArtName,
        string memory alienArtAddressStr,
        bool isDefaultAlienArt
    ) internal pure returns (string memory) {
        MoonImageConfig memory moonConfig = getMoonConfig(moonSeed);

        // Evaluate groups of traits to (1) better organize code (2) avoid stack too deep errors
        string memory frameTraits = getFrameTraits(moonConfig);

        string memory alienArtAllTraits = string.concat(
            Traits.getTrait(
                "Is default alien art",
                // This needs to be included as a boolean rather than a check
                // agains the default name since the name can be impersonated by another contract
                isDefaultAlienArt ? "Yes" : "No",
                true
            ),
            // Include alien art address so others can discover alien art
            // used by different moons
            Traits.getTrait("Alien art address", alienArtAddressStr, true),
            Traits.getTrait(
                "Alien art",
                alienArtName,
                // Include comma if alien art trait is defined
                // by doing length of alienArtTrait comparison
                bytes(alienArtTrait).length > 0
            ),
            alienArtTrait
        );

        return
            string.concat(
                "[",
                Traits.getTrait(
                    "Moon hue",
                    uint256(moonConfig.colors.moonHue),
                    true
                ),
                frameTraits,
                Traits.getTrait(
                    "Space darkness",
                    uint256(moonConfig.colors.backgroundLightness),
                    true
                ),
                Traits.getTrait(
                    "Has space gradient",
                    bytes(moonConfig.colors.backgroundGradientColor).length > 0
                        ? "Yes"
                        : "No",
                    true
                ),
                alienArtAllTraits,
                "]"
            );
    }

    function getBorderType(LibPRNG.PRNG memory prng)
        internal
        pure
        returns (string memory)
    {
        // Choose border type based on different weightings
        uint256 psuedoRandomOutOf100 = prng.uniform(100);
        if (psuedoRandomOutOf100 < 70) {
            return "solid";
        }
        if (psuedoRandomOutOf100 < 90) {
            return "inset";
        }
        return "outset";
    }

    function getMoonImageColors(LibPRNG.PRNG memory prng)
        internal
        pure
        returns (MoonImageColors memory)
    {
        uint16 moonHue = uint16(prng.uniform(360));
        uint8 borderSaturation = uint8(prng.uniform(71));
        uint8 backgroundLightness = uint8(prng.uniform(11));

        return
            MoonImageColors({
                moon: hslaString(moonHue, 50, 50),
                moonHue: moonHue,
                border: hslaString(moonHue, borderSaturation, 50),
                borderSaturation: borderSaturation,
                background: hslaString(0, 0, backgroundLightness),
                backgroundLightness: backgroundLightness,
                backgroundGradientColor: // Bias gradient to occur 33% of the time
                prng.uniform(3) == 0
                    ? hslaString(
                        // Derive hue from moon hue
                        moonHue,
                        50,
                        50
                    )
                    : ""
            });
    }

    function getMoonConfig(bytes32 moonSeed)
        internal
        pure
        returns (MoonImageConfig memory)
    {
        uint16 moonRadius = 32;
        uint16 viewSize = 200;
        uint16 offset = (viewSize - 2 * moonRadius) / 2;

        LibPRNG.PRNG memory prng;
        prng.seed(keccak256(abi.encodePacked(moonSeed, uint256(5))));

        // Border radius can vary from 0 to 50%
        uint16 borderRadius = prng.uniform(9) == 0 // 11% chance of having a circular border
            ? 50 // Otherwise, choose a border radius between 0 and 5
            : uint16(prng.uniform(6));

        // Border width can vary from 0 to 4
        uint16 borderWidth = uint16(prng.uniform(5));

        MoonImageColors memory colors = getMoonImageColors(prng);
        string memory borderType = getBorderType(prng);
        
        return
            MoonImageConfig({
                colors: colors,
                moonRadius: moonRadius,
                xOffset: offset,
                yOffset: offset,
                viewWidth: viewSize,
                viewHeight: viewSize,
                borderRadius: borderRadius,
                borderWidth: borderWidth,
                borderType: borderType
            });
    }

    // Helpers

    function hslaString(
        uint16 hue,
        uint8 saturation,
        uint8 lightness
    ) internal pure returns (string memory) {
        return
            string.concat(
                "hsla(",
                Utils.uint2str(hue),
                ",",
                Utils.uint2str(saturation),
                "%,",
                Utils.uint2str(lightness),
                "%,100%)"
            );
    }
}