// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

struct CollectionData {
    string uri;
    uint256 total;
    uint256 startTime;
    uint256 endTime;
    uint256 minumumAmount;
    uint256 NFTLimit;
    uint256 stonePrice;
    address admin;
    address factoryAddress;
    address farm;
    address token;
}