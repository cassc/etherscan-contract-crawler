// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

interface IRedeemerEvents {
    event Redeemed(
        uint tokenId,
        address indexed asset,
        address to,
        address redeemedAs,
        uint amount
    );
}