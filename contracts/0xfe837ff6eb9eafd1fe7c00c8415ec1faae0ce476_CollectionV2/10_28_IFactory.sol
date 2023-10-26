// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

struct CollectionData {
    string uri;
    uint256 total;
    uint256 startTime;
    uint256 endTime;
    uint256 amount;
    uint256 percent;
    address admin;
    address factoryAddress;
    uint8 currencyType;
    address farm;
    address moneyHandler;
    address treasury;
    address token;
    address stone;
    address operatorSubscription;
}

interface IFactory {
    function getPriceOracle() external view returns (address);
}