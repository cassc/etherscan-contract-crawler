// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

// This contract collects transaction fees from a pool of validators, and share the income with the delegators.
// Note that this contract does not collect commissions for stakefish. We always transfer
// balance into StakefishValidator contracts, which is responsible for collecting commissions.
interface IStakefishTransactionFeePoolV2 {
    event ValidatorJoined(bytes indexed validatorPubkey, address indexed depositorAddress, uint256 ts);
    event ValidatorParted(bytes indexed validatorPubkey, address indexed depositorAddress, uint256 ts);
    event ValidatorBulkJoined(bytes validatorPubkeyArray, address[] depositorAddress, uint256 time);
    event ValidatorBulkParted(bytes validatorPubkeyArray, address[] depositorAddress, uint256 time);
    event ValidatorRewardCollected(address indexed depositorAddress, address beneficiary, uint256 rewardAmount, address requester);
    event ValidatorTransferred(bytes indexed validatorPubkey, address indexed from, address indexed to, uint256 ts);
    event OperatorChanged(address newOperator);
    event CommissionRateChanged(uint256 newRate);
    event CommissionCollected(address beneficiary, uint256 collectedAmount);

    // Operator Only
    function joinPool(bytes calldata validatorPubkey, address depositorAddress, uint256 ts) external;
    function partPool(bytes calldata validatorPubkey, uint256 ts) external;
    function bulkJoinPool(bytes calldata validatorPubkeyArray, address[] calldata depositorAddress, uint256 ts) external;
    function bulkPartPool(bytes calldata validatorPubkeyArray, uint256 ts) external;

    // Allow a delegator (msg.sender) in the pool to collect their tip reward from the pool.
    // @amountRequested is the maximum amount of tokens to collect. If set to 0, then all available rewards are collected.
    // @beneficiary is the address to send the reward to; defaults to msg.sender when set to 0.
    function collectReward(address payable beneficiary, uint256 amountRequested) external;

    // Note: this function is not enabled right now to keep the product simple.
    // Transfer the ownership of the tips associated with a validator to another address.
    // Future tips will go to the new owner address, effective as of the time the transaction is processed.
    // @validatorPubkey is the validator to transfer the tips for.
    // @newOwner is the address to transfer future tips to.
    // function transferValidatorByOwner(bytes calldata validatorPubkey, address newOwner) external;

    // Admin Only
    function setCommissionRate(uint256) external;
    function collectPoolCommission(address payable beneficiary, uint256 amountRequested) external;
    function changeOperator(address _newOperator) external;
    function closePoolForWithdrawal() external;
    function openPoolForWithdrawal() external;
    function transferValidatorByAdmin(bytes calldata validatorPubkeys, address[] calldata tos, uint256 timestamp) external;
    function transferClaimHistory(address[] calldata addresses, uint256[] calldata claimAmount) external;

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
    function getPoolState() external view returns (uint256, uint256, uint256, uint256, uint256);
    function getUserState(address user) external view returns (uint256, uint256, uint256, uint256);
    receive() external payable;
}