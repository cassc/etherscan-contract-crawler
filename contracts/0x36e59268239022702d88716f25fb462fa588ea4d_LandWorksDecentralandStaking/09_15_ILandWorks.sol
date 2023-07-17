// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "./IERC721Consumable.sol";

interface ILandWorks is IERC721Consumable {
    enum AssetStatus {
        Listed,
        Delisted
    }

    struct Asset {
        uint256 metaverseId;
        address metaverseRegistry;
        uint256 metaverseAssetId;
        address paymentToken;
        uint256 minPeriod;
        uint256 maxPeriod;
        uint256 maxFutureTime;
        uint256 pricePerSecond;
        uint256 totalRents;
        AssetStatus status;
    }

    /// @notice Gets all asset data for a specific asset
    /// @param _assetId The target asset
    function assetAt(uint256 _assetId) external view returns (Asset memory);
}