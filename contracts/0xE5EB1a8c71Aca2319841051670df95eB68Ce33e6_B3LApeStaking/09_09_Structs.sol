//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

struct DashboardStake {
    uint256 poolId;
    uint256 tokenId;
    uint256 deposited;
    uint256 unclaimed;
    uint256 rewards24hr;
    DashboardPair pair;
}

struct DashboardPair {
        uint256 mainTokenId;
        uint256 mainTypePoolId;
}