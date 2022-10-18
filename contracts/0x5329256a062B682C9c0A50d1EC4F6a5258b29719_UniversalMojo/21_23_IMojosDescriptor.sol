// SPDX-License-Identifier: GPL-3.0

/// @title Interface for MojosDescriptor

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

import { IMojosSeeder } from './IMojosSeeder.sol';

interface IMojosDescriptor {
    event PartsLocked();

    event DataURIToggled(bool enabled);

    event BaseURIUpdated(string baseURI);

    function arePartsLocked() external returns (bool);

    function isDataURIEnabled() external returns (bool);

    function baseURI() external returns (string memory);

    function palettes(uint8 paletteIndex, uint256 colorIndex) external view returns (string memory);

    function backgrounds(uint256 index) external view returns (string memory);

    function bodies(uint256 index) external view returns (bytes memory);

    function bodyAccessories(uint256 index) external view returns (bytes memory);

    function faces(uint256 index) external view returns (bytes memory);

    function headAccessories(uint256 index) external view returns (bytes memory);

    function backgroundCount() external view returns (uint256);

    function bodyCount() external view returns (uint256);

    function bodyAccessoryCount() external view returns (uint256);

    function faceCount() external view returns (uint256);

    function headAccessoryCount() external view returns (uint256);

    function addManyColorsToPalette(uint8 paletteIndex, string[] calldata newColors) external;

    function addManyBackgrounds(string[] calldata backgrounds) external;

    function addManyBodies(bytes[] calldata bodies) external;

    function addManyBodyAccessories(bytes[] calldata bodyAccessories) external;

    function addManyFaces(bytes[] calldata faces) external;

    function addManyHeadAccessories(bytes[] calldata headAccessories) external;

    function addColorToPalette(uint8 paletteIndex, string calldata color) external;

    function addBackground(string calldata background) external;

    function addBody(bytes calldata body) external;

    function addBodyAccessory(bytes calldata bodyAccessory) external;

    function addFace(bytes calldata face) external;

    function addHeadAccessory(bytes calldata headAccessory) external;

    function lockParts() external;

    function toggleDataURIEnabled() external;

    function setBaseURI(string calldata baseURI) external;

    function tokenURI(uint256 tokenId, IMojosSeeder.Seed memory seed) external view returns (string memory);

    function dataURI(uint256 tokenId, IMojosSeeder.Seed memory seed) external view returns (string memory);

    function genericDataURI(
        string calldata name,
        string calldata description,
        IMojosSeeder.Seed memory seed
    ) external view returns (string memory);

    function generateSVGImage(IMojosSeeder.Seed memory seed) external view returns (string memory);
}