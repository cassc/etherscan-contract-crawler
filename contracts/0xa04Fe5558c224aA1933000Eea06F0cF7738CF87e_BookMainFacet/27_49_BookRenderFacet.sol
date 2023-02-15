//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.17;

import "hardhat/console.sol";
import "solady/src/utils/LibString.sol";
import "solady/src/utils/SafeTransferLib.sol";
import "solady/src/utils/SSTORE2.sol";
import "solady/src/utils/LibSort.sol";

import {BMP} from "@divergencetech/ethier/contracts/utils/BMP.sol";
import {Image, Rectangle} from "@divergencetech/ethier/contracts/utils/Image.sol";
import {DynamicBuffer} from "@divergencetech/ethier/contracts/utils/DynamicBuffer.sol";
import "solady/src/utils/Base64.sol";

import "hardhat-deploy/solc_0.8/diamond/UsingDiamondOwner.sol";

import "./LibStorage.sol";

import {BookInternalFacet} from "./BookInternalFacet.sol";
import {BookMainFacet} from "./BookMainFacet.sol";
import {BookDataFacet} from "./BookDataFacet.sol";
import "solady/src/utils/DynamicBufferLib.sol";

import {ERC721DInternal} from "./ERC721D/ERC721DInternal.sol";

contract BookRenderFacet is UsingDiamondOwner, WithStorage, ERC721DInternal, BookInternalFacet {
    using LibString for *;
    using DynamicBuffer for bytes;
    using DynamicBufferLib for DynamicBufferLib.DynamicBuffer;

    uint256 internal constant _BMP_URI_PREFIX_LENGTH = 22;
    uint32 internal constant _NATIVE_PUNK_RES = 24;
    
    struct Punk {
        bool exists;
        uint80 packedAssets;
        uint8[10] assetsArr;
        string assetJSON;
        string bmp;
    }
    
    function setBackgroundImageForLevel(bytes calldata backgroundImage, uint level) external onlyOwner {
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
            revert("Cannot set background image for level that is not next in line");
        }
    }
    
    function getBackgroundImageForLevel() public view returns (address[] memory) {
        return bk().backgroundImagePointersByLevel;
    }
    
    function setScaleUpFactor(uint32 scaleUp) external onlyRole(ADMIN) {
        bk().imageScaleUpFactor = scaleUp;
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

    function formatNumberAsString(uint256 source) public pure returns (string memory) {   
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
    
    function punkIdToPunkUpradeLevel(uint tokenId) internal view returns (uint) {
        return _getTokenExtraData(tokenId);
    }
    
    function backgroundPointerForPunk(uint tokenId) public view returns (address) {
        uint upgradeLevel = punkIdToPunkUpradeLevel(tokenId);
        uint maxUpgradeLevelStored = bk().backgroundImagePointersByLevel.length - 1;
        
        if (upgradeLevel > maxUpgradeLevelStored) {
            upgradeLevel = maxUpgradeLevelStored;
        }
        
        return bk().backgroundImagePointersByLevel[upgradeLevel];
    }
    
    function constructTokenURI(uint tokenId) public view returns (string memory) {
        require(BookMainFacet(address(this)).exists(tokenId), "Token does not exist");
        uint80 assets = uint80(tokenId);
        
        int _health = BookMainFacet(address(this)).punkHealth(tokenId);
        uint health = _health >= 0 ? uint(_health) : 0;
        uint upgradeLevel = punkIdToPunkUpradeLevel(tokenId);
        
        bytes memory artwork = BookDataFacet(address(this)).renderBmp(
            assets,
            backgroundPointerForPunk(tokenId),
            0,
            punkDefaultOverlayOpacity(tokenId)
        );
        
        (, uint256 paddedLengthScaled) = BMP.computePadding(
            _NATIVE_PUNK_RES * bk().imageScaleUpFactor,
            _NATIVE_PUNK_RES * bk().imageScaleUpFactor
        );

        bytes memory uri = DynamicBuffer.allocate(
            _BMP_URI_PREFIX_LENGTH +
                (4 * (BMP._BMP_HEADER_SIZE + paddedLengthScaled + 2)) /
                3 +
                1024
        );
        
        uri.appendSafe('data:application/json;utf-8,{"name":"');
        
        string memory customName = bk().punkIdToName[tokenId];
        
        string memory displayName = bytes(customName).length > 0 ?
            customName.escapeJSON() :
            string.concat(bk().nameSingular, " #", formatNumberAsString(tokenId));
        
        uri.appendSafe(bytes(displayName));

        uri.appendSafe('","description":"');
        uri.appendSafe(bytes(bk().tokenDescription.escapeJSON()));
        
        uri.appendSafe('","external_url":"');
        uri.appendSafe(bytes(bk().externalLink));

        uri.appendSafe('","image":"');
        _appendArtworkURI(uri, artwork, bk().imageScaleUpFactor);

        uri.appendSafe('","attributes":');
        uri.appendSafe(bytes(BookDataFacet(address(this)).attributesAsJSON(assets, true, health, upgradeLevel)));
        uri.appendSafe('}');
        
        return string(uri);
    }
    
    function punkDefaultOverlayOpacity(uint tokenId) public view returns (uint8) {
        int intHealth = BookMainFacet(address(this)).punkHealth(tokenId);
        uint punkHealth = intHealth >= 0 ? uint(intHealth) : 0;
        uint punkHealthCapacity = BookMainFacet(address(this)).punkHealthCapacity(tokenId);
        
        return uint8(255 - (255 * punkHealth / punkHealthCapacity));
    }
    
    function tokenBMP(uint tokenId, uint32 _imageScaleUpFactor) public view returns (string memory) {
        uint80 assets = uint80(tokenId);
        
        bytes memory artwork = BookDataFacet(address(this)).renderBmp(
            assets,
            backgroundPointerForPunk(tokenId),
            0,
            punkDefaultOverlayOpacity(tokenId)
        );
        
        (, uint256 paddedLengthScaled) = BMP.computePadding(
            _NATIVE_PUNK_RES * _imageScaleUpFactor,
            _NATIVE_PUNK_RES * _imageScaleUpFactor
        );

        bytes memory uri = DynamicBuffer.allocate(
            _BMP_URI_PREFIX_LENGTH +
                (4 * (BMP._BMP_HEADER_SIZE + paddedLengthScaled + 2)) /
                3 +
                1024
        );
        
        _appendArtworkURI(uri, artwork, _imageScaleUpFactor);
        
        return string(uri);
    }
    
    function getPunk(uint80 packedAssets, uint32 _imageScaleUpFactor) external view returns (Punk memory punk) {
        punk.exists = BookMainFacet(address(this)).exists(uint256(packedAssets));
        punk.packedAssets = packedAssets;
        punk.assetsArr = unpackAssets(packedAssets);
        punk.assetJSON = BookDataFacet(address(this)).attributesAsJSON(packedAssets, false, 0, 0);
        punk.bmp = tokenBMP(packedAssets, _imageScaleUpFactor);
    }
    
    // Copied from Moonbirds (0x85701AD420553315028a49A16f078D5FF62F4762)
    function _appendArtworkURI(
        bytes memory uri,
        bytes memory artwork,
        uint32 scaleupFactor
    ) internal pure {
        uri.appendSafe("data:image/bmp;base64,");

        if (scaleupFactor == 1) {
            uri.appendSafeBase64(
                BMP.bmp(artwork, _NATIVE_PUNK_RES, _NATIVE_PUNK_RES),
                false,
                false
            );
            return;
        }

        uint256 scaledImageStride = _NATIVE_PUNK_RES * 3 * scaleupFactor;
        if (scaledImageStride % 4 > 0) {
            uri.appendSafeBase64(
                BMP.bmp(
                    Image.scale(artwork, _NATIVE_PUNK_RES, 3, scaleupFactor),
                    _NATIVE_PUNK_RES * scaleupFactor,
                    _NATIVE_PUNK_RES * scaleupFactor
                ),
                false,
                false
            );
        } else {
            uri.appendSafeBase64(
                BMP.header(
                    _NATIVE_PUNK_RES * scaleupFactor,
                    _NATIVE_PUNK_RES * scaleupFactor
                ),
                false,
                false
            );
            Image.appendSafeScaled(
                uri,
                bytes(Base64.encode(artwork)),
                _NATIVE_PUNK_RES,
                4,
                scaleupFactor
            );
        }
    }
}