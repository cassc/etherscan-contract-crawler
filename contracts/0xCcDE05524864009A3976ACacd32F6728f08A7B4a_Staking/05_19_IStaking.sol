// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

/**
 * @title Interface for Kapital DAO Staking Pool
 * @author Playground Labs
 * @custom:security-contact [email protected]
 */
interface IStaking {
    struct Emission {
        uint128 rate; // KAP rewards per second emitted by the staking pool
        uint128 expiration; // rewards are no longer accumulated after this time
    }

    struct Deposit {
        uint112 amount; // token amount given to the staking pool
        uint64 start; // time of lock period start
        uint64 end; // time of lock period end
        bool collected; // becomes true after principal is collected
        uint256 cumulative; // {cumulative} at time of deposit or last claim
    }

    event Sync(address indexed by, uint256 cumulative);
    event Stake(address indexed staker, uint256 depositId, uint256 amount, uint256 lock);
    event Unstake(address indexed staker, uint256 depositId, uint256 amount);
    event Extend(address indexed staker, uint256 depositId, uint256 extension, uint256 boostRewards);
    event ClaimRewards(address indexed staker, uint256 depositId, uint256 extension, uint256 rewards);
    event UpdateEmission(address indexed updater, uint256 rate, uint256 expiration);
    event TurnOffBoost(address indexed by);
}