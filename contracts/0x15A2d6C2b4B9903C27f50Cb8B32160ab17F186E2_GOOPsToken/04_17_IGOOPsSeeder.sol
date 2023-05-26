// SPDX-License-Identifier: GPL-3.0



pragma solidity ^0.8.6;

import { IGOOPsDescriptor } from './IGOOPsDescriptor.sol';

interface IGOOPsSeeder {
    struct Seed {
        uint48 background;
        uint48 body;
        uint48 accessory;
        uint48 head;
        uint48 glasses;
    }

    function generateSeed(uint256 GOOPId, IGOOPsDescriptor descriptor) external view returns (Seed memory);
}