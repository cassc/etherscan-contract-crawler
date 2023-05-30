// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "../lib/0xStandardV2.sol";

contract UglyPeople is OxStandardV2 {
    constructor(
        uint256 _privateSalePrice,
        uint256 _publicSalePrice,
        string memory name,
        string memory symbol,
        uint256 _maxSupply,
        chainlinkParams memory chainlink,
        revenueShareParams memory revenueShare
    ) OxStandardV2(
        _privateSalePrice,
        _publicSalePrice,
        name,
        symbol,
        _maxSupply,
        chainlink,
        revenueShare
    ) {

    }
}