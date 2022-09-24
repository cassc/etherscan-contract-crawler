// SPDX-License-Identifier: GPL-3.0

/// @title Interface for ShinyDescriptor

/*********************************
 * ･ﾟ･ﾟ✧.・･ﾟshiny.club・✫・゜･ﾟ✧ *
 *********************************/

pragma solidity ^0.8.9;

import { IShinySeeder } from './IShinySeeder.sol';

interface IShinyDescriptor {
    event PartsLocked();

    function arePartsLocked() external returns (bool);

    function palettes(uint8 paletteIndex, uint256 colorIndex) external view returns (string memory);

    function backgrounds(uint256 index) external view returns (string memory);

    function bodies(uint256 index) external view returns (bytes memory);

    function accessories(uint256 index) external view returns (bytes memory);

    function heads(uint256 index) external view returns (bytes memory);

    function eyes(uint256 index) external view returns (bytes memory);

    function noses(uint256 index) external view returns (bytes memory);

    function mouths(uint256 index) external view returns (bytes memory);

    function shinyAccessories(uint256 index) external view returns (bytes memory);

    function backgroundCount() external view returns (uint256);

    function bodyCount() external view returns (uint256);

    function accessoryCount() external view returns (uint256);

    function headCount() external view returns (uint256);

    function eyesCount() external view returns (uint256);

    function nosesCount() external view returns (uint256);

    function mouthsCount() external view returns (uint256);

    function shinyAccessoriesCount() external view returns (uint256);

    function addManyColorsToPalette(uint8 paletteIndex, string[] calldata newColors) external;

    function addManyBackgrounds(string[] calldata backgrounds) external;

    function addManyBodies(bytes[] calldata bodies) external;

    function addManyAccessories(bytes[] calldata accessories) external;

    function addManyHeads(bytes[] calldata heads) external;

    function addManyEyes(bytes[] calldata eyes) external;

    function addManyNoses(bytes[] calldata noses) external;

    function addManyMouths(bytes[] calldata mouths) external;

    function addManyShinyAccessories(bytes[] calldata shinyAccessories) external;

    function addColorToPalette(uint8 paletteIndex, string calldata color) external;

    function addBackground(string calldata background) external;

    function addBody(bytes calldata body) external;

    function addAccessory(bytes calldata accessory) external;

    function addAccessoryAtIndex(uint16 index, bytes calldata accessory) external;

    function addHead(bytes calldata head) external;

    function addEyes(bytes calldata eyes) external;

    function addNose(bytes calldata noses) external;

    function addMouth(bytes calldata mouths) external;

    function lockParts() external;

    function tokenURI(uint256 tokenId, IShinySeeder.Seed memory seed, bool isShiny) external view returns (string memory);

    function dataURI(uint256 tokenId, IShinySeeder.Seed memory seed, bool isShiny) external view returns (string memory);

    function genericDataURI(
        string calldata name,
        string calldata description,
        IShinySeeder.Seed memory seed,
        bool isShiny
    ) external view returns (string memory);

    function generateSVGImage(IShinySeeder.Seed memory seed) external view returns (string memory);
}