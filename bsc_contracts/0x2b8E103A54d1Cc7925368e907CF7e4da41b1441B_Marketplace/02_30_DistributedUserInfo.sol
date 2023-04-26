// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

struct UserInfoDistributed {
    bool hasParticipated;
    bool hasParticipatedUsingMint;
    bool hasBurned;
    uint256 volumeWeightage;
    uint256 allWeightages;
    uint256 volume;
    uint256 volumeInEther;
    bool hasWithdrawn;
}