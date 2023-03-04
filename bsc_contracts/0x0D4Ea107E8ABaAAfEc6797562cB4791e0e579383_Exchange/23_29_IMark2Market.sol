// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.0 <0.9.0;

interface IMark2Market {

    struct StrategyAsset {
        address strategy;
        uint256 netAssetValue;
        uint256 liquidationValue;
    }

    function strategyAssets() external view returns (StrategyAsset[] memory);

    function totalNetAssets() external view returns (uint256);

    function totalLiquidationAssets() external view returns (uint256);

}