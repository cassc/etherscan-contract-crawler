// SPDX-License-Identifier: GPL-3.0

/// Based on Nouns

pragma solidity ^0.8.6;

import {iDescriptorMinimal} from "./iDescriptorMinimal.sol";

interface iSeeder {
    struct Seed {
        uint64 background;
        uint64 sky;
        uint64 pepe;
        uint64 altitude;
    }

    //prettier-ignore
    function generateSeed(uint256 tokenId, uint256 quantity_, iDescriptorMinimal descriptor) external view returns (Seed memory);

    //prettier-ignore
    function reachNewAltitude(uint256 newAltitude_) external view returns (Seed memory);
}