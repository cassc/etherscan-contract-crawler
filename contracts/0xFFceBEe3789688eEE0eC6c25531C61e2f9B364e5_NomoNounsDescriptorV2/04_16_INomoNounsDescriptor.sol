// SPDX-License-Identifier: GPL-3.0

/// @title Interface for NounsDescriptorV2

/*********************************
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░█████████░░█████████░░░ *
 * ░░░░░░██░░░████░░██░░░████░░░ *
 * ░░██████░░░████████░░░████░░░ *
 * ░░██░░██░░░████░░██░░░████░░░ *
 * ░░██░░██░░░████░░██░░░████░░░ *
 * ░░░░░░█████████░░█████████░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 *********************************/

pragma solidity ^0.8.6;

import {INomoNounsSeeder} from "./INomoNounsSeeder.sol";
import {ISVGRenderer} from "../../nouns-contracts/NounsDescriptorV2/contracts/interfaces/ISVGRenderer.sol";
import {INounsArt} from '../../nouns-contracts/NounsDescriptorV2/contracts/interfaces/INounsArt.sol';
//import {INounsDescriptorMinimal} from '../../nouns-contracts/NounsDescriptorV2/contracts/interfaces/INounsDescriptorMinimal.sol';

interface INomoNounsDescriptor {
    event DataURIToggled(bool enabled);

    event BaseURIUpdated(string baseURI);

    event ArtUpdated(INounsArt art);

    event RendererUpdated(ISVGRenderer renderer);

    error EmptyPalette();
    error BadPaletteLength();
    error IndexNotFound();

    function isDataURIEnabled() external returns (bool);

    function baseURI() external returns (string memory);

    function palettes(uint8 paletteIndex) external view returns (bytes memory);

    function backgrounds(uint256 index) external view returns (string memory);

    function bodies(uint256 index) external view returns (bytes memory);

    function accessories(uint256 index) external view returns (bytes memory);

    function heads(uint256 index) external view returns (bytes memory);

    function glasses(uint256 index) external view returns (bytes memory);

    function backgroundCount() external view returns (uint256);

    function bodyCount() external view returns (uint256);

    function accessoryCount() external view returns (uint256);

    function headCount() external view returns (uint256);

    function glassesCount() external view returns (uint256);

    function setBackgroundOverride(uint256 _index, string calldata _color) external;

    function unsetBackgroundOverride(uint256 _index) external;

    function toggleDataURIEnabled() external;

    function setBaseURI(string calldata baseURI) external;

    function tokenURI(uint256 tokenId, INomoNounsSeeder.Seed memory seed) external view returns (string memory);

    function dataURI(uint256 tokenId, INomoNounsSeeder.Seed memory seed) external view returns (string memory);

    function genericDataURI(
        string calldata name,
        string calldata description,
        INomoNounsSeeder.Seed memory seed
    ) external view returns (string memory);

    function generateSVGImage(INomoNounsSeeder.Seed memory seed) external view returns (string memory);
}