// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

interface IPresale {
    event SaleTimeUpdated(
        uint256 saleStartTime,
        uint256 saleEndTime,
        uint256 timestamp
    );

    event TokensClaimed(
        address indexed user,
        uint256 amount,
        uint256 timestamp
    );

    event ClaimStartTimeUpdated(
        uint256 newValue,
        uint256 timestamp
    );

    event TokensBought(
        address indexed user,
        bytes32 indexed currency,
        uint256 amount,
        uint256 totalCostInUsd,
        uint256 totalCostInCurrency,
        uint256 timestamp
    );
}