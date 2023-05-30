// SPDX-License-Identifier: GPL-3.0

/// @title Interface for Descriptor

pragma solidity ^0.8.6;

import { ISeeder } from '../seeder/ISeeder.sol';

interface IDescriptor {
    event PartsLocked();

    event DataURIToggled(bool enabled);

    event BaseURIUpdated(string baseURI);

    function arePartsLocked() external returns (bool);

    function isDataURIEnabled() external returns (bool);    

    function baseURI() external returns (string memory);

    function palettes(uint8 paletteIndex, uint256 colorIndex) external view returns (string memory);

    function addManyColorsToPalette(uint8 paletteIndex, string[] calldata newColors) external;

    function addColorToPalette(uint8 paletteIndex, string calldata color) external;


    function backgrounds(uint256 index) external view returns (string memory);    

    function backgroundCount() external view returns (uint256);

    function addManyBackgrounds(string[] calldata backgrounds) external;

    function addBackground(string calldata background) external;    

    
    
    function oneOfOnes(uint256 index) external view returns (bytes memory);

    function oneOfOnesCount() external view returns (uint256);

    function addOneOfOne(bytes calldata _oneOfOne) external;

    function addManyOneOfOnes(bytes[] calldata _oneOfOnes) external;    


    function skins(uint256 index) external view returns (bytes memory);

    function skinsCount() external view returns (uint256);

    function addManySkins(bytes[] calldata skins) external;

    function addSkin(bytes calldata skin) external;


    function hats(uint256 index) external view returns (bytes memory);

    function hatsCount() external view returns (uint256);

    function addManyHats(bytes[] calldata hats) external;

    function addHat(bytes calldata hat) external;

    
    function clothes(uint256 index) external view returns (bytes memory);

    function clothesCount() external view returns (uint256);

    function addManyClothes(bytes[] calldata ears) external;

    function addClothes(bytes calldata ear) external;


    function mouths(uint256 index) external view returns (bytes memory);

    function mouthsCount() external view returns (uint256);

    function addManyMouths(bytes[] calldata mouths) external;

    function addMouth(bytes calldata mouth) external;

    
    function eyes(uint256 index) external view returns (bytes memory);

    function eyesCount() external view returns (uint256);

    function addManyEyes(bytes[] calldata eyes) external;

    function addEyes(bytes calldata eye) external;


    function accessory(uint256 index) external view returns (bytes memory);

    function accessoryCount() external view returns (uint256);

    function addManyAccessories(bytes[] calldata noses) external;

    function addAccessory(bytes calldata nose) external;


    function bgItems(uint256 index) external view returns (bytes memory);

    function bgItemsCount() external view returns (uint256);

    function addManyBgItems(bytes[] calldata noses) external;

    function addBgItem(bytes calldata nose) external;


    function lockParts() external;

    function toggleDataURIEnabled() external;

    function setBaseURI(string calldata baseURI) external;

    function tokenURI(uint256 tokenId, ISeeder.Seed memory seed) external view returns (string memory);

    function dataURI(uint256 tokenId, ISeeder.Seed memory seed) external view returns (string memory);

    function genericDataURI(
        string calldata name,
        string calldata description,
        ISeeder.Seed memory seed
    ) external view returns (string memory);

    function generateSVGImage(ISeeder.Seed memory seed) external view returns (string memory);
}