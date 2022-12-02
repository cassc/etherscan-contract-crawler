// SPDX-License-Identifier: GPL-3.0

/// @title Interface for Composable Item

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

import { IERC1155Upgradeable } from '@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155Upgradeable.sol';

import { INounsSeeder } from '../../../interfaces/INounsSeeder.sol';
import { ISVGRenderer } from '../../../interfaces/ISVGRenderer.sol';

import { Inflate } from '../../../libs/Inflate.sol';
import { IInflator } from '../../../interfaces/IInflator.sol';

interface IComposableItem is IERC1155Upgradeable {

    error EmptyPalette();

    error BadPaletteLength();

    error EmptyBytes();

    error BadDecompressedLength();

    error BadItemCount();

    error ItemNotFound();

    error PaletteNotFound();

    event MinterUpdated(address indexed minter);

    event PaletteSet(uint8 paletteIndex);

    event ImagesAdded(uint16 imagesCountt);

    event MetaAdded(uint256 metaCount);

    struct StoragePage {
        uint16 itemCount;
        uint80 decompressedLength;
        address pointer;
    }

    struct StorageSet {
        StoragePage[] storagePages;
        uint256 storedCount;
    }    

    struct TokenURIParams {
        string metadata;
        string background;
        ISVGRenderer.Part[] parts;
    }

    function mint(address account, uint256 id, uint256 amount, bytes memory data) external;
    function mintBatch(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) external;

    function dataURI(uint256 tokenId) external returns (string memory);
    function tokenURI(uint256 tokenId) external returns (string memory);

    //function getPart(uint256 tokenId) external view returns (ISVGRenderer.Part memory);
 	function generateImage(uint256 tokenId) external view returns (string memory);
    function generateMeta(uint256 tokenId) external view returns (string memory);

    function getImageBytes(uint256 tokenId) external view returns (bytes memory);
    function getMetaBytes(uint256 tokenId) external view returns (bytes memory);
    
    function getImageSet() external view returns (StorageSet memory);
	function getMetaSet() external view returns (StorageSet memory);

	function totalSupply(uint256 tokenId) external view returns (uint256);
	function exists(uint256 tokenId) external view returns (bool);
	 	
    function getImageCount() external view returns (uint256);
    function getMetaCount() external view returns (uint256);    
 
    function palettes(uint8 paletteIndex) external view returns (bytes memory);

    function setPalette(uint8 paletteIndex, bytes calldata palette) external;

    function setPalettePointer(uint8 paletteIndex, address pointer) external;

    function addItems(
        bytes calldata encodedImagesCompressed,
        uint80 decompressedImagesLength,
        uint16 imagesCount,
        bytes calldata encodedMetaCompressed,
        uint80 decompressedMetaLength,
        uint16 metaCount,
    	uint8 paletteIndex, 
    	bytes calldata palette
    ) external;

    function addImages(
        bytes calldata encodedImagesCompressed,
        uint80 decompressedImagesLength,
        uint16 imagesCount
    ) external;

    function addMeta(
        bytes calldata encodedMetaCompressed,
        uint80 decompressedMetaLength,
        uint16 metaCount
    ) external;

    function addImagesFromPointer(
        address pointer,
        uint80 decompressedLength,
        uint16 imageCount
    ) external;

    function addMetaFromPointer(
        address pointer,
        uint80 decompressedLength,
        uint16 metaCount
    ) external;


    function setMinter(address minter) external;
    function minter() external view returns (address);
    
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    
    function transferOwnership(address newOwner) external;
    function owner() external view returns (address);
    
}