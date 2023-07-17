// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

abstract contract xRooStaking {
     struct UserData {
        uint256 stake;
        uint256 liquidity;
        uint256 lastTimestamp;
        int256 RTRewardModifier;
        int256 NFTXRewardModifier;
        uint256 NFTXRewardWithdrawn;
    }

    mapping(address => UserData) public users;
}