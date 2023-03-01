// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "hardhat/console.sol";
import "solady/src/utils/LibString.sol";

import "./LibStorage.sol";

import {BookInternalFacetV2} from "./BookInternalFacetV2.sol";
import {BookRenderFacetV2} from "./BookRenderFacetV2.sol";
import {GameMainFacet} from "./GameMainFacet.sol";
import "solady/src/utils/DynamicBufferLib.sol";

import { ERC721DInternal } from "./ERC721D/ERC721DInternal.sol";

contract BookExtensionFacetDamageBug is WithStorage, ERC721DInternal, BookInternalFacetV2 {
    struct BookExtensionFacetDamageBugStorage {
        mapping(string => uint) nameFingerprintToPunkId;
        bool bookExtensionFacetMirrorEtcInitialized;
    }
    
    function s() internal pure returns (BookExtensionFacetDamageBugStorage storage gs) {
        bytes32 position = keccak256("c21.babylon.game.book.storage.BookExtensionFacetDamageBug");
        assembly {
            gs.slot := position
        }
    }
    
    function setBookExtensionFacetDamageBugInitialized(bool newVal) external onlyRole(ADMIN) {
        s().bookExtensionFacetMirrorEtcInitialized = newVal;
    }
    
    function getBookExtensionFacetDamageBugInitialized() external view returns (bool) {
        return s().bookExtensionFacetMirrorEtcInitialized;
    }
    
    using LibString for *;
    using DynamicBufferLib for DynamicBufferLib.DynamicBuffer;
    
    error InvalidName(string name);
    error NameAlreadyTaken(string name);
    error CallerNotOwner(uint punkId);
    
    event ItemUsedOnBook(
        uint bookId,
        string itemSlug
    );

    function punkHealth(uint punkId) public view returns (int) {
        uint32[] memory damageSlots = bk().punkIdToPunkDamageEvents[punkId];
        uint damageTaken;
    
        for (uint i; i < damageSlots.length; ) {
            if (damageSlots[i] + 1 weeks > block.timestamp) {
                damageTaken++;
            }
            
            unchecked {++i;}
        }
        
        return int(punkHealthCapacity(punkId) - damageTaken);
    }
    
    function mintPunkToUser(address to, uint punkId) internal {
        _mint(to, punkId);
        
        if (userToPrimaryPunkId(to) == 0) {
            bk().userToPrimaryPunkId[to] = punkId;
        }
    }
    
    modifier usingItemOnBook(uint punkId, string memory itemSlug) {
        if (_ownerOf(punkId) != msg.sender) revert CallerNotOwner(punkId);
        
        burnGameItemFromSender(itemSlug);
        
        _;
        emit ItemUsedOnBook(punkId, itemSlug);
        emit MetadataUpdate(punkId);
    }
    
    function upgradePunkToLevel(uint punkId, uint level) internal returns (bool) {
        _setTokenExtraData(punkId, uint96(level));
        delete bk().punkIdToPunkDamageEvents[punkId];
        
        emit UpgradePunk(punkId, _punkIdToPunkUpradeLevel(punkId));
        
        return true;
    }
    
    function _punkIdToPunkUpradeLevel(uint tokenId) internal view returns (uint) {
        return _getTokenExtraData(tokenId);
    }
    
    function punkIdToPunkUpradeLevel(uint tokenId) external view returns (uint) {
        return _punkIdToPunkUpradeLevel(tokenId);
    }
    
    function getPunkDamageEvents(uint punkId) external view returns (uint32[] memory) {
        return bk().punkIdToPunkDamageEvents[punkId];
    }
    
    function punkHealthCapacity(uint punkId) public view returns (uint) {
        return 3 + _punkIdToPunkUpradeLevel(punkId);
    }
    
    function calculateFingerprintOrRevert(string memory str) public view returns (string memory) {
        DynamicBufferLib.DynamicBuffer memory fingerprintBuffer;
        
        uint runeCount = str.runeCount();
        bytes memory lowerBytes = bytes(str.lower());
        uint byteLength = bytes(lowerBytes).length;
        
        if (
            runeCount != byteLength ||
            runeCount > bk().maxNameRuneCount
        ) {
            revert InvalidName(str);
        }
        
        for (uint i; i < byteLength; ) {
            bytes1 char = lowerBytes[i];

            if (
                (char >= 0x30 && char <= 0x39) || // 0–9
                (char >= 0x61 && char <= 0x7A) // a–z
            ) {
                fingerprintBuffer.append(abi.encodePacked(char));
            } else if (char < 0x20 || char >= 0x7F) {
                revert InvalidName(str);
            }
            
            unchecked {++i;}
        }
        
        return string(fingerprintBuffer.data);
    }
    
    function migrateFingerprints(uint[] calldata punkIds) external onlyRole(ADMIN) {
        for (uint i; i < punkIds.length; ++i) {
            uint punkId = punkIds[i];
            string memory name = bk().punkIdToName[punkId];
            
            if (bytes(name).length == 0) continue;
            
            string memory fingerprint = calculateFingerprintOrRevert(name);
            bytes32 nameHash = keccak256(bytes(name));
            
            s().nameFingerprintToPunkId[fingerprint] = punkId;
            delete bk().punkNameHashToPunkId[nameHash];
        }
    }
    
    function fingerprintToPunkId(string calldata nameOrFingerprint) external view returns (uint) {
        string memory fingerprint = calculateFingerprintOrRevert(nameOrFingerprint);
        return s().nameFingerprintToPunkId[fingerprint];
    }
    
    function punkIdToName(uint punkId) external view returns (string memory) {
        return bk().punkIdToName[punkId];
    }
    
    function fingerprintToExtendedPunk(string calldata nameOrFingerprint, uint32 _imageScaleUpFactor) external view returns (BookRenderFacetV2.PunkExtended memory) {
        string memory fingerprint = calculateFingerprintOrRevert(nameOrFingerprint);
        
        return BookRenderFacetV2(address(this)).getPunkExtended(
            uint80(s().nameFingerprintToPunkId[fingerprint]),
            _imageScaleUpFactor
        );
    }
    
    struct UserInfoLite {
        address userAddress;
        uint userPrimaryPunkId;
        string userPrimaryPunkName;
    }
    
    function fingerprintToUserInfoPunkOwner(string calldata nameOrFingerprint) external view returns (UserInfoLite memory) {
        string memory fingerprint = calculateFingerprintOrRevert(nameOrFingerprint);
        
        uint punkId = s().nameFingerprintToPunkId[fingerprint];
        address owner = _ownerOf(punkId);
        
        uint primaryPunkId = userToPrimaryPunkId(owner);
        string memory primaryPunkName = tokenIdToName(primaryPunkId);
        
        return UserInfoLite({
            userAddress: owner,
            userPrimaryPunkId: primaryPunkId,
            userPrimaryPunkName: primaryPunkName
        });
    }
    
    function tokenIdToName(uint tokenId) internal view returns (string memory) {
        string memory customName = bk().punkIdToName[tokenId];
        
        string memory displayName = bytes(customName).length > 0 ?
            customName.escapeJSON() :
            string.concat(bk().nameSingular, " #", formatNumberAsString(tokenId));
            
        return displayName;
    }
    
    function setPunkName(uint punkId, string calldata newName) external usingItemOnBook(punkId, "book_name_tag") {
        string memory oldName = bk().punkIdToName[punkId];
        string memory oldFingerprint = calculateFingerprintOrRevert(oldName);
        
        string memory newFingerprint = calculateFingerprintOrRevert(newName);
        
        if (bytes(newFingerprint).length == 0) revert InvalidName(newName);
        if (s().nameFingerprintToPunkId[newFingerprint] != 0) revert NameAlreadyTaken(newName);
        
        s().nameFingerprintToPunkId[newFingerprint] = punkId;
        bk().punkIdToName[punkId] = newName;
        
        delete s().nameFingerprintToPunkId[oldFingerprint];
        
        emit SetPunkName(msg.sender, punkId, newName);
    }
    
    function removePunkName(uint punkId) external {
        if (_ownerOf(punkId) != msg.sender) revert CallerNotOwner(punkId);

        string memory currentName = bk().punkIdToName[punkId];
        string memory currentFingerprint = calculateFingerprintOrRevert(currentName);
        
        delete bk().punkIdToName[punkId];
        delete s().nameFingerprintToPunkId[currentFingerprint];
        
        emit SetPunkName(msg.sender, punkId, "");
        emit MetadataUpdate(punkId);
    }

    function makePunkTakeDamageRevertIfAlreadyDead(uint punkId) external {
        require(msg.sender == bk().gameContract, "Only chest contract can call this");
        
        uint32[] storage damageSlots = bk().punkIdToPunkDamageEvents[punkId];
        uint healthCapacity = punkHealthCapacity(punkId);
        uint damageSlotCount = damageSlots.length;

        if (damageSlotCount < healthCapacity) {
            damageSlots.push(uint32(block.timestamp));
        } else {
            uint damageTaken;
            uint oldestEventIndex;
            
            unchecked {
                for (uint i; i < damageSlotCount; ++i) {
                    if (damageSlots[i] + 1 weeks > block.timestamp) {
                        damageTaken++;
                    }
                    
                    if (damageSlots[i] < damageSlots[oldestEventIndex]) {
                        oldestEventIndex = i;
                    }
                }
            }
            
            require(healthCapacity - damageTaken > 0, "Punk is already dead");
            
            damageSlots[oldestEventIndex] = uint32(block.timestamp);
        }
        
        emit MetadataUpdate(punkId);
        emit PunkTakeDamage(punkId);
    }
    
    function upgradePunkWithGameItem(uint punkId) external usingItemOnBook(punkId, "book_upgrade") {
        upgradePunkToLevel(punkId, _punkIdToPunkUpradeLevel(punkId) + 1);
    }
    
    function mintPunkWithRegularKey(uint80 assets) external {
        require (
            punkIsValid(assets) &&
            // ps().packedAssetsToOldPunksIdPlusOneMap[assets] == 0 &&
            _punkConformsToTheme(assets),
            "Not mintable"
        );
        
        burnGameItemFromSender("regular_key");
        mintPunkToUser(msg.sender, assets);
        
        emit MintPunkWithKey(msg.sender, assets, "regular_key", bk().currentThemeVersion);
    }
    
    function mintPunkWithSkeletonKey(uint80 assets) external {
        require (
            punkIsValid(assets),
            // ps().packedAssetsToOldPunksIdPlusOneMap[assets] == 0 &&
            "Not mintable"
        );
        
        burnGameItemFromSender("skeleton_key");
        mintPunkToUser(msg.sender, assets);
        
        emit MintPunkWithKey(msg.sender, assets, "skeleton_key", bk().currentThemeVersion);
    }
    
    function mintPunkWithDiamondSkeletonKey(uint80 assets) external {
        require (
            punkIsValid(assets),
            // ps().packedAssetsToOldPunksIdPlusOneMap[assets] == 0 &&
            "Not mintable"
        );
        
        burnGameItemFromSender("diamond_skeleton_key");
        mintPunkToUser(msg.sender, assets);
        upgradePunkToLevel(assets, 4);
        
        emit MintPunkWithKey(msg.sender, assets, "diamond_skeleton_key", bk().currentThemeVersion);
    }
    
    function burnGameItemFromSender(string memory gameItemSlug) internal {
        GameMainFacet(bk().gameContract).burnFromPunkContract(
            msg.sender,
            gameItemSlug,
            1
        );
    }

    function userToPrimaryPunkId(address user) public view returns (uint) {
        uint candidateId = bk().userToPrimaryPunkId[user];
        
        return _ownerOf(candidateId) == user ? candidateId : 0;
    }
    
    function updatePrimaryPunkId(uint punkId) external {
        if (_ownerOf(punkId) != msg.sender) revert CallerNotOwner(punkId);
        bk().userToPrimaryPunkId[msg.sender] = punkId;
    }
    
    function concatGlue(string memory base, uint256 part, bool isSet) internal pure returns (string memory) {  
        string memory stringified = part.toString();
        string memory glue = ",";

        if(!isSet) glue = "";
        return string(abi.encodePacked(
                stringified, 
                glue, 
                base));
    }

    function formatNumberAsString(uint256 source) internal pure returns (string memory) {   
        string memory result;
        uint128 index;

        while (source > 0) {
            uint256 part = source % 10; // get each digit
            bool isSet = index != 0 && index % 3 == 0; // if we're passed another set of 3 digits, request set glue

            result = concatGlue(result, part, isSet);
            source = source / 10;
            index += 1;
        }
 
        return result;
    }
}