// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import { IPriceProvider } from "../interfaces/IPriceProvider.sol";

contract MockPriceProvider is IPriceProvider {
    uint256 _price;

    constructor() {}

    function setPrice(uint256 price) external {
        _price = price;
    }

    function getPrice() external view returns (uint256) {
        return _price;
    }
}