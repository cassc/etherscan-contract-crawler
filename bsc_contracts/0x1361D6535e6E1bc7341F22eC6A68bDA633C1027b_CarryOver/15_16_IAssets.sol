// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

interface IAssets {
    struct Asset {
        string symbol;
        address asset;
        address priceFeed;
    }

    function getAsset(string calldata symbol) external view returns (Asset memory);
}