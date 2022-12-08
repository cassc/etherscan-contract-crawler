// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

/**
 * IStakefishTransactionFeePoolV3
 * This contract collects transaction fees from a pool of validators, and shares the income with their delegators (depositors).
 * Important notes compared to V2:
 * - The ability to retroactively specify join and part pool time is no longer present.
 * - joinPool and partPool no longer take timestamps--they are effective as of the transaction.
 * - We no longer emit bulkJoinPool and bulkPartPool events.
 */
interface IStakefishTransactionFeePoolV3 {
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
     * Emits an {ValidatorJoined} event.
     * Requirements:
     * `validatorPubkey` cannot double join (Validator already in pool).
     * `depositorAddress` is not nullable (depositorAddress must be set).
     * @param validatorPubKey The validator's public key
     * @param depositorAddress The delegator that is associated with the validator
     */
    function joinPool(bytes calldata validatorPubKey, address depositorAddress, uint256 unused) external;

    /**
     * @notice Remove a validator from the pool
     * @dev operatorOnly.
     * Emits an {ValidatorParted} event.
     * Requirements:
     * `validatorPubKey` must be in the pool (Validator not in pool).
     * @param validatorPubKey The validator's public key
     */
    function partPool(bytes calldata validatorPubKey, uint256 unused) external;

    /**
     * @notice Add many validators to the pool
     * @dev operatorOnly.
     * @param validatorPubKeys The list of validator public keys to add (must be a multiple of 48)
     * @param depositorAddresses The depositor addresses to associate with the validators.
     */
    function bulkJoinPool(bytes calldata validatorPubKeys, address[] calldata depositorAddresses, uint256 unused) external;

    /**
     * @notice Remove many validators from the pool
     * @dev operatorOnly.
     * @param validatorPubKeys The list of validator public keys to remove (must be a multiple of 48)
     */
    function bulkPartPool(bytes calldata validatorPubKeys, uint256 unused) external;

    // Admin Only

    /**
     * @notice Set the contract commission rate
     * @dev adminOnly.
     * Emits an {CommissionRateChanged} event.
     * @param commissionRate The new commission rate
     */
    function setCommissionRate(uint256 commissionRate) external;

    /**
     * @notice Collect new commission fees up to `amountRequested`.
     * @dev adminOnly.
     * Emits an {CommissionCollected} event.
     * Requirements:
     * `amountRequested` cannot be greater than the available balance (Not enough pending commission).
     * @param beneficiary The address that the `amountRequested` will be sent to
     * @param amountRequested The amount that will be sent to the `beneficiary`. If 0, collect all fees.
     */
    function collectPoolCommission(address payable beneficiary, uint256 amountRequested) external;

    /**
     * @notice Change the contract operator
     * @dev adminOnly.
     * Emits an {OperatorChanged} event.
     * Requirements:
     * `newOperator` is not nullable ().
     * @param newOperator The new operator
     */
    function changeOperator(address newOperator) external;

    /**
     * @notice Temporarily disable reward collection during a contract maintenance window
     * @dev adminOnly.
     * Requirements:
     * `isOpenForWithdrawal` must be true (Pool is already closed for withdrawal).
     */
    function closePoolForWithdrawal() external;

    /**
     * @notice Enable reward collection after a temporary contract maintenance window
     * @dev adminOnly.
     * Requirements:
     * `isOpenForWithdrawal` must be false (Pool is already open for withdrawal).
     */
    function openPoolForWithdrawal() external;

    /**
     * @notice Transfer one or more validators to new fee pool owners.
     * @dev adminOnly.
     * Emits many {ValidatorParted}, {ValidatorJoined} and {ValidatorTransferred} events.
     * Requirements:
     * `validatorPubKeys`.length must equal `toAddresses`.length * 48 (validatorPubKeys byte array length incorrect).
     * Every `validatorPubKey` must be in the pool (Validator not in pool).
     * No `toAddress` is nullable (to address must be set to nonzero).
     * No `toAddress` can be equal to the validator's depositor (cannot transfer validator owner to oneself).
     * `transferTimestamp` must be before every validator's `joinTime` (Validator transferTimestamp is before join pool time).
     * `transferTimestamp` must not be in the future (Validator transferTimestamp is in the future).
     * @param validatorPubKeys The list of validators that will be transferred
     * @param toAddresses The list of addresses that the validators will be transferred to
     */
    function transferValidatorByAdmin(bytes calldata validatorPubKeys, address[] calldata toAddresses) external;

