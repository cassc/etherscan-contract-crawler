// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.6;

import {IGnarDescriptorV2} from "./IGNARDescriptorV2.sol";

interface IGnarSeederV2 {
    struct Seed {
        uint48 background;
        uint48 body;
        uint48 accessory;
        uint48 head;
        uint48 glasses;
    }

    function generateSeed(uint256 gnarId, IGnarDescriptorV2 descriptor) external view returns (Seed memory);
}