// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

/**
 * IStakefishTransactionFeePoolV2
 * This contract collects transaction fees from a pool of validators, and shares the income with their delegators (depositors).
 */
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

    /**
     * @notice Add a validator to the pool
     * @dev operatorOnly.
     * Calls {_joinPool}.
     * Emits an {ValidatorJoined} event.
     * Reverts if `validatorPubkey` is already in the pool (Validator already in pool).
     * Reverts if the `depositorAddress` address is not set (depositorAddress must be set).
     * Reverts if `joinTime` is set in the future (Invalid validator joinTime).
     * @param validatorPubKey The validator's public key
     * @param depositorAddress The delegator that is associated with the validator
     * @param joinTime The timestamp when the validator started accruing payable uptime
     */
    function joinPool(bytes calldata validatorPubKey, address depositorAddress, uint256 joinTime) external;

    /**
     * @notice Remove a validator from the pool
     * @dev operatorOnly.
     * Calls {_partPool}.
     * Emits an {ValidatorParted} event.
     * Reverts if the `validatorPubKey` is not in the pool (Validator not in pool).
     * Reverts if the `leaveTime` is in the future (Invalid validator leaveTime).
     * Reverts if the `leaveTime` is before the validator's `joinTime` (leave pool time must be after join pool time).
     * @param validatorPubKey The validator's public key
     * @param leaveTime The timestamp when the validator stopped accruing payable uptime
     */
    function partPool(bytes calldata validatorPubKey, uint256 leaveTime) external;

    /**
     * @notice Add many validators to the pool
     * @dev operatorOnly.
     * Emits an {ValidatorBulkJoined} event.
     * Reverts if `joinTime` is in the future (Invalid validator join timestamp).
     * Reverts if `depositorAddresses`.length is != 1 and != `validatorPubKeyArray`length / 48 (Invalid depositorAddresses length).
     * Reverts if any of the depositor addresses is not set (depositorAddress must be set).
     * Reverts if any of the validators are already in the pool (Validator already in pool).
     * @param validatorPubKeyArray The list of validator public keys to add (must be a multiple of 48)
     * @param depositorAddresses The depositor addresses to associate with the validators.
     * If length is 1, then the same depositor address is used for all validators.
     * Otherwise the array must have length equal to validatorPubKeys.length / 48.
     * @param joinTime The timestamp when the validators started accruing payable uptime
     */
    function bulkJoinPool(bytes calldata validatorPubKeyArray, address[] calldata depositorAddresses, uint256 joinTime) external;

    /**
     * @notice Remove many validators from the pool
     * @dev operatorOnly.
     * Calls {_partPool}.
     * Emits one {ValidatorBulkParted} and many {ValidatorParted} events.
     * Reverts if `validatorPubKeyArray` is not divisible by 48 (Validator length not multiple of 48).
     * Reverts if the `validatorPubKey` is not in the pool (Validator not in pool).
     * Reverts if the `leaveTime` is in the future (Invalid validator leaveTime).
     * Reverts if the `leaveTime` is before the validator's `joinTime` (leave pool time must be after join pool time).
     * @param validatorPubKeyArray The list of validator public keys to remove (must be a multiple of 48)
     * @param leaveTime The timestamp when the validators stopped accruing payable uptime
     */
    function bulkPartPool(bytes calldata validatorPubKeyArray, uint256 leaveTime) external;

    // Admin Only

    /**
     * @notice Set the contract commission rate
     * @dev adminOnly.
     * Emits an {CommissionRateChanged} event.
     * @param commissionRate The new commission rate
     */
    function setCommissionRate(uint256 commissionRate) external;

    /**
     * @notice Collect new commission fees, up to `amountRequested`.
     * @dev adminOnly.
     * Emits an {CommissionCollected} event.
     * @param beneficiary The address that the `amountRequested` will be sent to
     * @param amountRequested The amount that will be sent to the `beneficiary`. If 0, collect all fees.
     */
    function collectPoolCommission(address payable beneficiary, uint256 amountRequested) external;

    /**
     * @notice Change the contract operator
     * @dev adminOnly.
     * Emits an {OperatorChanged} event.
     * Reverts if `newOperator` is not set ().
     * @param newOperator The new operator
     */
    function changeOperator(address newOperator) external;

    /**
     * @notice Temporarily disable reward collection during a contract maintenance window
     * @dev adminOnly.
     * Reverts if `isOpenForWithdrawal` (Pool is already closed for withdrawal).
     */
    function closePoolForWithdrawal() external;

    /**
     * @notice Enable reward collection after a temporary contract maintenance window
     * @dev adminOnly.
     * Reverts if !`isOpenForWithdrawal` (Pool is already open for withdrawal).
     */
    function openPoolForWithdrawal() external;

    /**
     * @notice Transfer one or more validators to new fee pool owners.
     * @dev adminOnly.
     * Calls {_transferValidator}, which calls {_partPool} and {_joinPool}.
     * Emits many {ValidatorParted}, {ValidatorJoined} and {ValidatorTransferred} events.
     * Reverts if `validatorPubKeys`.length != `toAddresses`.length * 48 (validatorPubKeys byte array length incorrect).
     * Reverts if the `validatorPubKey` is not in the pool (Validator not in pool).
     * Reverts if `toAddresses[i]` is not set (to address must be set to nonzero).
     * Reverts if `toAddresses[i]` is the validator's depositor (cannot transfer validator owner to oneself).
     * Reverts if `transferTimestamp` is before the validator's `joinTime` (Validator transferTimestamp is before join pool time).
     * Reverts if `transferTimestamp` is in the future (Validator transferTimestamp is in the future).
     * @param validatorPubKeys The list of validators that will be transferred
     * @param toAddresses The list of addresses that the validators will be transferred to
     * @param transferTimestamp The time when the validators were transferred
     */
    function transferValidatorByAdmin(bytes calldata validatorPubKeys, address[] calldata toAddresses, uint256 transferTimestamp) external;

    /**
     * @notice Transfer historical claim amounts into this contract
     * @dev adminOnly (used during contract migration) (not idempotent!)
     * @param addresses The list of depositor addresses that collected
     * @param claimAmounts The total amount collected by each depositor
     */
    function transferClaimHistory(address[] calldata addresses, uint256[] calldata claimAmounts) external;

    /**
     * @notice Admin function to help users recover funds from a lost or stolen wallet
     * @dev adminOnly.
     * Calls {_collectReward}.
     * Emits an {ValidatorRewardCollected} event.
     * Reverts if `depositorAddresses`.length != `beneficiaries`.length and `beneficiaries`.length != 1 (beneficiaries length incorrect).
     * Reverts if the pool is not open for withdrawals (Pool is not open for withdrawal right now).
     * @param depositorAddresses The list of depositors to withdraw rewards from
     * @param beneficiaries The list of addresses that will be sent the depositors' rewards
     * @param amountRequested The max amount to be withdrawn. If 0, all depositors' pending rewards will be withdrawn.
     */
    function emergencyWithdraw(address[] calldata depositorAddresses, address[] calldata beneficiaries, uint256 amountRequested) external;

    // Public

    /**
     * @notice The amount of rewards a depositor can withdraw, and all rewards they have ever withdrawn
     * @dev Reverts if `depositorAddress` is not set (depositorAddress must be set).
     * Returns (
     * uint256 pendingRewards: The current amount available for withdrawal by the depositor,
     * uint256 collectedRewards: The total amount ever withdrawn by the depositor
     * ).
     * @param depositorAddress The depositor address
     * @return pendingRewards The current amount available for withdrawal by the depositor,
     * @return collectedRewards The total amount ever withdrawn by the depositor
     * )
     */
    function pendingReward(address depositorAddress) external view returns (uint256 pendingRewards, uint256 collectedRewards);

    /**
     * @notice Allow a depositor ({msg.sender}) to collect their tip rewards from the pool.
     * @dev Calls {_collectReward}.
     * Emits an {ValidatorRewardCollected} event.
     * Reverts if the pool is not open for withdrawals (Pool is not open for withdrawal right now).
     * @param beneficiary The address that the `amountRequested` will be sent to. If not set, send to {msg.sender}.
     * @param amountRequested The amount that will be sent to the `beneficiary`. If 0, send all pending rewards.
     */
    function collectReward(address payable beneficiary, uint256 amountRequested) external;

    /**
     * @notice The count of all validators in the pool
     * @dev Returns (
     * uint256 validatorCount: the count of all validators in the pool
     * )
     * @return validatorCount The count of all validators in the pool
     */
    function totalValidators() external view returns (uint256 validatorCount);

    /**
     * @notice A summary of the pool's current state
     * @dev Returns (
     * uint256 lastCachedUpdateTime: The timestamp when `totalValidatorUptime` was last updated,
     * uint256 totalValidatorUptime: The pool's total uptime,
     * uint256 validatorCount: The count of all validators in the pool,
     * uint256 lifetimeCollectedCommission: The amount of commissions ever collected from the pool,
     * uint256 lifetimePaidUserRewards: The amount of user rewards ever withdrawn the pool
     * )
     * @return (
     * uint256 lastCachedUpdateTime: The timestamp when `totalValidatorUptime` was last updated,
     * uint256 totalValidatorUptime: The pool's total uptime,
     * uint256 validatorCount: The count of all validators in the pool,
     * uint256 lifetimeCollectedCommission: The amount of commissions ever collected from the pool,
     * uint256 lifetimePaidUserRewards: The amount of user rewards ever withdrawn the pool
     * )
     */
    function getPoolState() external view returns (uint256, uint256, uint256, uint256, uint256);

    /**
     * @notice A summary of the depositor's activity in the pool
     * @dev Returns (
     * uint256 validatorCount: The count of all validators owned by the depositor,
     * uint256 totalStartTimestamps: The sum of all validator joinTime's owned by the depositor,
     * uint256 partedUptime: The uptime from all parted validators owned by the depositor,
     * uint256 collectedReward: The total of all collected rewards ever collected by the depositor
     * )
     * @param user A depositor address
     * @return (
     * uint256 validatorCount: The count of all validators owned by the depositor,
     * uint256 totalStartTimestamps: The sum of all validator joinTime's owned by the depositor,
     * uint256 partedUptime: The uptime from all parted validators owned by the depositor,
     * uint256 collectedReward: The total of all collected rewards ever collected by the depositor
     * )
     */
    function getUserState(address user) external view returns (uint256, uint256, uint256, uint256);
    receive() external payable;
}