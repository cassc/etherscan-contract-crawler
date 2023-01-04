// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.17;

interface IBasePriceOracle {
    event AssetStatusSet(address indexed baseAsset, bool indexed isEnabled);

    function supportsAsset(address, address) external view returns (bool);

    function getPrice(address, address) external view returns (bool, uint256);

    function setAssetStatus(address, bool) external;
}