// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.6;

import {IGnarDescriptor} from "./IGNARDescriptor.sol";

interface IGnarSeeder {
    struct Seed {
        uint48 background;
        uint48 body;
        uint48 accessory;
        uint48 head;
        uint48 glasses;
    }

    function generateSeed(uint256 nounId, IGnarDescriptor descriptor)
        external
        view
        returns (Seed memory);
}