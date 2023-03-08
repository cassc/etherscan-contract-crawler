// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "hardhat/console.sol";

import {BMP} from "@divergencetech/ethier/contracts/utils/BMP.sol";
import {Image, Rectangle} from "@divergencetech/ethier/contracts/utils/Image.sol";
import {DynamicBuffer} from "@divergencetech/ethier/contracts/utils/DynamicBuffer.sol";
import "solady/src/utils/Base64.sol";

import "./LibStorage.sol";

import {BookInternalFacet} from "./BookInternalFacet.sol";

import "solady/src/utils/DynamicBufferLib.sol";

contract BookDataFacetPosterExt is WithStorage, BookInternalFacet {
    using DynamicBufferLib for DynamicBufferLib.DynamicBuffer;
    using DynamicBuffer for bytes;
    using Image for bytes;
    
    function getAssetName(uint8 asset) external view returns (string memory) {
        return ps().assetNames[asset];
    }
    
    function assetSlotToTraitType(uint8 assetSlot) external view returns (string memory) {
        return ps().assetSlotToTraitType[assetSlot];
    }
    
    function renderBmpMinimal(
        uint80 packed,
        uint24 backgroundColor
    ) external view returns (string memory) {
        bytes memory imageBytes = new bytes(24 * 24 * 3);
        imageBytes.fill(backgroundColor);

        Rectangle memory rect = Rectangle(0, 0, 24, 24);

        uint256 mask = 0xff << 72;
        
        unchecked {
            for (uint8 j = 0; j < 10; ++j) {
                uint8 assetIndex = uint8(
                    (packed & (mask >> (j * 8))) >> (8 * (9 - j))
                );
                if (assetIndex > 0) {
                    bytes memory assetPixels = renderAssetMinimal(assetIndex);
                    
                    imageBytes.alphaBlend(assetPixels, 24, rect);
                }
            }
        }
        
        (, uint256 paddedLengthScaled) = BMP.computePadding(
            24,
            24
        );

        bytes memory uri = DynamicBuffer.allocate(
            22 +
                (4 * (BMP._BMP_HEADER_SIZE + paddedLengthScaled + 2)) /
                3 +
                1024
        );
        
        uri.appendSafeBase64(
            BMP.bmp(imageBytes, 24, 24),
            false,
            false
        );
        
        return string(uri);
    }
    
    function renderAssetMinimal(
        uint8 assetIndex
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
                            uint yVal = 2 * v[1] + dy;
                            uint xVal = 2 * v[0] + dx;
                            
                            uint256 p = ((23 - yVal) * 24 + xVal) * 4;
                                
                            if (v[2] & (1 << (dx * 2 + dy)) != 0) {
                                bytes4 c = composite(
                                    a[i * 3 + 1]
                                );
                                
                                pixels[p] = c[3];
                                pixels[(p) + 1] = c[2];
                                pixels[(p) + 2] = c[1];
                                pixels[(p) + 3] = c[0];
                            } else if (v[3] & (1 << (dx * 2 + dy)) != 0) {
                                pixels[p] = 0xFF;
                                pixels[p + 1] = 0;
                                pixels[p + 2] = 0;
                                pixels[p + 3] = 0;
                            }
                        }
                    }
                }
            }
        }
        
        return pixels;
    }
}