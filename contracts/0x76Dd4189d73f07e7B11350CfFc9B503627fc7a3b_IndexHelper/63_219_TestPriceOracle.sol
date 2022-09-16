// SPDX-License-Identifier: Apache-2.0

pragma solidity 0.8.13;

import "../interfaces/IPriceOracle.sol";

contract TestPriceOracle is IPriceOracle {
    mapping(address => uint) public assetPrice;

    function refreshedAssetPerBaseInUQ(address _asset) external returns (uint) {
        return assetPrice[_asset];
    }

    function lastAssetPerBaseInUQ(address _asset) external view returns (uint) {
        return assetPrice[_asset];
    }

    function setPrice(address _asset, uint price) external {
        assetPrice[_asset] = price;
    }
}