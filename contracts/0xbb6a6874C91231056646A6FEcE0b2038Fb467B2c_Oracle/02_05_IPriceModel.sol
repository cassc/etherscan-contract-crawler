//SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

interface IPriceModel {
    function isPriceModel() external view returns (bool);

    function getAssetPrice(address _asset) external returns (uint256);

    function getAssetStatus(address _asset) external returns (bool);

    function getAssetPriceStatus(address _asset)
        external
        returns (uint256, bool);
}