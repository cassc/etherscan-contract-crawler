// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

/**
 * @title Interface for RewardsLocker
 * @author Playground Labs
 * @custom:security-contact [email protected]
 * @notice Interface used by staking contracts to create lock
 * agreements in RewardsLocker when KAP rewards are claimed
 */
interface IRewardsLocker {
    function createLockAgreement(address beneficiary, uint256 amount) external;

    /**
     * @dev Data structure describing a lock agreement created after a user
     * claims KAP staking rewards
     */
    struct LockAgreement {
        uint64 availableTimestamp; // after `availableTimestamp`, `amount` KAP is made available for withdrawal
        uint96 amount; // amount of KAP promised to the beneficiary
        bool collected; // used to prohibit double-collection
    }

    event CreateLockAgreement(address indexed beneficiary, uint256 amount);
    event CollectRewards(address indexed beneficiary, uint256 lockAgreementId);
    event TransferKap(address to, uint256 amount);
}