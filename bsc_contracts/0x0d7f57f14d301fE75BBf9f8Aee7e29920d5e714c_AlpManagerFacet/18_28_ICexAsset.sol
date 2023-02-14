// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface ICexAsset {
    enum AssetType {AssetBalance, UnRealizedPnl, TotalNotional}

    struct AssetDetailRecord {
        address symbol;
        int192 balance;
        AssetType assetType;
    }

    struct BatchAssetRecord {
        AssetDetailRecord[] records;
        uint256 blockNumber;
    }

    function getRecordsAtIndex(uint256 _index) external view returns (BatchAssetRecord memory);
}