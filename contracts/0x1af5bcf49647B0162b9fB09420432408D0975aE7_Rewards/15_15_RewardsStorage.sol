// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "../interface/IESMET.sol";
import "../interface/IRewards.sol";

abstract contract RewardsStorageV1 is IRewards {
    struct Reward {
        bool isBoosted; // linear distribution if false
        uint256 periodFinish; // end of a drip period
        uint256 rewardPerSecond; // distribution per second (i.e. dripAmount/dripPeriod)
        uint256 lastUpdateTime; // stores last drip time
        uint256 rewardPerTokenStored; // reward per MET
    }

    struct UserReward {
        uint128 rewardPerTokenPaid; // reward per MET accumulator
        uint128 claimableRewardsStored; // pending to claim
    }

    /**
     * @notice Locker contract
     */
    IESMET public esMET;

    /**
     * @notice Array of reward tokens
     */
    address[] public rewardTokens;

    /**
     * @notice Rewards state per token
     * @dev RewardToken => Reward
     */
    mapping(address => Reward) public rewards;

    /**
     * @notice User's rewards state per token
     * @dev User => RewardToken => UserReward
     */
    mapping(address => mapping(address => UserReward)) public rewardOf;

    /**
     * @notice Reward distributors
     * RewardToken -> distributor -> is approved to drip
     */
    mapping(address => mapping(address => bool)) public isRewardDistributor;
}