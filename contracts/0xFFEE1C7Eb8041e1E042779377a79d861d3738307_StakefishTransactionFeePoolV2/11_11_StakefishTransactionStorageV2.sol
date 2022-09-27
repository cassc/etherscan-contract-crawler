// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

contract StakefishTransactionStorageV2 {
    struct UserSummary {
        uint128 validatorCount;
        uint128 totalStartTimestamps;
        uint128 partedUptime;
        uint128 collectedReward;
    }

    struct ComputationCache {
        uint256 lastCacheUpdateTime;
        uint256 totalValidatorUptime;
    }

    address internal adminAddress;
    address internal operatorAddress;

    uint256 internal validatorCount;
    uint256 public stakefishCommissionRateBasisPoints;

    uint256 public lifetimeCollectedCommission;
    uint256 public lifetimePaidUserRewards;

    bool public isOpenForWithdrawal;

    mapping(address => UserSummary) internal users;
    // This uint256 packs two information:
    //   The lower 4 bytes are a timestamp representing the join pool time of the validator.
    //   The next 20 bytes are the ETH1 address of the owner.
    mapping(bytes => uint256) internal validatorOwnerAndJoinTime;

    ComputationCache internal cache;
}