// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {IGauge} from "./IGauge.sol";

interface IGaugeV2 is IGauge {
    /// @notice A checkpoint for marking balance
    struct Checkpoint {
        uint256 timestamp;
        uint256 balanceOf;
    }

    /// @notice A checkpoint for marking reward rate
    struct RewardPerTokenCheckpoint {
        uint256 timestamp;
        uint256 rewardPerToken;
    }

    /// @notice A checkpoint for marking supply
    struct SupplyCheckpoint {
        uint256 timestamp;
        uint256 supply;
    }

    event Deposit(address indexed from, uint256 amount);
    event Withdraw(address indexed from, uint256 amount);
    event NotifyReward(
        address indexed from,
        address indexed reward,
        uint256 amount
    );
    event ClaimFees(address indexed from, uint256 claimed0, uint256 claimed1);
    event ClaimRewards(
        address indexed from,
        address indexed reward,
        uint256 amount
    );
    event MaxBoostRequirementChanged(uint256 _old, uint256 _new);
}