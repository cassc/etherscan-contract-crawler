// SPDX-License-Identifier: GPL-3.0

/// @title Interface for ShinySeeder

/*********************************
 * ･ﾟ･ﾟ✧.・･ﾟshiny.club・✫・゜･ﾟ✧ *
 *********************************/

pragma solidity ^0.8.9;

import { IShinyDescriptor } from './IShinyDescriptor.sol';

interface IShinySeeder {
    struct Seed {
        uint16 background;
        uint16 body;
        uint16 accessory;
        uint16 head;
        uint16 eyes;
        uint16 nose;
        uint16 mouth;
        uint16 shinyAccessory;
    }

    function generateSeedForMint(uint256 tokenId, IShinyDescriptor descriptor, bool isShiny) external view returns (Seed memory);

    function generateSeedWithValues(Seed memory newSeed,
                                    IShinyDescriptor descriptor,
                                    bool isShiny) external view returns (Seed memory);
}