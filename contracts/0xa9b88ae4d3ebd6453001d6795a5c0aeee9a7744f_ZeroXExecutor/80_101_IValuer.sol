// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

interface IValuer {
    struct AssetValue {
        address asset;
        uint256 totalMinValue;
        uint256 totalMaxValue;
        AssetBreakDown[] breakDown;
    }

    struct AssetBreakDown {
        address asset;
        uint256 balance;
        uint256 minValue;
        uint256 maxValue;
    }

    function getVaultValue(
        address vault,
        address asset,
        int256 unitPrice
    ) external view returns (uint256 minValue, uint256 maxValue);

    function getAssetValue(
        uint amount,
        address asset,
        int256 unitPrice
    ) external view returns (uint256 minValue, uint256 maxValue);

    // This returns an array because later on we may support assets that have multiple tokens
    // Or we may want to break GMX down into individual positions
    function getAssetBreakdown(
        address vault,
        address asset,
        int256 unitPrice
    ) external view returns (AssetValue memory);
}