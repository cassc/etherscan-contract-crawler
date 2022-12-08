// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

contract StakefishTransactionStorageV3 {
    // Note that the UserSummary definition changed, but the struct layout remains the same in storage.
    // The old definition is included here for reference.
    // struct UserSummary {
    //     uint128 validatorCount;
    //     uint128 totalStartTimestamps;
    //     uint128 partedUptime;
    //     uint128 collectedReward;
    // }
    struct UserSummary {
        uint128 validatorCount;
        uint128 lifetimeCredit;
        uint128 debit;
        uint128 collectedReward;
    }

    // Carried over from v2, no longer used.
    struct DEPRECATED_ComputationCache {
        uint256 lastCacheUpdateTime;
        uint256 totalValidatorUptime;
    }

    /////////////////////////////////////////////////////////////
    // V2 storage preserved to allow in place upgrade.         //
    // Some are deprecated and no longer used.                 //
    /////////////////////////////////////////////////////////////
    address internal adminAddress;
    address internal operatorAddress;

    uint256 internal validatorCount;
    uint256 public stakefishCommissionRateBasisPoints;

    uint256 public lifetimeCollectedCommission;
    uint256 public lifetimePaidUserRewards;

    bool public isOpenForWithdrawal;

    mapping(address => UserSummary) internal users;
    mapping(bytes => uint256) internal validatorOwnerAndJoinTime;
    DEPRECATED_ComputationCache internal DEPRECATED_cache;
    /////////////////////////////////////////////////////////////
    // End of V2 data structures                               //
    /////////////////////////////////////////////////////////////

    // The below are storage variables introduced by V3
    uint256 public amountTransferredToColdWallet;
    uint256 internal accRewardPerValidator;

    uint256 internal lastRewardUpdateBlock;
    uint256 internal lastLifetimeReward;
}