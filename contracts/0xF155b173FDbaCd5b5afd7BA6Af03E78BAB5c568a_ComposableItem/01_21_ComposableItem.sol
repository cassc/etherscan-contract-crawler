// SPDX-License-Identifier: GPL-3.0

/// @title The Composable Nouns Item ERC-1155 token

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

import "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import { Strings } from '@openzeppelin/contracts/utils/Strings.sol';

import { IComposableItemInitializer } from './interfaces/IComposableItemInitializer.sol';
import { IComposablePart } from './interfaces/IComposablePart.sol';
import { IComposableItem } from './interfaces/IComposableItem.sol';
import { ISVGRenderer } from '../../interfaces/ISVGRenderer.sol';

import { SSTORE2 } from '../../libs/SSTORE2.sol';
import { IInflator } from '../../interfaces/IInflator.sol';

import { Base64 } from 'base64-sol/base64.sol';

contract ComposableItem is IComposableItemInitializer, IComposablePart, IComposableItem, ERC1155Upgradeable {
    using Strings for uint256;

    /// @notice The contract responsible for constructing SVGs
    ISVGRenderer public immutable renderer;
    
    /// @notice Current inflator address
    IInflator public immutable inflator;

	// The owner/creator of this collection
  	address public owner;

    // An address who has permissions to mint
    address public minter;
    
    // Contract name
    string public name;

    // Contract symbol
    string public symbol;    
    
    // Supply per token id
    mapping (uint256 => uint256) public tokenSupply;

    /// @notice Noun Color Palettes (Index => Hex Colors, stored as a contract using SSTORE2)
    mapping(uint8 => address) public palettesPointers;

    /// @notice Image StorageSet
    StorageSet public imageSet;

    /// @notice Metadata StorageSet
    StorageSet public metaSet;

    /**
     * @notice Require that the sender is the minter.
     */
    modifier onlyMinter() {
        require(_msgSender() == minter, 'Sender is not the minter');
        _;
    }
    
    /**
     * @notice Require that the sender is the minter.
     */
  	modifier onlyOwner() {
    	require(_msgSender() == owner, "Sender is not owner");
    	_;
  	}  	

    constructor(
        ISVGRenderer _renderer,
        IInflator _inflator    	
    ) {
        renderer = _renderer;
        inflator = _inflator;
    }
    
    function initialize(
    	string memory _name,
    	string memory _symbol,
    	address _creator,
        address _minter
    ) public initializer {
		__ERC1155_init('');

    	name = _name;
    	symbol = _symbol;

    	owner = _creator;
        minter = _minter;    	
    }

    function mint(address account, uint256 id, uint256 amount, bytes memory data)
        external
        onlyMinter
    {
        _mint(account, id, amount, data);

        tokenSupply[id] = tokenSupply[id] += amount;
    }

    function mintBatch(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
        external
        onlyMinter
    {
        _mintBatch(to, ids, amounts, data);
        
        uint256 len = ids.length;

        for (uint256 i = 0; i < len;) {
            tokenSupply[ids[i]] += amounts[i];

			unchecked {
            	i++;
        	}
        }
    }
	
    /**
     * @notice A distinct Uniform Resource Identifier (URI) for a given asset.
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory) {
        require(_exists(tokenId), 'ComposableItem: URI query for nonexistent token');
		return _dataURI(tokenId);
    }

    /**
     * @notice Similar to `tokenURI`, but always serves a base64 encoded data URI
     * with the JSON contents directly inlined.
     */
    function dataURI(uint256 tokenId) external view returns (string memory) {
        require(_exists(tokenId), 'ComposableItem: URI query for nonexistent token');
        return _dataURI(tokenId);
    }

    function getPart(uint256 tokenId) external view returns (ISVGRenderer.Part memory) {
    	require(_exists(tokenId), 'ComposableItem: Part query for nonexistent token');
    	return _getPart(tokenId);
    }

    /**
     * @notice Given a tokenId, generate a base64 encoded SVG image.
     */
    function generateImage(uint256 tokenId) external view returns (string memory) {
        ISVGRenderer.SVGParams memory params = ISVGRenderer.SVGParams({
            parts: _getParts(tokenId),
            background: ''
        });
        
        return _generateSVGImage(renderer, params);
    }

    /**
     * @notice Given a tokenId, generate the metadata string in storage.
     */
    function generateMeta(uint256 tokenId) external view returns (string memory) {
		return string(abi.encodePacked(_itemBytesByIndex(metaSet, tokenId)));    	
    }    

    /**
     * @notice Get a item image bytes (RLE-encoded).
     */
    function getImageBytes(uint256 tokenId) external view returns (bytes memory) {
    	require(_exists(tokenId), 'ComposableItem: Image query for nonexistent token');
        return _itemBytesByIndex(imageSet, tokenId);
    }

    /**
     * @notice Get a item metadata bytes (RLE-encoded).
     */
    function getMetaBytes(uint256 tokenId) external view returns (bytes memory) {
    	require(_exists(tokenId), 'ComposableItem: Meta query for nonexistent token');
        return _itemBytesByIndex(metaSet, tokenId);
    }

    /**
     * @notice Get the StorageSet struct for images.
     * @dev This explicit getter is needed because implicit getters for structs aren't fully supported yet:
     * https://github.com/ethereum/solidity/issues/11826
     * @return StorageSet the struct, including a total stored count, and an array of storage pages.
     */
    function getImageSet() external view returns (StorageSet memory) {
        return imageSet;
    }

    /**
     * @notice Get the StorageSet struct for metadata.
     * @dev This explicit getter is needed because implicit getters for structs aren't fully supported yet:
     * https://github.com/ethereum/solidity/issues/11826
     * @return StorageSet the struct, including a total image count, and an array of storage pages.
     */
    function getMetaSet() external view returns (StorageSet memory) {
        return metaSet;
    }    
           
    /**
    * @dev Returns the total quantity for a token ID
    * @param tokenId uint256 ID of the token to query
    * @return amount of token in existence
    */
	function totalSupply(uint256 tokenId) external view returns (uint256) {
    	require(_exists(tokenId), 'ComposableItem: Supply query for nonexistent token');
	    return tokenSupply[tokenId];
	}

  	/**
    * @dev Returns whether the specified token exists by checking to see if we have a stored item for it
    * @param tokenId uint256 ID of the token to query the existence of
    * @return bool whether the token exists
    */
	
	function exists(uint256 tokenId) external view returns (bool) {
    	return _exists(tokenId);
	}

	function _exists(uint256 tokenId) internal view returns (bool) {
    	return tokenId < imageSet.storedCount;
	}
	
    /**
     * @notice Get the number of available image items.
     */
    function getImageCount() external view returns (uint256) {
        return imageSet.storedCount;
    }

    /**
     * @notice Get the number of available metadata items.
     */
    function getMetaCount() external view returns (uint256) {
        return metaSet.storedCount;
    }

    /**
     * @notice Given a token ID, construct a base64 encoded data URI.
     */
    function _dataURI(uint256 tokenId) internal view returns (string memory) {
        TokenURIParams memory params = TokenURIParams({
            metadata: string(abi.encodePacked(_itemBytesByIndex(metaSet, tokenId))),
            parts: _getParts(tokenId),
            background: ''
        });
        return _constructTokenURI(renderer, params);
    }

    function _getParts(uint256 tokenId) internal view returns (ISVGRenderer.Part[] memory) {
        ISVGRenderer.Part[] memory parts = new ISVGRenderer.Part[](1);
        parts[0] = _getPart(tokenId);

        return parts;
    }

    function _getPart(uint256 tokenId) internal view returns (ISVGRenderer.Part memory) {
        bytes memory item = _itemBytesByIndex(imageSet, tokenId);

        ISVGRenderer.Part memory part = ISVGRenderer.Part({ image: item, palette: _getPalette(item) });

        return part;
    }    
    
    /**
     * @notice Get the color palette pointer for the passed part.
     */
    function _getPalette(bytes memory part) internal view returns (bytes memory) {
        return _palettes(uint8(part[0]));
    }	


    /**
     * @notice Update a single color palette. This function can be used to
     * add a new color palette or update an existing palette.
     * @param paletteIndex the identifier of this palette
     * @param palette byte array of colors. every 3 bytes represent an RGB color. max length: 256 * 3 = 768
     * @dev This function can only be called by the owner.
     */
    function setPalette(uint8 paletteIndex, bytes calldata palette) external onlyOwner {
    	_setPalette(paletteIndex, palette);
    }

    function _setPalette(uint8 paletteIndex, bytes calldata palette) internal {
        if (palette.length == 0) {
            revert EmptyPalette();
        }
        if (palette.length % 3 != 0 || palette.length > 768) {
            revert BadPaletteLength();
        }
        palettesPointers[paletteIndex] = SSTORE2.write(palette);

        emit PaletteSet(paletteIndex);
    }

    function addItems(
        bytes calldata encodedImagesCompressed,
        uint80 decompressedImagesLength,
        uint16 imageCount,
        bytes calldata encodedMetaCompressed,
        uint80 decompressedMetaLength,
        uint16 metaCount,
    	uint8 paletteIndex, 
    	bytes calldata palette
    ) external onlyOwner {

        _addPage(imageSet, encodedImagesCompressed, decompressedImagesLength, imageCount);
        emit ImagesAdded(imageCount);
        
        _addPage(metaSet, encodedMetaCompressed, decompressedMetaLength, metaCount);
        emit MetaAdded(metaCount);

		//check to see if we even need to update the palette
        if (palette.length != 0) {
			_setPalette(paletteIndex, palette);
        }

    }

    /**
     * @notice Add a batch of images.
     * @param encodedImagesCompressed bytes created by taking a string array of RLE-encoded images, abi encoding it as a bytes array,
     * and finally compressing it using deflate.
     * @param decompressedImagesLength the size in bytes the images bytes were prior to compression; required input for Inflate.
     * @param imageCount the number of images in this batch; used when searching for images among batches.
     * @dev This function can only be called by the owner.
     */
    function addImages(
        bytes calldata encodedImagesCompressed,
        uint80 decompressedImagesLength,
        uint16 imageCount
    ) external onlyOwner {
        _addPage(imageSet, encodedImagesCompressed, decompressedImagesLength, imageCount);

        emit ImagesAdded(imageCount);
    }

    /**
     * @notice Add a batch of metadata.
     * @param encodedMetaCompressed bytes created by taking a string array of RLE-encoded metadata, abi encoding it as a bytes array,
     * and finally compressing it using deflate.
     * @param decompressedMetaLength the size in bytes the metadata bytes were prior to compression; required input for Inflate.
     * @param metaCount the number of metadata in this batch; used when searching for metadata among batches.
     * @dev This function can only be called by the owner.
     */
    function addMeta(
        bytes calldata encodedMetaCompressed,
        uint80 decompressedMetaLength,
        uint16 metaCount
    ) external onlyOwner {
        _addPage(metaSet, encodedMetaCompressed, decompressedMetaLength, metaCount);

        emit MetaAdded(metaCount);
    }

    /**
     * @notice Update a single color palette. This function can be used to
     * add a new color palette or update an existing palette. This function does not check for data length validity
     * (len <= 768, len % 3 == 0).
     * @param paletteIndex the identifier of this palette
     * @param pointer the address of the contract holding the palette bytes. every 3 bytes represent an RGB color.
     * max length: 256 * 3 = 768.
     * @dev This function can only be called by the owner.
     */
    function setPalettePointer(uint8 paletteIndex, address pointer) external onlyOwner {
        palettesPointers[paletteIndex] = pointer;

        emit PaletteSet(paletteIndex);
    }

    /**
     * @notice Add a batch of images from an existing storage contract.
     * @param pointer the address of a contract where the image batch was stored using SSTORE2. The data
     * format is expected to be like {encodedCompressed}: bytes created by taking a string array of
     * RLE-encoded images, abi encoding it as a bytes array, and finally compressing it using deflate.
     * @param decompressedLength the size in bytes the images bytes were prior to compression; required input for Inflate.
     * @param imageCount the number of images in this batch; used when searching for images among batches.
     * @dev This function can only be called by the owner.
     */
    function addImagesFromPointer(
        address pointer,
        uint80 decompressedLength,
        uint16 imageCount
    ) external onlyOwner {
        _addPage(imageSet, pointer, decompressedLength, imageCount);

        emit ImagesAdded(imageCount);
    }

    /**
     * @notice Add a batch of metadata from an existing storage contract.
     * @param pointer the address of a contract where the metadata batch was stored using SSTORE2. The data
     * format is expected to be like {encodedCompressed}: bytes created by taking a string array of
     * RLE-encoded metadata, abi encoding it as a bytes array, and finally compressing it using deflate.
     * @param decompressedLength the size in bytes the metadata bytes were prior to compression; required input for Inflate.
     * @param metaCount the number of metadatas in this batch; used when searching for metadata among batches.
     * @dev This function can only be called by the owner.
     */
    function addMetaFromPointer(
        address pointer,
        uint80 decompressedLength,
        uint16 metaCount
    ) external onlyOwner {
        _addPage(metaSet, pointer, decompressedLength, metaCount);

        emit MetaAdded(metaCount);
    }

    /**
     * @notice Get a color palette bytes.
     */
    function palettes(uint8 paletteIndex) external view returns (bytes memory) {
        return _palettes(paletteIndex);
    }

    function _palettes(uint8 paletteIndex) internal view returns (bytes memory) {
        address pointer = palettesPointers[paletteIndex];
        if (pointer == address(0)) {
            revert PaletteNotFound();
        }
        return SSTORE2.read(palettesPointers[paletteIndex]);
    }

    function _addPage(
        StorageSet storage itemSet,
        bytes calldata encodedCompressed,
        uint80 decompressedLength,
        uint16 itemCount
    ) internal {
        if (encodedCompressed.length == 0) {
            revert EmptyBytes();
        }
        address pointer = SSTORE2.write(encodedCompressed);
        _addPage(itemSet, pointer, decompressedLength, itemCount);
    }

    function _addPage(
        StorageSet storage itemSet,
        address pointer,
        uint80 decompressedLength,
        uint16 itemCount
    ) internal {
        if (decompressedLength == 0) {
            revert BadDecompressedLength();
        }
        if (itemCount == 0) {
            revert BadItemCount();
        }
        itemSet.storagePages.push(
            StoragePage({ pointer: pointer, decompressedLength: decompressedLength, itemCount: itemCount })
        );
        itemSet.storedCount += itemCount;
    }

    function _itemBytesByIndex(IComposableItem.StorageSet storage itemSet, uint256 index) internal view returns (bytes memory) {
        (IComposableItem.StoragePage storage page, uint256 indexInPage) = _getPage(itemSet.storagePages, index);
        bytes[] memory decompressedItemBytes = _decompressAndDecode(page);
        return decompressedItemBytes[indexInPage];
    }

    /**
     * @dev Given an item index, this function finds the storage page the item is in, and the relative index
     * inside the page, so the item can be read from storage.
     * Example: if you have 2 pages with 100 item each, and you want to get item 150, this function would return
     * the 2nd page, and the 50th index.
     * @return IComposableItem.StoragePage the page containing the item at index
     * @return uint256 the index of the item in the page
     */
    function _getPage(IComposableItem.StoragePage[] storage pages, uint256 index) internal view returns (IComposableItem.StoragePage storage, uint256) {
        uint256 len = pages.length;
        uint256 pageFirstItemIndex = 0;
        for (uint256 i = 0; i < len; i++) {
            IComposableItem.StoragePage storage page = pages[i];

            if (index < pageFirstItemIndex + page.itemCount) {
                return (page, index - pageFirstItemIndex);
            }

            pageFirstItemIndex += page.itemCount;
        }

        revert ItemNotFound();
    }

    function _decompressAndDecode(IComposableItem.StoragePage storage page) internal view returns (bytes[] memory) {
        bytes memory compressedData = SSTORE2.read(page.pointer);
        (, bytes memory decompressedData) = inflator.puff(compressedData, page.decompressedLength);
        return abi.decode(decompressedData, (bytes[]));
    }		

    /**
     * @notice Construct an ERC721 token URI.
     */
    function _constructTokenURI(ISVGRenderer _renderer, TokenURIParams memory params) internal view returns (string memory) {
        string memory image = _generateSVGImage(
            _renderer,
            ISVGRenderer.SVGParams({ parts: params.parts, background: params.background })
        );

        // prettier-ignore
        return string(
            abi.encodePacked(
                "data:application/json;base64,",
                Base64.encode(
                    bytes(
                        abi.encodePacked("{", params.metadata, ", \"image\": \"", "data:image/svg+xml;base64,", image, "\" }")
                    )
                )
            )
        );
    }

    /**
     * @notice Generate an SVG image for use in the ERC721 token URI.
     */
    function _generateSVGImage(ISVGRenderer _renderer, ISVGRenderer.SVGParams memory params) internal view returns (string memory svg) {
        return Base64.encode(bytes(_renderer.generateSVG(params)));
    }

    /**
     * @notice Set the token minter.
     * @dev Only callable by the owner when not locked.
     */
    function setMinter(address _minter) external onlyOwner {
        minter = _minter;

        emit MinterUpdated(_minter);
    }    

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "ComposableItem: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal {
        address oldOwner = owner;
        owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }        
}