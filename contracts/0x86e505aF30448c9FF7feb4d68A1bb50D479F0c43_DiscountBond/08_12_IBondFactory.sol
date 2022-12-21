// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.9;

interface IBondFactory {
    struct BondPrice {
        uint256 price;
        uint256 bid;
        uint256 ask;
        uint256 lastUpdated;
    }

    function priceFactor() external view returns (uint256);

    function getPrice(address bondToken_) external view returns (BondPrice memory price);
}