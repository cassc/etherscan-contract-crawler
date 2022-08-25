// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

interface IOpenSkyPriceAggregator {
    event SetAggregator(address indexed asset, address indexed aggregator);

    function getAssetPrice(address nftAddress) external view returns (uint256);
}