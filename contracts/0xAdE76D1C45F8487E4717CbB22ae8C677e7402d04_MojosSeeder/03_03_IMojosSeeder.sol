// SPDX-License-Identifier: GPL-3.0

/// @title Interface for MojosSeeder

/*********************************
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░███████████████████████░░░ *
 * ░░░░░░█████████████████░░░░░░ *
 * ░░░░░░█████████████████░░░░░░ *
 * ░░░░░░█████████████████░░░░░░ *
 * ░░░░░░█████████████████░░░░░░ *
 * ░░░░░░█████████████████░░░░░░ *
 *********************************/

pragma solidity ^0.8.6;

import { IMojosDescriptor } from './IMojosDescriptor.sol';

interface IMojosSeeder {
    struct Seed {
        uint48 background;
        uint48 body;
        uint48 bodyAccessory;
        uint48 face;
        uint48 headAccessory;
    }

    function generateSeed(uint256 mojoId, IMojosDescriptor descriptor) external view returns (Seed memory);
}