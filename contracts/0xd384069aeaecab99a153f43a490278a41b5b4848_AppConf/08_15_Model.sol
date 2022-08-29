// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

library Model {
    uint8 constant NFT_TYPE_GENESIS = 1;
    uint8 constant NFT_TYPE_WISH = 2;

    uint8 constant REWARD_TYPE_FIXED = 1;
    uint8 constant REWARD_TYPE_CYCLED = 2;

    uint8 constant STAKING_STATUS_STAKED = 1;
    uint8 constant STAKING_STATUS_UNSTAKED = 2;

    uint8 constant SourceTypeReward = 1;
    uint8 constant SourceTypeGrant = 2;

    struct FarmAddr {
        address farmStakingAddr;
        address farmRewardAddr;
    }

    struct StakingRecord {
        uint256 index;
        address nftToken;
        uint8 nftType;
        uint8 gen;
        string wish;
        address userAddr;
        uint256[] tokenIds;
        uint8 status; // 1=staked, 2=unstaked
        uint256 stakingBlockNumber;
        uint256 stakingTime;
        uint256 unstakingBlockNumber;
        uint256 unstakingTime;
    }

    struct Checkpoint {
        uint256 blockNumber;
        uint256 timestamp;
    }
}