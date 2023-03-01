// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "hardhat/console.sol";
import "solady/src/utils/LibString.sol";
import "solady/src/utils/SSTORE2.sol";

import "hardhat-deploy/solc_0.8/diamond/UsingDiamondOwner.sol";

import "./LibStorage.sol";
import "./LibStorageExtension.sol";

import {BookInternalFacet} from "./BookInternalFacet.sol";
import {GameMainFacet} from "./GameMainFacet.sol";
import "@solidstate/contracts/utils/Multicall.sol";

import { ERC721DInternal } from "./ERC721D/ERC721DInternal.sol";

contract BookExtensionFacetMirrorEtc is ERC721DInternal, WithStorage, BookInternalFacet {
    event AdminMintPunkToUser(
        address indexed minter,
        address indexed recipient,
        uint indexed punkId
    );
    
    error BookDoesNotExist(uint punkId);
    error CannotSetBackgroundImageForLevelThatIsNotNext(uint maxLevelCovered);
    error ColorMappingNotEnabledForItem(string itemSlug);
    error BackgroundNotEnabledForItem(string itemSlug);
    error CallerNotOwner(uint punkId);
    
    function bkExt() internal pure returns (BookStorageExtension storage) {
        return LibStorageExtension.bookStorageExtension();
    }
    
    function setBookExtensionFacetMirrorEtcInitialized(bool newVal) external onlyRole(ADMIN) {
        bkExt().bookExtensionFacetMirrorEtcInitialized = newVal;
    }
    
    function getBookExtensionFacetMirrorEtcInitialized() external view returns (bool) {
        return bkExt().bookExtensionFacetMirrorEtcInitialized;
    }
    
    function burnGameItemFromSender(string memory gameItemSlug) internal {
        GameMainFacet(bk().gameContract).burnFromPunkContract(
            msg.sender,
            gameItemSlug,
            1
        );
    }
    
    modifier usingItemOnBook(uint punkId, string memory itemSlug) {
        if (_ownerOf(punkId) != msg.sender) revert CallerNotOwner(punkId);
        
        burnGameItemFromSender(itemSlug);
        
        _;
        emit MetadataUpdate(punkId);
    }
    
    function setScaleUpFactor(uint32 scaleUp) external onlyRole(ADMIN) {
        bk().imageScaleUpFactor = scaleUp;
    }
    
    function setBackgroundImageForLevel(bytes calldata backgroundImage, uint level) external onlyRole(ADMIN) {
        address backgroundImagePointer = SSTORE2.write(backgroundImage);
        uint existingCount = bk().backgroundImagePointersByLevel.length;
        
        if (existingCount == 0) {
            bk().backgroundImagePointersByLevel.push(backgroundImagePointer);
            return;
        }
        
        uint maxLevelCovered = existingCount - 1;
        
        if (level <= maxLevelCovered) {
            bk().backgroundImagePointersByLevel[level] = backgroundImagePointer;
        } else if (level == maxLevelCovered + 1) {
            bk().backgroundImagePointersByLevel.push(backgroundImagePointer);
        } else {
            revert CannotSetBackgroundImageForLevelThatIsNotNext(maxLevelCovered);
        }
    }
    
    function healBook(uint punkId) usingItemOnBook(punkId, "healing_quill") external {
        delete bk().punkIdToPunkDamageEvents[punkId];
    }
    
    function changeBackground(uint punkId, string calldata itemSlug) usingItemOnBook(punkId, itemSlug) external {
        address possiblePointer = bkExt().gameItemToBackgroundPointer[itemSlug];
        
        if (possiblePointer == address(0)) revert BackgroundNotEnabledForItem(itemSlug);
        
        bkExt().punkIdToBackgroundItem[punkId] = itemSlug;
    }
    
    function clearBackground(uint punkId) external {
        if (_ownerOf(punkId) != msg.sender) revert CallerNotOwner(punkId);
        
        delete bkExt().punkIdToBackgroundItem[punkId];
        emit MetadataUpdate(punkId);
    }
    
    function mirrorPunk(uint punkId) usingItemOnBook(punkId, "book_mirror") external {
        bkExt().punkIdToIsMirrored[punkId] = true;
    }
    
    function unmirrorPunk(uint punkId) external {
        if (_ownerOf(punkId) != msg.sender) revert CallerNotOwner(punkId);
        
        bkExt().punkIdToIsMirrored[punkId] = false;
        emit MetadataUpdate(punkId);
    }
    
    function changeColorMapping(uint punkId, string calldata itemSlug) usingItemOnBook(punkId, itemSlug) external {
        if (!bkExt().colorMappingItemToIsEnabled[itemSlug]) revert ColorMappingNotEnabledForItem(itemSlug);
        bkExt().punkIdToColorMappingItem[punkId] = itemSlug;
    }
    
    function setBackgroundPointerForGameItem(
        string calldata itemSlug,
        bytes calldata backgroundImage
    ) external onlyRole(ADMIN) {
        address backgroundImagePointer = SSTORE2.write(backgroundImage);

        bkExt().gameItemToBackgroundPointer[itemSlug] = backgroundImagePointer;
    }
    
    function setColorMappingForSlug(
        string calldata itemSlug,
        bytes4[][] calldata _colorMapping
    ) external onlyRole(ADMIN) {
        mapping(bytes4 => bytes4) storage colorMapping = bkExt().gameItemToColorMapping[itemSlug];

        for (uint i; i < _colorMapping.length; ++i) {
            colorMapping[_colorMapping[i][0]] = _colorMapping[i][1];
        }
        
        bkExt().colorMappingItemToIsEnabled[itemSlug] = true;
    }
    
    function setColorMappingEnabled(string calldata itemSlug, bool newVal) external onlyRole(ADMIN) {
        bkExt().colorMappingItemToIsEnabled[itemSlug] = newVal;
    }
    
    function setAttributeNameForGameItem(
        string calldata itemSlug,
        string calldata attributeName
    ) external onlyRole(ADMIN) {
        bkExt().gameItemToAttributeName[itemSlug] = attributeName;
    }
    
    function getAttributeNameForGameItem(string calldata itemSlug) view external returns (string memory) {
        return bkExt().gameItemToAttributeName[itemSlug];
    }
    
    function adminMintPunkToUserNoRevertOnExists(address to, uint80 punkId) external onlyRole(ADMIN) {
        if (_exists(punkId)) return;
        
        if (!punkIsValid(punkId)) revert();

        _mint(to, punkId);
        
        if (bk().userToPrimaryPunkId[to] == 0) {
            bk().userToPrimaryPunkId[to] = punkId;
        }
        
        emit AdminMintPunkToUser(msg.sender, to, punkId);
    }
    
    function setRenderMode(uint8 _renderMode) external onlyRole(ADMIN) {
        bkExt().renderMode = _renderMode;
    }
    
    function setBaseImageURI(string memory _baseImageURI) external onlyRole(ADMIN) {
        bkExt().baseImageURI = _baseImageURI;
    }
}