// SPDX-License-Identifier: LICENSED
pragma solidity ^0.7.0;

interface IConverter {
    function convertUsdAmountToAssetAmount(
        uint256 usdAmount,
        address assetAddress
    ) external view returns (uint256);

    function convertAssetAmountToUsdAmount(
        uint256 assetAmount,
        address assetAddress
    ) external view returns (uint256);

    function getUsdAmount(
        address market,
        uint256 assetAmount,
        address priceOracle
    ) external view returns (uint256 usdAmount);

    function getAssetAmount(
        address market,
        uint256 usdAmount,
        address priceOracle
    ) external view returns (uint256 assetAmount);
}