    /**
     * @notice Transfer historical claim amounts into this contract
     * @dev adminOnly (used during contract migration) (not idempotent!)
     * @param addresses The list of depositor addresses that collected
     * @param claimedAmounts The total amount collected by each depositor
     */
    function transferClaimHistory(address[] calldata addresses, uint256[] calldata claimedAmounts) external;

    /**
     * @notice Admin function to help users recover funds from a lost or stolen wallet
     * @dev adminOnly.
     * Emits an {ValidatorRewardCollected} event.
     * Requirements:
     * `beneficiaries`.length must equal 1 or `depositorAddresses`.length (beneficiaries length incorrect).
     * The pool must be open for withdrawals (Pool is not open for withdrawal right now).
     * `amountRequested` cannot be greater than the available balance (Not enough pending rewards).
     * @param depositorAddresses The list of depositors to withdraw rewards from
     * @param beneficiaries The list of addresses that will be sent the depositors' rewards
     * @param amountRequested The max amount to be withdrawn. If 0, all depositors' pending rewards will be withdrawn.
     */
    function emergencyWithdraw(address[] calldata depositorAddresses, address[] calldata beneficiaries, uint256 amountRequested) external;


    /**
     * @notice Admin function to transfer excess balance into a cold wallet for safekeeping.
     * @dev adminOnly.
     * @param wallet the cold wallet to transfer to
     * @param amount the amount to transfer
     */
    function saveToColdWallet(address wallet, uint256 amount) external;

    /**
     * @notice Admin function to transfer balance back from a cold wallet. Please do not send value from the cold
     * wallet directly into this contract. This function needs to do accounting to track the transferred balance.
     * @dev adminOnly.
     */
    function loadFromColdWallet() external payable;

    // Public

    /**
     * @notice The amount of rewards a depositor can withdraw, and all rewards they have ever withdrawn
     * @dev Reverts if `depositorAddress` is not set (depositorAddress must be set).
     * @param depositorAddress The depositor address
     * @return pendingRewards The current amount available for withdrawal by the depositor
     * @return collectedRewards The total amount ever withdrawn by the depositor
     */
    function pendingReward(address depositorAddress) external view returns (
        uint256 pendingRewards,
        uint256 collectedRewards
    );

    /**
     * @notice Allow a depositor (`msg.sender`) to collect their tip rewards from the pool.
     * @dev Emits an {ValidatorRewardCollected} event.
     * Requirements:
     * The pool must be open for withdrawals (Pool is not open for withdrawal right now).
     * `amountRequested` cannot be greater than the available balance (Not enough pending rewards).
     * @param beneficiary The address that the `amountRequested` will be sent to. If not set, send to `msg.sender`.
     * @param amountRequested The amount that will be sent to the `beneficiary`. If 0, send all pending rewards.
     */
    function collectReward(address payable beneficiary, uint256 amountRequested) external;

    /**
     * @notice The count of all validators in the pool
     * @return validatorCount_ The count of all validators in the pool
     */
    function totalValidators() external view returns (
        uint256 validatorCount_
    );

    /**
     * @notice A summary of the pool's current state
     */
    function getPoolState() external view returns (
        uint256 lastRewardUpdateBlock,
        uint256 accRewardPerValidator,
        uint256 validatorCount,
        uint256 lifetimeCollectedCommission,
        uint256 lifetimePaidUserRewards,
        uint256 amountInColdWallet,
        bool isPoolOpenForWithdrawal
    );

    /**
     * @notice A summary of the depositor's activity in the pool
     * @param user The depositor's address
     */
    function getUserState(address user) external view returns (
        uint256 validatorCount,
        uint256 lifetimeCredit,
        uint256 debit,
        uint256 collectedReward
    );
}