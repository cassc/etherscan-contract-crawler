// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import "../sale/SaleContract.sol";

contract sale is SaleContract {
    constructor(SaleConfiguration memory config) SaleContract(config) {}
}