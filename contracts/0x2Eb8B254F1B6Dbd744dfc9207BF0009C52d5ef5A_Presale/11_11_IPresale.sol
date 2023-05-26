// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

interface IPresale {
    event SaleTimeSet(uint256 _start, uint256 _end, uint256 timestamp);

    event TokensBought(
        address indexed user,
        uint256 indexed tokensBought,
        uint256 amountPaid,
        uint256 timestamp
    );

    event TokensClaimed(
        address indexed user,
        uint256 amount,
        uint256 timestamp
    );

    event ClaimStartUpdated(
        uint256 prevValue,
        uint256 newValue,
        uint256 timestamp
    );
}