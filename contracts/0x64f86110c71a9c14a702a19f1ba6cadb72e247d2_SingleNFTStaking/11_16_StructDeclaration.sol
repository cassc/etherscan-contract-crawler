// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

struct InitializeParam {
    address stakeNftAddress;
    address rewardTokenAddress;
    uint256 stakeNftPrice;
    uint256 apr;
    address creatorAddress;
    uint256 maxStakedNfts;
    uint256 maxNftsPerUser;
    uint256 depositFeePerNft;
    uint256 withdrawFeePerNft;
    uint256 startTime;
    uint256 endTime;
}