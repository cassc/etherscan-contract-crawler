// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IBurnRedeemable {
    event Redeemed(
        address indexed user,
        address indexed yenContract,
        address indexed tokenContract,
        uint256 yenAmount,
        uint256 tokenAmount
    );

    function onTokenBurned(address user, uint256 amount) external;
}