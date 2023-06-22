// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface IDIVAOracleTellor {
    // Thrown in the internal `_claimReward` function used in `claimReward`, 
    // `setFinalReferenceValue` and their respective batch versions if
    // rewards are claimed before a pool was confirmed.
    error NotConfirmedPool();

    // Thrown in `addTip` if user tries to add a tip for an already confirmed
    // pool.
    error AlreadyConfirmedPool();

    // Thrown in `addTip` if the tipping token implements a fee
    error FeeTokensNotSupported();

    // Thrown in `updateExcessDIVARewardRecipient` or constructor if the zero address
    // is passed as excess DIVA reward recipient address.
    error ZeroExcessDIVARewardRecipient();

    // Thrown in `setFinalReferenceValue` if there is no data reported after
    // the expiry time for the specified pool.
    error NoOracleSubmissionAfterExpiryTime();

    // Thrown in `setFinalReferenceValue` if user tries to call the function
    // before the minimum period undisputed period has passed.
    error MinPeriodUndisputedNotPassed();

    // Thrown in constructor if zero address is provided as ownershipContract.
    error ZeroOwnershipContractAddress();

    // Thrown in constructor if zero address is provided for DIVA Protocol contract.
    error ZeroDIVAAddress();

    // Thrown in governance related functions including `updateExcessDIVARewardRecipient`
    // `updateMaxDIVARewardUSD`, `revokePendingExcessDIVARewardRecipientUpdate`,
    // and `revokePendingMaxDIVARewardUSDUpdate` and `msg.sender` is not contract owner.
    error NotContractOwner(address _user, address _contractOwner);

    // Thrown in `updateExcessDIVARewardRecipient` if there is already a pending
    // excess DIVA reward recipient address update.
    error PendingExcessDIVARewardRecipientUpdate(
        uint256 _timestampBlock,
        uint256 _startTimeExcessDIVARewardRecipient
    );

    // Thrown in `updateMaxDIVARewardUSD` if there is already a pending max USD
    // DIVA reward update.
    error PendingMaxDIVARewardUSDUpdate(
        uint256 _timestampBlock,
        uint256 _startTimeMaxDIVARewardUSD
    );

    // Thrown in `revokePendingExcessDIVARewardRecipientUpdate` if the excess DIVA reward
    // recipient update to be revoked is already active.
    error ExcessDIVARewardRecipientAlreadyActive(
        uint256 _timestampBlock,
        uint256 _startTimeExcessDIVARewardRecipient
    );

    // Thrown in `revokePendingMaxDIVARewardUSDUpdate` if the max USD DIVA reward
    // update to be revoked is already active.
    error MaxDIVARewardUSDAlreadyActive(
        uint256 _timestampBlock,
        uint256 _startTimeMaxDIVARewardUSD
    );

    /**
     * @notice Emitted when the final reference value is set via the
     * `setFinalReferenceValue` function.
     * @param poolId The Id of the pool.
     * @param finalValue Tellor value expressed as an integer with 18 decimals.
     * @param expiryTime Pool expiry time as a unix timestamp in seconds.
     * @param timestamp Tellor value timestamp.
     */
    event FinalReferenceValueSet(
        bytes32 indexed poolId,
        uint256 finalValue,
        uint256 expiryTime,
        uint256 timestamp
    );

    /**
     * @notice Emitted when a tip is added via the `addTip` function.
     * @param poolId The Id of the tipped pool.
     * @param tippingToken Tipping token address.
     * @param amount Tipping token amount expressed as an integer with
     * tipping token decimals.
     * @param tipper Tipper address.
     */
    event TipAdded(
        bytes32 poolId,
        address tippingToken,
        uint256 amount,
        address tipper
    );

    /**
     * @notice Emitted when the reward is claimed via the in `claimReward`
     * function.
     * @param poolId The Id of the pool.
     * @param recipient Address of the tip recipient.
     * @param tippingToken Tipping token address.
     * @param amount Claimed amount expressed as an integer with tipping
     * token decimals.
     */
    event TipClaimed(
        bytes32 poolId,
        address recipient,
        address tippingToken,
        uint256 amount
    );

    /**
     * @notice Emitted when the excess DIVA reward recipient is updated via
     * the `updateExcessDIVARewardRecipient` function.
     * @param from Address that initiated the change (contract owner).
     * @param excessDIVARewardRecipient New excess DIVA reward recipient address.
     * @param startTimeExcessDIVARewardRecipient Timestamp in seconds since epoch at
     * which the new excess DIVA reward recipient will be activated.
     */
    event ExcessDIVARewardRecipientUpdated(
        address indexed from,
        address indexed excessDIVARewardRecipient,
        uint256 startTimeExcessDIVARewardRecipient
    );

    /**
     * @notice Emitted when the max USD DIVA reward is updated via the
     * `updateMaxDIVARewardUSD` function.
     * @param from Address that initiated the change (contract owner).
     * @param maxDIVARewardUSD New max USD DIVA reward expressed as an
     * integer with 18 decimals.
     * @param startTimeMaxDIVARewardUSD Timestamp in seconds since epoch at
     * which the new max USD DIVA reward will be activated.
     */
    event MaxDIVARewardUSDUpdated(
        address indexed from,
        uint256 maxDIVARewardUSD,
        uint256 startTimeMaxDIVARewardUSD
    );

    /**
     * @notice Emitted when a pending excess DIVA reward recipient update is revoked
     * via the `revokePendingExcessDIVARewardRecipientUpdate` function.
     * @param revokedBy Address that initiated the revocation.
     * @param revokedExcessDIVARewardRecipient Pending excess DIVA reward recipient that was
     * revoked.
     * @param restoredExcessDIVARewardRecipient Previous excess DIVA reward recipient that was
     * restored.
     */
    event PendingExcessDIVARewardRecipientUpdateRevoked(
        address indexed revokedBy,
        address indexed revokedExcessDIVARewardRecipient,
        address indexed restoredExcessDIVARewardRecipient
    );

    /**
     * @notice Emitted when a pending max USD DIVA reward update is revoked
     * via the `revokePendingMaxDIVARewardUSDUpdate` function.
     * @param revokedBy Address that initiated the revocation.
     * @param revokedMaxDIVARewardUSD Pending max USD DIVA reward that was
     * revoked.
     * @param restoredMaxDIVARewardUSD Previous max USD DIVA reward that was
     * restored.
     */
    event PendingMaxDIVARewardUSDUpdateRevoked(
        address indexed revokedBy,
        uint256 revokedMaxDIVARewardUSD,
        uint256 restoredMaxDIVARewardUSD
    );

    // Struct for `batchSetFinalReferenceValue` function input.
    struct ArgsBatchSetFinalReferenceValue {
        bytes32 poolId;
        address[] tippingTokens;
        bool claimDIVAReward;
    }

    // Struct for `batchAddTip` function input.
    struct ArgsBatchAddTip {
        bytes32 poolId;
        uint256 amount;
        address tippingToken;
    }
    
    // Struct for `batchClaimReward` function input.
    struct ArgsBatchClaimReward {
        bytes32 poolId;
        address[] tippingTokens;
        bool claimDIVAReward;
    }

    // Struct for `getTippingTokens` function input.
    struct ArgsGetTippingTokens {
        bytes32 poolId;
        uint256 startIndex;
        uint256 endIndex;
    }

    // Struct for `getTipAmounts` function input.
    struct ArgsGetTipAmounts {
        bytes32 poolId;
        address[] tippingTokens;
    }

    // Struct for `getPoolIdsForReporters` function input.
    struct ArgsGetPoolIdsForReporters {
        address reporter;
        uint256 startIndex;
        uint256 endIndex;
    }

    /**
     * @notice Function to set the final reference value for a given `_poolId`.
     * The first value that was submitted to the Tellor contract after the pool
     * expiration and remained undisputed for at least 12 hours will be passed
     * on to the DIVA smart contract for settlement.
     * @dev Function must be triggered within the submission window of the pool.
     * @param _poolId The Id of the pool.
     * @param _tippingTokens Array of tipping tokens to claim.
     * @param _claimDIVAReward Flag indicating whether to claim the DIVA reward.
     */
    function setFinalReferenceValue(
        bytes32 _poolId,
        address[] calldata _tippingTokens,
        bool _claimDIVAReward
    ) external;

    /**
     * @notice Batch version of `setFinalReferenceValue`.
     * @param _argsBatchSetFinalReferenceValue List containing poolIds, tipping
     * tokens, and `claimDIVAReward` flag.
     */
    function batchSetFinalReferenceValue(
        ArgsBatchSetFinalReferenceValue[] calldata _argsBatchSetFinalReferenceValue
    ) external;

    /**
     * @notice Function to tip a pool. Tips can be added in any
     * ERC20 token until the final value has been submitted and
     * confirmed in DIVA Protocol by successfully calling the
     * `setFinalReferenceValue` function. Tips can e claimed via the
     * `claimReward` function after final value confirmation.
     * @dev Function will revert if `msg.sender` has insufficient
     * allowance.
     * @param _poolId The Id of the pool.
     * @param _amount The amount to tip expressed as an integer
     * with tipping token decimals.
     * @param _tippingToken Tipping token address.
     */
    function addTip(
        bytes32 _poolId,
        uint256 _amount,
        address _tippingToken
    ) external;

    /**
     * @notice Batch version of `addTip`.
     * @param _argsBatchAddTip List containing poolIds, amounts
     * and tipping tokens.
     */
    function batchAddTip(
        ArgsBatchAddTip[] calldata _argsBatchAddTip
    ) external;

    /**
     * @notice Function to claim tips and/or DIVA reward.
     * @dev Claiming rewards is only possible after the final value has been
     * submitted and confirmed in DIVA Protocol by successfully calling
     * the `setFinalReferenceValue` function. Anyone can trigger this
     * function to transfer the rewards to the eligible reporter.
     * 
     * If no tipping tokens are provided and `_claimDIVAReward` is
     * set to `false`, the function will not execute anything, but will
     * not revert.
     * @param _poolId The Id of the pool.
     * @param _tippingTokens Array of tipping tokens to claim.
     * @param _claimDIVAReward Flag indicating whether to claim the
     * DIVA reward.
     */
    function claimReward(
        bytes32 _poolId,
        address[] memory _tippingTokens,
        bool _claimDIVAReward
    ) external;

    /**
     * @notice Batch version of `claimReward`.
     * @param _argsBatchClaimReward List containing poolIds, tipping
     * tokens, and `claimDIVAReward` flag.
     */
    function batchClaimReward(
        ArgsBatchClaimReward[] calldata _argsBatchClaimReward
    ) external;

    /**
     * @notice Function to update the excess DIVA reward recipient address.
     * @dev Activation is restricted to the contract owner and subject
     * to a 3-day delay.
     *
     * Reverts if:
     * - `msg.sender` is not contract owner.
     * - provided address equals zero address.
     * - there is already a pending excess DIVA reward recipient address update.
     * @param _newExcessDIVARewardRecipient New excess DIVA reward recipient address.
     */
    function updateExcessDIVARewardRecipient(address _newExcessDIVARewardRecipient) external;

    /**
     * @notice Function to update the maximum amount of DIVA reward that
     * a reporter can receive, denominated in USD.
     * @dev Activation is restricted to the contract owner and subject
     * to a 3-day delay.
     *
     * Reverts if:
     * - `msg.sender` is not contract owner.
     * - there is already a pending amount update.
     * @param _newMaxDIVARewardUSD New amount expressed as an integer with
     * 18 decimals.
     */
    function updateMaxDIVARewardUSD(uint256 _newMaxDIVARewardUSD) external;

    /**
     * @notice Function to revoke a pending excess DIVA reward recipient update
     * and restore the previous one.
     * @dev Reverts if:
     * - `msg.sender` is not contract owner.
     * - new excess DIVA reward recipient is already active.
     */
    function revokePendingExcessDIVARewardRecipientUpdate() external;

    /**
     * @notice Function to revoke a pending max USD DIVA reward update
     * and restore the previous one. Only callable by contract owner.
     * @dev Reverts if:
     * - `msg.sender` is not contract owner.
     * - new amount is already active.
     */
    function revokePendingMaxDIVARewardUSDUpdate() external;

    /**
     * @notice Function to return whether the Tellor adapter's data feed
     * is challengeable inside DIVA Protocol.
     * @dev In this implementation, the function always returns `false`,
     * which means that the first value submitted to DIVA Protocol
     * will determine the payouts, and users can start claiming their
     * payouts thereafter.
     */
    function getChallengeable() external pure returns (bool);

    /**
     * @notice Function to return the excess DIVA reward recipient info, including
     * the last update, its activation time and the previous value.
     * @dev The initial excess DIVA reward recipient is set when the contract is deployed.
     * The previous excess DIVA reward recipient is set to the zero address initially.
     * @return previousExcessDIVARewardRecipient Previous excess DIVA reward recipient address.
     * @return excessDIVARewardRecipient Latest update of the excess DIVA reward recipient address.
     * @return startTimeExcessDIVARewardRecipient Timestamp in seconds since epoch at which
     * `excessDIVARewardRecipient` is activated.
     */
    function getExcessDIVARewardRecipientInfo()
        external
        view
        returns (
            address previousExcessDIVARewardRecipient,
            address excessDIVARewardRecipient,
            uint256 startTimeExcessDIVARewardRecipient
        );

    /**
     * @notice Function to return the max USD DIVA reward info, including
     * the last update, its activation time and the previous value.
     * @dev The initial value is set when the contract is deployed.
     * The previous value is set to zero initially.
     * @return previousMaxDIVARewardUSD Previous value.
     * @return maxDIVARewardUSD Latest update of the value.
     * @return startTimeMaxDIVARewardUSD Timestamp in seconds since epoch at which
     * `maxDIVARewardUSD` is activated.
     */
    function getMaxDIVARewardUSDInfo()
        external
        view
        returns (
            uint256 previousMaxDIVARewardUSD,
            uint256 maxDIVARewardUSD,
            uint256 startTimeMaxDIVARewardUSD
        );

    /**
     * @notice Function to return the minimum period (in seconds) a reported
     * value has to remain undisputed in order to be considered valid.
     * Hard-coded to 12 hours (= 43'200 seconds) in this implementation.
     */
    function getMinPeriodUndisputed() external pure returns (uint32);

    /**
     * @notice Function to return the number of tipping tokens for a given
     * set of poolIds.
     * @param _poolIds Array of poolIds.
     */
    function getTippingTokensLengthForPoolIds(bytes32[] calldata _poolIds)
        external
        view
        returns (uint256[] memory);

    /**
     * @notice Function to return an array of tipping tokens for the given struct
     * array of poolIds, along with start and end indices to manage the return
     * size of the array.
     * @param _argsGetTippingTokens List containing poolId,
     * start index and end index.
     */
    function getTippingTokens(
        ArgsGetTippingTokens[] calldata _argsGetTippingTokens
    ) external view returns (address[][] memory);

    /**
     * @notice Function to return the tipping amounts for a given set of poolIds
     * and tipping tokens.
     * @param _argsGetTipAmounts List containing poolIds and tipping
     * tokens.
     */
    function getTipAmounts(ArgsGetTipAmounts[] calldata _argsGetTipAmounts)
        external
        view
        returns (uint256[][] memory);

    /**
     * @notice Function to return the list of reporter addresses that are entitled
     * to receive rewards for a given list of poolIds.
     * @dev If a value has been reported to the Tellor contract but hasn't been 
     * pulled into the DIVA contract via the `setFinalReferenceValue` function yet,
     * the function returns the zero address.
     * @param _poolIds Array of poolIds.
     */
    function getReporters(bytes32[] calldata _poolIds)
        external
        view
        returns (address[] memory);

    /**
     * @notice Function to return the number of poolIds that a given list of
     * reporter addresses are eligible to claim rewards for.
     * @param _reporters List of reporter addresses.
     */
    function getPoolIdsLengthForReporters(address[] calldata _reporters)
        external
        view
        returns (uint256[] memory);

    /**
     * @notice Function to return a list of poolIds that a given list of reporters
     * is eligible to claim rewards for.
     * @dev It takes a list of reporter addresses, as well as the start and end
     * indices as input to manage the return size of the array.
     * @param _argsGetPoolIdsForReporters List containing reporter
     * address, start index and end index.
     */
    function getPoolIdsForReporters(
        ArgsGetPoolIdsForReporters[] calldata _argsGetPoolIdsForReporters
    ) external view returns (bytes32[][] memory);

    /**
     * @notice Function to return the DIVA contract address that the
     * Tellor adapter is linked to.
     * @dev The address is set at contract deployment and cannot be modified.
     */
    function getDIVAAddress() external view returns (address);

    /**
     * @notice Returns the DIVA ownership contract address that stores
     * the contract owner.
     * @dev The owner can be obtained by calling the `getOwner` function
     * at the returned contract address.
     */
    function getOwnershipContract() external view returns (address);

    /**
     * @notice Returns the activation delay (in seconds) for governance
     * related updates. Hard-coded to 3 days (= 259'200 seconds).
     */
    function getActivationDelay() external pure returns (uint256);

    /**
     * @notice Function to return the query data and Id for a given poolId
     * which are required for reporting values via Tellor's `submitValue`
     * function.
     * @param _poolId The Id of the pool.
     */
    function getQueryDataAndId(
        bytes32 _poolId
    ) external view returns (bytes memory, bytes32);
}