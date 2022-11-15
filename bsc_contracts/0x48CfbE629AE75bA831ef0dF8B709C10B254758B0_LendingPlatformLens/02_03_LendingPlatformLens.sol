// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import '../modules/Lender/ILendingPlatform.sol';
import '../core/interfaces/ILendingPlatformAdapterProvider.sol';

contract LendingPlatformLens {
    address public immutable foldingRegistry;

    constructor(address registry) public {
        require(registry != address(0), 'ICP0');
        foldingRegistry = registry;
    }

    function getAssetMetadata(address[] calldata platforms, address[] calldata assets)
        external
        returns (AssetMetadata[] memory assetsData)
    {
        require(platforms.length == assets.length, 'LPL1');
        assetsData = new AssetMetadata[](assets.length);

        for (uint256 i = 0; i < assets.length; i++) {
            address lender = getLender(platforms[i]);
            try ILendingPlatform(lender).getAssetMetadata(platforms[i], assets[i]) returns (AssetMetadata memory data) {
                assetsData[i] = data;
            } catch {}
        }
    }

    function getLender(address platform) internal view returns (address) {
        return ILendingPlatformAdapterProvider(foldingRegistry).getPlatformAdapter(platform);
    }
}