// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <=0.9.0;

interface IAaveV1PriceOracle {
    function getAssetPrice(address _asset) external view returns (uint256);
}