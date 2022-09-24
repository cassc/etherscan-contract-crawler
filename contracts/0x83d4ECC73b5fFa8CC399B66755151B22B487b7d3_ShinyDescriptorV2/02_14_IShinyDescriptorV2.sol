// SPDX-License-Identifier: GPL-3.0

/// @title Interface for ShinyDescriptorV2

/*********************************
 * ･ﾟ･ﾟ✧.・･ﾟshiny.club・✫・゜･ﾟ✧ *
 *********************************/

pragma solidity ^0.8.9;

import { IShinySeeder } from './IShinySeeder.sol';
import { ISVGRenderer } from './ISVGRenderer.sol';
import { IShinyArt } from './IShinyArt.sol';
import { IShinyDescriptorMinimal } from './IShinyDescriptorMinimal.sol';

interface IShinyDescriptorV2 is IShinyDescriptorMinimal {
    event PartsLocked();

    event ArtUpdated(IShinyArt art);

    event RendererUpdated(ISVGRenderer renderer);

    error EmptyPalette();
    error BadPaletteLength();
    error IndexNotFound();

    function arePartsLocked() external returns (bool);

    function palettes(uint8 paletteIndex) external view returns (bytes memory);

    function backgrounds(uint256 index) external view returns (string memory);

    function bodies(uint256 index) external view returns (bytes memory);

    function accessories(uint256 index) external view returns (bytes memory);

    function heads(uint256 index) external view returns (bytes memory);

    function eyes(uint256 index) external view returns (bytes memory);

    function noses(uint256 index) external view returns (bytes memory);

    function mouths(uint256 index) external view returns (bytes memory);

    function shinyAccessories(uint256 index) external view returns (bytes memory);

    function backgroundCount() external view override returns (uint256);

    function bodyCount() external view override returns (uint256);

    function accessoryCount() external view override returns (uint256);

    function headCount() external view override returns (uint256);

    function eyesCount() external view override returns (uint256);

    function nosesCount() external view override returns (uint256);

    function mouthsCount() external view override returns (uint256);

    function shinyAccessoryCount() external view override returns (uint256);

    function addManyBackgrounds(string[] calldata backgrounds) external;

    function addBackground(string calldata background) external;

    function setPalette(uint8 paletteIndex, bytes calldata palette) external;

    function addBodies(
        bytes calldata encodedCompressed,
        uint80 decompressedLength,
        uint16 imageCount
    ) external;

    function addAccessories(
        bytes calldata encodedCompressed,
        uint80 decompressedLength,
        uint16 imageCount
    ) external;

    function addHeads(
        bytes calldata encodedCompressed,
        uint80 decompressedLength,
        uint16 imageCount
    ) external;

    function addEyes(
        bytes calldata encodedCompressed,
        uint80 decompressedLength,
        uint16 imageCount
    ) external;

    function addNoses(
        bytes calldata encodedCompressed,
        uint80 decompressedLength,
        uint16 imageCount
    ) external;

    function addMouths(
        bytes calldata encodedCompressed,
        uint80 decompressedLength,
        uint16 imageCount
    ) external;

    function addShinyAccessories(
        bytes calldata encodedCompressed,
        uint80 decompressedLength,
        uint16 imageCount
    ) external;

    function setPalettePointer(uint8 paletteIndex, address pointer) external;

    function addBodiesFromPointer(
        address pointer,
        uint80 decompressedLength,
        uint16 imageCount
    ) external;

    function addAccessoriesFromPointer(
        address pointer,
        uint80 decompressedLength,
        uint16 imageCount
    ) external;

    function addHeadsFromPointer(
        address pointer,
        uint80 decompressedLength,
        uint16 imageCount
    ) external;

    function addEyesFromPointer(
        address pointer,
        uint80 decompressedLength,
        uint16 imageCount
    ) external;

    function addNosesFromPointer(
        address pointer,
        uint80 decompressedLength,
        uint16 imageCount
    ) external;

    function addMouthsFromPointer(
        address pointer,
        uint80 decompressedLength,
        uint16 imageCount
    ) external;

    function addShinyAccessoriesFromPointer(
        address pointer,
        uint80 decompressedLength,
        uint16 imageCount
    ) external;

    function lockParts() external;

    function tokenURI(uint256 tokenId, IShinySeeder.Seed memory seed, bool isShiny) external view override returns (string memory);

    function dataURI(uint256 tokenId, IShinySeeder.Seed memory seed, bool isShiny) external view override returns (string memory);

    function genericDataURI(
        string calldata name,
        string calldata description,
        IShinySeeder.Seed memory seed,
        bool isShiny
    ) external view returns (string memory);

    function generateSVGImage(IShinySeeder.Seed memory seed) external view returns (string memory);
}