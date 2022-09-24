// SPDX-License-Identifier: GPL-3.0

/// @title Common interface for ShinyDescriptor versions, as used by ShinyToken and ShinySeeder.

/*********************************
 * ･ﾟ･ﾟ✧.・･ﾟshiny.club・✫・゜･ﾟ✧ *
 *********************************/

pragma solidity ^0.8.9;

import { IShinySeeder } from './IShinySeeder.sol';

interface IShinyDescriptorMinimal {
    ///
    /// USED BY TOKEN
    ///

    function tokenURI(uint256 tokenId, IShinySeeder.Seed memory seed, bool isShiny) external view returns (string memory);

    function dataURI(uint256 tokenId, IShinySeeder.Seed memory seed, bool isShiny) external view returns (string memory);

    ///
    /// USED BY SEEDER
    ///

    function backgroundCount() external view returns (uint256);

    function bodyCount() external view returns (uint256);

    function accessoryCount() external view returns (uint256);

    function headCount() external view returns (uint256);

    function eyesCount() external view returns (uint256);

    function nosesCount() external view returns (uint256);

    function mouthsCount() external view returns (uint256);

    function shinyAccessoryCount() external view returns (uint256);
}