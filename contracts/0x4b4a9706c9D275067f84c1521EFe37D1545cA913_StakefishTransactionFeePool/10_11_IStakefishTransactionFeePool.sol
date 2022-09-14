// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

// This contract collects transaction fees from a pool of validators, and share the income with the delegators.
// Note that this contract does not collect commissions for stakefish. We always transfer
// balance into StakefishValidator contracts, which is responsible for collecting commissions.
interface IStakefishTransactionFeePool {
    struct UserSummary {
        uint256 validatorCount;
        // Think of this as the average validator start timestamp * total validator count.
        // It's more efficient to store the sum compared to the average to avoid divisions.
        uint256 totalStartTimestamps;
        // The amount of rewards earmarked for this user, but not yet collected.
        uint256 pendingReward;
        // The amount of reward already collected by the user.
        uint256 collectedReward;
    }

    struct ComputationCache {
        uint256 lastCacheUpdateTime;
        uint256 totalValidatorUptime;

        // The part of contract balance that belong to stakefish as commissions.
        uint256 totalUncollectedCommission;
        // The part of contract balance that belong to delegators, but not yet earmarked for specific users.
        uint256 totalUncollectedUserBalance;
        // The part of contract balance that are earmarked for distribution to specific users but not yet collected.
        uint256 totalUnsentUserRewards;
    }

    event ValidatorJoined(bytes indexed validatorPubkey, address indexed depositorAddress, uint256 ts);
    event ValidatorParted(bytes indexed validatorPubkey, address indexed depositorAddress, uint256 ts);
    event ValidatorBulkJoined(bytes validatorPubkeyArray, address[] depositorAddress, uint256 time);
    event ValidatorBulkParted(bytes validatorPubkeyArray, address[] depositorAddress, uint256 time);
    event ValidatorRewardCollected(address indexed depositorAddress, address beneficiary, uint256 rewardAmount, address requester);
    event OperatorChanged(address newOperator);
    event CommissionRateChanged(uint256 newRate);

    // Operator Only
    function joinPool(bytes calldata validatorPubkey, address depositorAddress, uint256 ts) external;
    function partPool(bytes calldata validatorPubkey, uint256 ts) external;
    function bulkJoinPool(bytes calldata validatorPubkeyArray, address[] calldata depositorAddress, uint256 ts) external;
    function bulkPartPool(bytes calldata validatorPubkeyArray, uint256 ts) external;

    // Allow a delegator (msg.sender) in the pool to collect their tip reward from the pool.
    // @amountRequested is the maximum amount of tokens to collect. If set to 0, then all available rewards are collected.
    // @beneficiary is the address to send the reward to; defaults to msg.sender when set to 0.
    function collectReward(address payable beneficiary, uint256 amountRequested) external;

    // Admin Only
    function setCommissionRate(uint256) external;
    function collectPoolCommission(address payable beneficiary, uint256 amountRequested) external;
    function changeOperator(address _newOperator) external;
    function closePoolForWithdrawal() external;
    function openPoolForWithdrawal() external;

    // Allows an admin to trigger withdraw on behalf of an user into the admin's address.
    // This is used to help users recover funds if they lose their account.
    // @depositorAddresses is the list of addresses of the delegators in the pool for which to withdraw rewards from.
    // @beneficiaries is the addresses to send the reward to; defaults to the corresponding depositors when set to 0.
    // @amountRequested is the maximum amount of tokens to withdraw. If set to 0, then all available rewards are withdrawn.
    function emergencyWithdraw(address[] calldata depositorAddresses, address[] calldata beneficiaries, uint256 amountRequested) external;

    // Functions for the general public
    // Check the amount of pending rewards for a given delegator--he can withdraw up to this amount.
    // Also returns the amount of already collected reward.
    // @returns (uint256, uint256) - (pendingReward, collectedReward)
    function pendingReward(address depositorAddress) external view returns (uint256, uint256);
    function totalValidators() external view returns (uint256);
    function getPoolState() external view returns (ComputationCache memory);
    receive() external payable;
}