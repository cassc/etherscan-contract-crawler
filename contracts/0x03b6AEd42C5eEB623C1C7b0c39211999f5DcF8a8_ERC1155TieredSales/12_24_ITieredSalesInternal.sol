// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

interface ITieredSalesInternal {
    struct Tier {
        uint256 start;
        uint256 end;
        address currency;
        uint256 price;
        uint256 maxPerWallet;
        bytes32 merkleRoot;
        uint256 reserved;
        uint256 maxAllocation;
    }

    event TierSale(uint256 indexed tierId, address indexed operator, address indexed minter, uint256 count);
}