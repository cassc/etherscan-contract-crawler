// SPDX-License-Identifier: GPL-3.0

/// @title Interface for Seeder

pragma solidity ^0.8.6;

import { IDescriptor } from '../descriptor/IDescriptor.sol';

// "Skin", "Cloth", "Eye", "Mouth", "Acc", "Item", "Hat"
interface ISeeder {
    struct Seed {
        uint48 background;
        uint48 skin;
        uint48 clothes;
        uint48 eyes;
        uint48 mouth;
        uint48 accessory;
        uint48 bgItem;
        uint48 hat;
        bool oneOfOne;
        uint48 oneOfOneIndex;
    }

    function generateSeed(uint256 wizardId, IDescriptor descriptor, bool isOneOfOne, uint48 isOneOfOneIndex) external view returns (Seed memory);
}