pragma solidity ^0.8.9;

library BondStruct {
    struct BondPriceRange {
        uint256 min;
        uint256 max;
        uint256 price;
    }
}