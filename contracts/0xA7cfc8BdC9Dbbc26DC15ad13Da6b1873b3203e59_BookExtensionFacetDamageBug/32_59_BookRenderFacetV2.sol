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
import "./LibStorageExtension.sol";

import {BookInternalFacet} from "./BookInternalFacet.sol";
import {BookMainFacet} from "./BookMainFacet.sol";
import {BookDataFacet} from "./BookDataFacet.sol";
import {GameHelperFacet} from "./GameHelperFacet.sol";
import "solady/src/utils/DynamicBufferLib.sol";

import {ERC721DInternal} from "./ERC721D/ERC721DInternal.sol";

contract BookRenderFacetV2 is UsingDiamondOwner, WithStorage, ERC721DInternal, BookInternalFacet {
    using LibString for *;
    using DynamicBuffer for bytes;
    using DynamicBufferLib for DynamicBufferLib.DynamicBuffer;
    using Image for bytes;
    
    function bkExt() internal pure returns (BookStorageExtension storage) {
        return LibStorageExtension.bookStorageExtension();
    }
    
    uint256 internal constant _BMP_URI_PREFIX_LENGTH = 22;
    uint32 internal constant _NATIVE_PUNK_RES = 24;
    
    struct Punk {
        bool exists;
        uint80 packedAssets;
        uint8[10] assetsArr;
        string assetJSON;
        string bmp;
    }
    
    struct PunkExtended {
        bool exists;
        uint80 packedAssets;
        uint8[10] assetsArr;
        string assetJSON;
        string liveAssetJSON;
        string name;
        string bmp;
        uint16 health;
        uint16 upgradeLevel;
        bool isMirrored;
        string colorMappingItem;
        string customBackgroundItem;
    }
    
    function renderAsset(
        uint8 assetIndex,
        bool[576] memory overallPixelIndicesUsed,
        bool flip,
        mapping(bytes4 => bytes4) storage colorMapping,
        bool useColorMapping
    ) internal view returns (bytes memory) {
        bytes memory pixels = new bytes(2304);
        
        unchecked {
            if (assetIndex > 0) {
                bytes storage a = ps().assets[assetIndex];
                uint256 n = a.length / 3;
                for (uint256 i = 0; i < n; ++i) {
                    uint256[4] memory v = [
                        uint256(uint8(a[i * 3]) & 0xF0) >> 4,
                        uint256(uint8(a[i * 3]) & 0xF),
                        uint256(uint8(a[i * 3 + 2]) & 0xF0) >> 4,
                        uint256(uint8(a[i * 3 + 2]) & 0xF)
                    ];
                    for (uint256 dx = 0; dx < 2; ++dx) {
                        for (uint256 dy = 0; dy < 2; ++dy) {
                            uint256 p = ((2 * v[1] + dy) * 24 + (2 * v[0] + dx)) * 4;
                            
                            if (flip) {    
                                p = ((2 * v[1] + dy) *
                                    24 +
                                    (23 - (2 * v[0] + dx))) * 4;
                            }
                            if (v[2] & (1 << (dx * 2 + dy)) != 0) {
                                bytes4 c = composite(
                                    a[i * 3 + 1]
                                );
                                
                                if (useColorMapping) {
                                    c = colorMapping[c];
                                }
                                
                                pixels[p] = c[3];
                                pixels[p + 1] = c[2];
                                pixels[p + 2] = c[1];
                                pixels[p + 3] = c[0];
                                
                                overallPixelIndicesUsed[p / 4] = true;
                            } else if (v[3] & (1 << (dx * 2 + dy)) != 0) {
                                pixels[p] = 0xFF;
                                pixels[p + 1] = 0;
                                pixels[p + 2] = 0;
                                pixels[p + 3] = 0;
                                
                                overallPixelIndicesUsed[p / 4] = true;
                            }
                        }
                    }
                }
            }
        }
        
        return pixels;
    }
    
    function _attributesAsJSON(
        uint80 packed,
        uint health,
        uint upgradeLevel,
        bool showBabylonSpecificTraits
    ) internal view returns (string memory json) {
        DynamicBufferLib.DynamicBuffer memory buffer;
        
        UnpackedPunk memory punk = packedAssetsToUnpackedPunkStruct(packed);
        
        buffer.append(bytes('['));
        
        uint256 mask = 0xff << 72;
        
        for (uint8 j = 0; j < 10; j++) {
            uint8 assetIndex = uint8(
                (packed & (mask >> (j * 8))) >> (8 * (9 - j))
            );
            if (assetIndex > 0) {
                if (j > 0) {
                    buffer.append(bytes(','));
                }
                
            string memory name = j == 0 ?
                ps().assetNames[assetIndex].split(' ')[0] : ps().assetNames[assetIndex];
            
            string memory traitType;
            
            if (j == 1) {
                Gender gender = Gender(ps().baseToGender[uint8(punk.base)]);
                traitType = gender == Gender.Female ? "Lips" : "Mouth";
            } else {
                traitType = ps().assetSlotToTraitType[j];
            }
            
            buffer.append(abi.encodePacked('{"trait_type":"', traitType, '","value":"'));
            buffer.append(bytes(name));
            buffer.append(bytes('"}'));
            }
        }
        
        if (showBabylonSpecificTraits) {
            buffer.append(abi.encodePacked(',{"display_type": "number", "trait_type":"Health","value":', health.toString(), '}'));
            buffer.append(abi.encodePacked(',{"display_type": "number", "trait_type":"Upgrade Level","value":', (upgradeLevel + 1).toString(), '}'));
            
            bool isMirrored = bkExt().punkIdToIsMirrored[packed];
            
            if (isMirrored) {
                buffer.append(abi.encodePacked(',{"trait_type":"Mirrored","value":"Yes"}'));
            }
            
            string memory colorMappingItem = bkExt().punkIdToColorMappingItem[packed];
            
            if (bkExt().colorMappingItemToIsEnabled[colorMappingItem]) {
                string memory colorMappingItemName = bkExt().gameItemToAttributeName[colorMappingItem];
                buffer.append(abi.encodePacked(',{"trait_type":"Colorway","value":"', colorMappingItemName.escapeJSON(), '"}'));
            }
            
            string memory customBackgroundItem = bkExt().punkIdToBackgroundItem[packed];
            address possiblePointer = bkExt().gameItemToBackgroundPointer[customBackgroundItem];
            
            if (possiblePointer != address(0)) {
                string memory backgroundItemName = bkExt().gameItemToAttributeName[customBackgroundItem];
                buffer.append(abi.encodePacked(',{"trait_type":"Background","value":"', backgroundItemName.escapeJSON(), '"}'));
            }
        }

        
        buffer.append(bytes(']'));
        
        return string(buffer.data);
    }
    
    function _renderBMPFullOptions(
        uint80 packed,
        string memory customBackgroundItem,
        uint upgradeLevel,
        string memory colorMappingItem,
        bool isMirrored,
        uint8 damageOverlayOpacity
    ) internal view returns (bytes memory imageBytes) {
        imageBytes = SSTORE2.read(
            _backgroundPointerForPunk(upgradeLevel, customBackgroundItem)
        );

        Rectangle memory rect = Rectangle(0, 0, 24, 24);

        uint256 mask = 0xff << 72;
        
        bool[576] memory overallPixelIndicesUsed;
        
        mapping(bytes4 => bytes4) storage colorMapping = bkExt().gameItemToColorMapping[colorMappingItem];
        bool mappingEnabled = bkExt().colorMappingItemToIsEnabled[colorMappingItem];
        
        unchecked {
            for (uint8 j = 0; j < 10; ++j) {
                uint8 assetIndex = uint8(
                    (packed & (mask >> (j * 8))) >> (8 * (9 - j))
                );
                if (assetIndex > 0) {
                    bytes memory assetPixels = renderAsset(
                        assetIndex,
                        overallPixelIndicesUsed,
                        isMirrored,
                        colorMapping,
                        mappingEnabled
                    );
                    
                    imageBytes.alphaBlend(assetPixels, 24, rect);
                }
            }
        }
        
        return BookDataFacet(address(this)).postProcessImage(
            imageBytes,
            overallPixelIndicesUsed,
            damageOverlayOpacity
        );
    }
    
    function _renderBmp(uint80 tokenId) internal view returns (bytes memory imageBytes) {
        return _renderBMPFullOptions(
            tokenId,
            bkExt().punkIdToBackgroundItem[tokenId],
            punkIdToPunkUpradeLevel(tokenId),
            bkExt().punkIdToColorMappingItem[tokenId],
            bkExt().punkIdToIsMirrored[tokenId],
            punkDefaultOverlayOpacity(tokenId)
        );
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
    
    function punkIdToPunkUpradeLevel(uint tokenId) internal view returns (uint) {
        return _getTokenExtraData(tokenId);
    }
    
    function _backgroundPointerForPunk(
        uint upgradeLevel,
        string memory backgroundItem
    ) internal view returns (address) {
        address possiblePointer = bkExt().gameItemToBackgroundPointer[backgroundItem];
        
        if (possiblePointer != address(0)) {
            return possiblePointer;
        }
        
        uint maxUpgradeLevelStored = bk().backgroundImagePointersByLevel.length - 1;
        
        if (upgradeLevel > maxUpgradeLevelStored) {
            upgradeLevel = maxUpgradeLevelStored;
        }
        
        return bk().backgroundImagePointersByLevel[upgradeLevel];
    }
    
    function tokenSVG(uint tokenId) public view returns (string memory) {
        string memory artwork = tokenBMP(tokenId, 1);
        
        bytes memory innerSVG = abi.encodePacked(
            '<svg xmlns="http://www.w3.org/2000/svg" width="1200" height="1200" viewBox="0 0 1200 1200" version="1.2" style="background-color:transparent;background-image:url(', artwork, ');background-repeat:no-repeat;background-size:contain;background-position:center;image-rendering:-webkit-optimize-contrast;-ms-interpolation-mode:nearest-neighbor;image-rendering:-moz-crisp-edges;image-rendering:pixelated;"/>'
        );
        
        string memory outerSVG = string.concat(
            '<svg xmlns="http://www.w3.org/2000/svg" width="100%" height="100%" viewBox="0 0 1200 1200" version="1.2"><image width="1200" height="1200" href="data:image/svg+xml;base64,', Base64.encode(innerSVG), '"/></svg>'
        );
        
        return outerSVG;
    }
    
    function tokenOffChainPNGURI(uint tokenId) public view returns (string memory) {
        return string.concat(bkExt().baseImageURI, tokenId.toString());
    }
    
    function tokenIdToName(uint tokenId) internal view returns (string memory) {
        string memory customName = bk().punkIdToName[tokenId];
        
        string memory displayName = bytes(customName).length > 0 ?
            customName.escapeJSON() :
            string.concat(bk().nameSingular, " #", formatNumberAsString(tokenId));
            
        return displayName;
    }
    
    function constructTokenURI(uint tokenId) external view returns (string memory) {
        require(_exists(tokenId), "Token does not exist");
        uint80 assets = uint80(tokenId);
        
        int _health = BookMainFacet(address(this)).punkHealth(tokenId);
        uint health = _health >= 0 ? uint(_health) : 0;
        uint upgradeLevel = punkIdToPunkUpradeLevel(tokenId);
        
        uint allocationSize;
        
        if (bkExt().renderMode == 0) {
            (, uint256 paddedLengthScaled) = BMP.computePadding(
                _NATIVE_PUNK_RES * bk().imageScaleUpFactor,
                _NATIVE_PUNK_RES * bk().imageScaleUpFactor
            );
            
            allocationSize = _BMP_URI_PREFIX_LENGTH +
                (4 * (BMP._BMP_HEADER_SIZE + paddedLengthScaled + 2)) /
                3 +
                1024;
        } else if (bkExt().renderMode == 1) {
            allocationSize = 1024 * 128;
        } else if (bkExt().renderMode == 2) {
            allocationSize = 1024 * 128;
        }
        
        bytes memory uri = DynamicBuffer.allocate(allocationSize);
        
        uri.appendSafe('data:application/json;utf-8,{"name":"');
        
        string memory displayName = tokenIdToName(tokenId);
        
        uri.appendSafe(bytes(displayName));

        uri.appendSafe('","description":"');
        uri.appendSafe(bytes(bk().tokenDescription.escapeJSON()));
        
        uri.appendSafe('","external_url":"');
        uri.appendSafe(bytes(bk().externalLink));
        
        if (bkExt().renderMode == 0) {
            uri.appendSafe('","image":"');
            
            bytes memory artwork = _renderBmp(assets);
            _appendArtworkURI(uri, artwork, bk().imageScaleUpFactor);
        } else if (bkExt().renderMode == 1) {
            uri.appendSafe('","image_data":"data:image/svg+xml;base64,');
            uri.appendSafe(bytes(Base64.encode(bytes(tokenSVG(tokenId)))));
        } else if (bkExt().renderMode == 2) {
            uri.appendSafe('","image":"');
            uri.appendSafe(bytes(tokenOffChainPNGURI(tokenId)));
        }

        uri.appendSafe('","attributes":');
        uri.appendSafe(bytes(_attributesAsJSON(assets, health, upgradeLevel, true)));
        uri.appendSafe('}');
        
        return string(uri);
    }
    
    function punkDefaultOverlayOpacity(uint tokenId) internal view returns (uint8) {
        int intHealth = BookMainFacet(address(this)).punkHealth(tokenId);
        uint punkHealth = intHealth >= 0 ? uint(intHealth) : 0;
        uint punkHealthCapacity = BookMainFacet(address(this)).punkHealthCapacity(tokenId);
        
        return uint8(255 - (255 * punkHealth / punkHealthCapacity));
    }
    
    function tokenBMP(uint tokenId, uint32 _imageScaleUpFactor) public view returns (string memory) {
        uint80 assets = uint80(tokenId);
        
        bytes memory artwork = _renderBmp(assets);
        
        return scaleArtwork(artwork, _imageScaleUpFactor);
    }
    
    function tokenBMPFullOptions(
        uint80 packed,
        string memory customBackgroundItem,
        uint upgradeLevel,
        string memory colorMappingItem,
        bool isMirrored,
        uint8 damageOverlayOpacity,
        uint32 _imageScaleUpFactor
    ) external view returns (string memory) {
        bytes memory artwork = _renderBMPFullOptions(
            packed,
            customBackgroundItem,
            upgradeLevel,
            colorMappingItem,
            isMirrored,
            damageOverlayOpacity
        );
        
        return scaleArtwork(artwork, _imageScaleUpFactor);
    }
    
    function scaleArtwork(bytes memory artwork, uint32 _imageScaleUpFactor) internal pure returns (string memory) {
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
        punk.exists = _exists(packedAssets);
        punk.packedAssets = packedAssets;
        punk.assetsArr = unpackAssets(packedAssets);
        punk.assetJSON = _attributesAsJSON(packedAssets, 0, 0, false);
        punk.bmp = tokenBMP(packedAssets, _imageScaleUpFactor);
    }
    
    function getPunkExtended(uint80 packedAssets, uint32 _imageScaleUpFactor) external view returns (PunkExtended memory punkExtended) {
        punkExtended.exists = _exists(packedAssets);
        
        punkExtended.packedAssets = packedAssets;
        punkExtended.assetsArr = unpackAssets(packedAssets);
        punkExtended.assetJSON = _attributesAsJSON(packedAssets, 0, 0, false);
        punkExtended.bmp = tokenBMP(packedAssets, _imageScaleUpFactor);
        punkExtended.name = tokenIdToName(packedAssets);
        
        int _health = BookMainFacet(address(this)).punkHealth(packedAssets);
        punkExtended.health = uint16(_health >= 0 ? uint(_health) : 0);
        punkExtended.upgradeLevel = uint16(punkIdToPunkUpradeLevel(packedAssets));
        
        punkExtended.isMirrored = bkExt().punkIdToIsMirrored[packedAssets];

        string memory colorMappingItem = bkExt().punkIdToColorMappingItem[packedAssets];
        
        if (bkExt().colorMappingItemToIsEnabled[colorMappingItem]) {
            punkExtended.colorMappingItem = colorMappingItem;
        }
        
        string memory customBackgroundItem = bkExt().punkIdToBackgroundItem[packedAssets];
        address possiblePointer = bkExt().gameItemToBackgroundPointer[customBackgroundItem];
        
        if (possiblePointer != address(0)) {
            punkExtended.customBackgroundItem = customBackgroundItem;
        }
        
        if (punkExtended.exists) {
            punkExtended.liveAssetJSON = _attributesAsJSON(packedAssets, punkExtended.health, punkExtended.upgradeLevel, true);
        }
    }
    
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