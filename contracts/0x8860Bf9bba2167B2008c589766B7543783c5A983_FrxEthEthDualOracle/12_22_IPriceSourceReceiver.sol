// SPDX-License-Identifier: ISC
pragma solidity ^0.8.19;

interface IPriceSourceReceiver {
    function addRoundData(bool isBadData, uint104 priceLow, uint104 priceHigh, uint40 timestamp) external;

    function getPrices() external view returns (bool isBadData, uint256 priceLow, uint256 priceHigh);
}