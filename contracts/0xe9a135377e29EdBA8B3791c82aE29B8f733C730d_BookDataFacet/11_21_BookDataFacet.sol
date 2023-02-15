// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "hardhat/console.sol";
import "solady/src/utils/SSTORE2.sol";
import "solady/src/utils/LibString.sol";

import {BMP} from "@divergencetech/ethier/contracts/utils/BMP.sol";
import {Image, Rectangle} from "@divergencetech/ethier/contracts/utils/Image.sol";
import {DynamicBuffer} from "@divergencetech/ethier/contracts/utils/DynamicBuffer.sol";
import "solady/src/utils/Base64.sol";

import "hardhat-deploy/solc_0.8/diamond/UsingDiamondOwner.sol";

import "./LibStorage.sol";

import {BookInternalFacet} from "./BookInternalFacet.sol";

import "solady/src/utils/DynamicBufferLib.sol";

contract BookDataFacet is UsingDiamondOwner, WithStorage, BookInternalFacet {
    using LibString for *;
    using EnumerableSet for EnumerableSet.UintSet;

    using DynamicBufferLib for DynamicBufferLib.DynamicBuffer;
    using DynamicBuffer for bytes;
    using Image for bytes;
    
    function getBases() external view returns (uint[] memory) {
        return ps().validBases.toArray();
    }
    
    function getAttributeRanges() external view returns (uint[][9][6] memory ranges) {
        for (uint8 i; i < ranges.length; ++i) {
            for (uint8 j; j < 9; ++j) {
                ranges[i][j] = ps().genderedAttributes[i][j].toArray();
            }
        }
    }
    
    function setAttributeRanges(uint8[][][6] calldata slotRanges) external onlyOwner {
        for (uint8 _gender; _gender < slotRanges.length; _gender++) {
            for (uint8 _attributeSlot; _attributeSlot < slotRanges[_gender].length; _attributeSlot++) {
                uint8[] memory _attributes = slotRanges[_gender][_attributeSlot];
                
                for (uint _attrIdx; _attrIdx < _attributes.length; _attrIdx++) {
                    ps().genderedAttributes[_gender][_attributeSlot].add(_attributes[_attrIdx]);
                }
            }
        }
    }
    
    function updatePackedAssetsToOldPunksIdPlusOneMap(uint80[2][] calldata oldPunksArray) external onlyOwner {
        unchecked {
            for (uint i; i < oldPunksArray.length; ++i) {
                uint80[2] memory current = oldPunksArray[i];
                ps().packedAssetsToOldPunksIdPlusOneMap[current[0]] = uint16(current[1]);
            }
        }
    }
    
    function addAsset(
        uint8 index,
        bytes calldata encoding,
        string calldata name
    ) external onlyOwner {
        ps().assets[index] = encoding;
        ps().assetNames[index] = name;
    }
    
    function addAssetBatch(
        uint8[] calldata indices,
        bytes[] calldata encodings,
        string[] calldata names
    ) external onlyOwner {
        require(indices.length == encodings.length);
        require(indices.length == names.length);
        
        unchecked {
            for (uint256 i = 0; i < indices.length; ++i) {
                ps().assets[indices[i]] = encodings[i];
                ps().assetNames[indices[i]] = names[i];
            }
        }
    }

    function renderAsset(
        uint8 assetIndex,
        bool aBGRMode,
        bool[576] memory overallPixelIndicesUsed
    ) public view returns (bytes memory) {
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
                            uint256 p = ((2 * v[1] + dy) *
                                24 +
                                (2 * v[0] + dx)) * 4;
                            if (v[2] & (1 << (dx * 2 + dy)) != 0) {
                                bytes4 c = composite(
                                    a[i * 3 + 1]
                                );
                                
                                if (aBGRMode) {
                                    pixels[p] = c[3];
                                    pixels[p + 1] = c[2];
                                    pixels[p + 2] = c[1];
                                    pixels[p + 3] = c[0];
                                } else {
                                    pixels[p] = c[0];
                                    pixels[p + 1] = c[1];
                                    pixels[p + 2] = c[2];
                                    pixels[p + 3] = c[3];
                                }
                                
                                overallPixelIndicesUsed[(2 * v[1] + dy) * 24 + (2 * v[0] + dx)] = true;
                            } else if (v[3] & (1 << (dx * 2 + dy)) != 0) {
                                if (aBGRMode) {
                                    pixels[p] = 0xFF;
                                    pixels[p + 1] = 0;
                                    pixels[p + 2] = 0;
                                    pixels[p + 3] = 0;
                                } else {
                                    pixels[p] = 0;
                                    pixels[p + 1] = 0;
                                    pixels[p + 2] = 0;
                                    pixels[p + 3] = 0xFF;
                                }
                                
                                overallPixelIndicesUsed[(2 * v[1] + dy) * 24 + (2 * v[0] + dx)] = true;
                            }
                        }
                    }
                }
            }
        }
        
        return pixels;
    }
    
    function renderAssetSvgRects(uint8 assetIndex) public view returns (string memory) {
        DynamicBufferLib.DynamicBuffer memory svgBytes;
        
        bool[576] memory overallPixelIndicesUsed;

        bytes memory pixels = renderAsset(assetIndex, false, overallPixelIndicesUsed);

        bytes memory buffer = new bytes(8);
        
        unchecked {
            for (uint256 y = 0; y < 24; y++) {
                for (uint256 x = 0; x < 24; x++) {
                    uint256 p = (y * 24 + x) * 4;
                    if (uint8(pixels[p + 3]) > 0) {
                        for (uint256 i = 0; i < 4; i++) {
                            uint8 value = uint8(pixels[p + i]);
                            buffer[i * 2 + 1] = _HEX_SYMBOLS[value & 0xf];
                            value >>= 4;
                            buffer[i * 2] = _HEX_SYMBOLS[value & 0xf];
                        }
                        svgBytes.append(
                            abi.encodePacked(
                                '<rect x="',
                                x.toString(),
                                '" y="',
                                y.toString(),
                                '" fill="#',
                                string(buffer),
                                '"/>'
                            )
                        );
                    }
                }
            }
        }
        
        return string(svgBytes.data);
    }
    
    function renderSvg(uint80 packed, string memory bg) public view returns (string memory) {
        if (packed == 0) return '';
        
        DynamicBufferLib.DynamicBuffer memory svgBytes;
        
        svgBytes.append(abi.encodePacked('<svg width="1200" height="1200" shape-rendering="crispEdges" xmlns="http://www.w3.org/2000/svg" version="1.2" viewBox="0 0 24 24"><style>rect{width:1px;height:1px}</style><rect x="0" y="0" style="width:100%;height:100%" fill="#', bg, '" />'));

        uint256 mask = 0xff << 72;
        
        for (uint8 j = 0; j < 10; j++) {
            uint8 assetIndex = uint8(
                (packed & (mask >> (j * 8))) >> (8 * (9 - j))
            );
            if (assetIndex > 0) {
                svgBytes.append(bytes(renderAssetSvgRects(assetIndex)));
            }
        }
        
        svgBytes.append(bytes("</svg>"));

        return string(svgBytes.data);
    }

    function getPackedAssetNames(uint80 packed)
        public
        view
        returns (string memory text)
    {
        uint96 mask = 0xff << 72;
        for (uint8 j = 0; j < 10; j++) {
            uint8 asset = uint8((packed & (mask >> (j * 8))) >> (8 * (9 - j)));
            if (asset > 0) {
                if (j > 0) {
                    text = string(
                        abi.encodePacked(text, ", ", ps().assetNames[asset])
                    );
                } else {
                    text = ps().assetNames[asset];
                }
            }
        }
    }
    
    function arrayToAssetNames(uint8[10] memory assetsArr) public view returns (string memory) {
        return getPackedAssetNames(packAssets(assetsArr));
    }
    
    function attributesAsJSON(uint80 packed, bool addHealthAndUpgrade, uint health, uint upgradeLevel) public view returns (string memory json) {
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
        
        if (addHealthAndUpgrade) {
            buffer.append(abi.encodePacked(',{"display_type": "number", "trait_type":"Health","value":', health.toString(), '},'));
            buffer.append(abi.encodePacked('{"display_type": "number", "trait_type":"Upgrade Level","value":', (upgradeLevel + 1).toString(), '}'));
        }
        
        buffer.append(bytes(']'));
        
        return string(buffer.data);
    }
    
    function postProcessImage(
        bytes memory pixels,
        bool[576] memory overallPixelIndicesUsed,
        uint8 defaultBGOpacity
    ) public pure returns (bytes memory) {
        bytes memory newPixels = new bytes(pixels.length);
        
        bytes1 alpha = bytes1(defaultBGOpacity);
        bytes1 blue = bytes1(uint8(151));
        bytes1 green = bytes1(uint8(138));
        bytes1 red = bytes1(uint8(120));
        
        uint32 blendValAsUint = uint32(
            uint32(uint8(alpha)) << 24 |
            uint32(uint8(blue)) << 16 |
            uint32(uint8(green)) << 8 |
            uint32(uint8(red))
        );
        
        unchecked {
            for (uint256 y = 0; y < 24; ++y) {
                for (uint256 x = 0; x < 24; ++x) {
                    uint256 p = (y * 24 + x) * 3;
                    uint256 p2 = ((23 - y) * 24 + x) * 3;
                    newPixels[p] = pixels[p2];
                    newPixels[p + 1] = pixels[p2 + 1];
                    newPixels[p + 2] = pixels[p2 + 2];
                    
                    uint pixelIndex = (23 - y) * 24 + x;
                    
                    if (defaultBGOpacity > 0 && overallPixelIndicesUsed[pixelIndex]) {
                        uint24 currentPixelValAsUint = uint24(
                            uint24(uint8(newPixels[p])) << 16 |
                            uint24(uint8(newPixels[p + 1])) << 8 |
                            uint24(uint8(newPixels[p + 2]))
                        );
                        
                        uint24 blendedVal = Image.alphaBlend(
                            currentPixelValAsUint,
                            blendValAsUint
                        );
                        
                        newPixels[p] = bytes1(uint8(blendedVal >> 16));
                        newPixels[p + 1] = bytes1(uint8(blendedVal >> 8));
                        newPixels[p + 2] = bytes1(uint8(blendedVal));
                    }
                }
            }
        }
        return newPixels;
    }
    
    function renderBmp(
        uint80 packed,
        address backgroundImagePointer,
        uint24 backgroundColor,
        uint8 defaultBGopacity
    ) public view returns (bytes memory imageBytes) {
        if (backgroundImagePointer != address(0)) {
            imageBytes = SSTORE2.read(backgroundImagePointer);
        } else {
            imageBytes = new bytes(24 * 24 * 3);
            imageBytes.fill(backgroundColor);
        }

        Rectangle memory rect = Rectangle(0, 0, 24, 24);

        uint256 mask = 0xff << 72;
        
        bool[576] memory overallPixelIndicesUsed;
        
        unchecked {
            for (uint8 j = 0; j < 10; ++j) {
                uint8 assetIndex = uint8(
                    (packed & (mask >> (j * 8))) >> (8 * (9 - j))
                );
                if (assetIndex > 0) {
                    bytes memory assetPixels = renderAsset(assetIndex, true, overallPixelIndicesUsed);
                    
                    imageBytes.alphaBlend(assetPixels, 24, rect);
                }
            }
        }
        
        return postProcessImage(
            imageBytes,
            overallPixelIndicesUsed,
            defaultBGopacity
        );
    }
    
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
}