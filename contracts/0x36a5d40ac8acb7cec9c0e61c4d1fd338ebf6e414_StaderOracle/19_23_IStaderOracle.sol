// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import '../library/ValidatorStatus.sol';

import './ISocializingPool.sol';
import './IStaderConfig.sol';

struct SDPriceData {
    uint256 reportingBlockNumber;
    uint256 sdPriceInETH;
}

/// @title MissedAttestationPenaltyData
/// @notice This struct holds missed attestation penalty data
struct MissedAttestationPenaltyData {
    /// @notice The block number when the missed attestation penalty data is reported
    uint256 reportingBlockNumber;
    /// @notice The index of missed attestation penalty data
    uint256 index;
    /// @notice missed attestation validator pubkeys
    bytes[] sortedPubkeys;
}

struct MissedAttestationReportInfo {
    uint256 index;
    uint256 pageNumber;
}

/// @title ExchangeRate
/// @notice This struct holds data related to the exchange rate between ETH and ETHX.
struct ExchangeRate {
    /// @notice The block number when the exchange rate was last updated.
    uint256 reportingBlockNumber;
    /// @notice The total balance of Ether (ETH) in the system.
    uint256 totalETHBalance;
    /// @notice The total supply of the liquid staking token (ETHX) in the system.
    uint256 totalETHXSupply;
}

/// @title ValidatorStats
/// @notice This struct holds statistics related to validators in the beaconchain.
struct ValidatorStats {
    /// @notice The block number when the validator stats was last updated.
    uint256 reportingBlockNumber;
    /// @notice The total balance of all exiting validators.
    uint128 exitingValidatorsBalance;
    /// @notice The total balance of all exited validators.
    uint128 exitedValidatorsBalance;
    /// @notice The total balance of all slashed validators.
    uint128 slashedValidatorsBalance;
    /// @notice The number of currently exiting validators.
    uint32 exitingValidatorsCount;
    /// @notice The number of validators that have exited.
    uint32 exitedValidatorsCount;
    /// @notice The number of validators that have been slashed.
    uint32 slashedValidatorsCount;
}

struct WithdrawnValidators {
    uint8 poolId;
    uint256 reportingBlockNumber;
    bytes[] sortedPubkeys;
}

struct ValidatorVerificationDetail {
    uint8 poolId;
    uint256 reportingBlockNumber;
    bytes[] sortedReadyToDepositPubkeys;
    bytes[] sortedFrontRunPubkeys;
    bytes[] sortedInvalidSignaturePubkeys;
}

interface IStaderOracle {
    // Error
    error InvalidUpdate();
    error NodeAlreadyTrusted();
    error NodeNotTrusted();
    error ZeroFrequency();
    error FrequencyUnchanged();
    error DuplicateSubmissionFromNode();
    error ReportingFutureBlockData();
    error InvalidMerkleRootIndex();
    error ReportingPreviousCycleData();
    error InvalidMAPDIndex();
    error PageNumberAlreadyReported();
    error NotATrustedNode();
    error InvalidERDataSource();
    error InspectionModeActive();
    error UpdateFrequencyNotSet();
    error InvalidReportingBlock();
    error ERChangeLimitCrossed();
    error ERChangeLimitNotCrossed();
    error ERPermissibleChangeOutofBounds();
    error InsufficientTrustedNodes();
    error CooldownNotComplete();

    // Events
    event ERDataSourceToggled(bool isPORBasedERData);
    event UpdatedERChangeLimit(uint256 erChangeLimit);
    event ERInspectionModeActivated(bool erInspectionMode, uint256 time);
    event ExchangeRateSubmitted(
        address indexed from,
        uint256 block,
        uint256 totalEth,
        uint256 ethxSupply,
        uint256 time
    );
    event ExchangeRateUpdated(uint256 block, uint256 totalEth, uint256 ethxSupply, uint256 time);
    event TrustedNodeAdded(address indexed node);
    event TrustedNodeRemoved(address indexed node);
    event SocializingRewardsMerkleRootSubmitted(
        address indexed node,
        uint256 index,
        bytes32 merkleRoot,
        uint8 poolId,
        uint256 block
    );
    event SocializingRewardsMerkleRootUpdated(uint256 index, bytes32 merkleRoot, uint8 poolId, uint256 block);
    event SDPriceSubmitted(address indexed node, uint256 sdPriceInETH, uint256 reportedBlock, uint256 block);
    event SDPriceUpdated(uint256 sdPriceInETH, uint256 reportedBlock, uint256 block);

    event MissedAttestationPenaltySubmitted(
        address indexed node,
        uint256 index,
        uint256 block,
        uint256 reportingBlockNumber,
        bytes[] pubkeys
    );
    event MissedAttestationPenaltyUpdated(uint256 index, uint256 block, bytes[] pubkeys);
    event UpdateFrequencyUpdated(uint256 updateFrequency);
    event ValidatorStatsSubmitted(
        address indexed from,
        uint256 block,
        uint256 activeValidatorsBalance,
        uint256 exitedValidatorsBalance,
        uint256 slashedValidatorsBalance,
        uint256 activeValidatorsCount,
        uint256 exitedValidatorsCount,
        uint256 slashedValidatorsCount,
        uint256 time
    );
    event ValidatorStatsUpdated(
        uint256 block,
        uint256 activeValidatorsBalance,
        uint256 exitedValidatorsBalance,
        uint256 slashedValidatorsBalance,
        uint256 activeValidatorsCount,
        uint256 exitedValidatorsCount,
        uint256 slashedValidatorsCount,
        uint256 time
    );
    event WithdrawnValidatorsSubmitted(
        address indexed from,
        uint8 poolId,
        uint256 block,
        bytes[] pubkeys,
        uint256 time
    );
    event WithdrawnValidatorsUpdated(uint8 poolId, uint256 block, bytes[] pubkeys, uint256 time);
    event ValidatorVerificationDetailSubmitted(
        address indexed from,
        uint8 poolId,
        uint256 block,
        bytes[] sortedReadyToDepositPubkeys,
        bytes[] sortedFrontRunPubkeys,
        bytes[] sortedInvalidSignaturePubkeys,
        uint256 time
    );
    event ValidatorVerificationDetailUpdated(
        uint8 poolId,
        uint256 block,
        bytes[] sortedReadyToDepositPubkeys,
        bytes[] sortedFrontRunPubkeys,
        bytes[] sortedInvalidSignaturePubkeys,
        uint256 time
    );
    event SafeModeEnabled();
    event SafeModeDisabled();
    event UpdatedStaderConfig(address staderConfig);
    event TrustedNodeChangeCoolingPeriodUpdated(uint256 trustedNodeChangeCoolingPeriod);

    // methods

    function addTrustedNode(address _nodeAddress) external;

    function removeTrustedNode(address _nodeAddress) external;

    /**
     * @notice submit exchange rate data by trusted oracle nodes
    @dev Submits the given balances for a specified block number.
    @param _exchangeRate The exchange rate to submit.
    */
    function submitExchangeRateData(ExchangeRate calldata _exchangeRate) external;

    //update the exchange rate via POR Feed data
    function updateERFromPORFeed() external;

    //update exchange rate via POR Feed when ER change limit is crossed
    function closeERInspectionMode() external;

    function disableERInspectionMode() external;

    /**
    @notice Submits the root of the merkle tree containing the socializing rewards.
    sends user ETH Rewards to SSPM
    sends protocol ETH Rewards to stader treasury
    @param _rewardsData contains rewards merkleRoot and rewards split
    */
    function submitSocializingRewardsMerkleRoot(RewardsData calldata _rewardsData) external;

    function submitSDPrice(SDPriceData calldata _sdPriceData) external;

    /**
     * @notice Submit validator stats for a specific block.
     * @dev This function can only be called by trusted nodes.
     * @param _validatorStats The validator stats to submit.
     *
     * Function Flow:
     * 1. Validates that the submission is for a past block and not a future one.
     * 2. Validates that the submission is for a block higher than the last block number with updated counts.
     * 3. Generates submission keys using the input parameters.
     * 4. Validates that this is not a duplicate submission from the same node.
     * 5. Updates the submission count for the given counts.
     * 6. Emits a ValidatorCountsSubmitted event with the submitted data.
     * 7. If the submission count reaches a majority (trustedNodesCount / 2 + 1), checks whether the counts are not already updated,
     *    then updates the validator counts, and emits a CountsUpdated event.
     */
    function submitValidatorStats(ValidatorStats calldata _validatorStats) external;

    /// @notice Submit the withdrawn validators list to the oracle.
    /// @dev The function checks if the submitted data is for a valid and newer block,
    ///      and if the submission count reaches the required threshold, it updates the withdrawn validators list (NodeRegistry).
    /// @param _withdrawnValidators The withdrawn validators data, including blockNumber and sorted pubkeys.
    function submitWithdrawnValidators(WithdrawnValidators calldata _withdrawnValidators) external;

    /**
     * @notice submit the ready to deposit keys, front run keys and invalid signature keys
     * @dev The function checks if the submitted data is for a valid and newer block,
     *  and if the submission count reaches the required threshold, it updates the markValidatorReadyToDeposit (NodeRegistry).
     * @param _validatorVerificationDetail validator verification data, containing valid pubkeys, front run and invalid signature
     */
    function submitValidatorVerificationDetail(ValidatorVerificationDetail calldata _validatorVerificationDetail)
        external;

    /**
     * @notice store the missed attestation penalty strike on validator
     * @dev _missedAttestationPenaltyData.index should not be zero
     * @param _mapd missed attestation penalty data
     */
    function submitMissedAttestationPenalties(MissedAttestationPenaltyData calldata _mapd) external;

    // setters
    // enable the safeMode depending on network and protocol health
    function enableSafeMode() external;

    // disable safe mode
    function disableSafeMode() external;

    function updateStaderConfig(address _staderConfig) external;

    function setERUpdateFrequency(uint256 _updateFrequency) external;

    function setSDPriceUpdateFrequency(uint256 _updateFrequency) external;

    function setValidatorStatsUpdateFrequency(uint256 _updateFrequency) external;

    function setValidatorVerificationDetailUpdateFrequency(uint256 _updateFrequency) external;

    function setWithdrawnValidatorsUpdateFrequency(uint256 _updateFrequency) external;

    function setMissedAttestationPenaltyUpdateFrequency(uint256 _updateFrequency) external;

    function updateERChangeLimit(uint256 _erChangeLimit) external;

    function togglePORFeedBasedERData() external;

    // getters
    function trustedNodeChangeCoolingPeriod() external view returns (uint256);

    function lastTrustedNodeCountChangeBlock() external view returns (uint256);

    function erInspectionMode() external view returns (bool);

    function isPORFeedBasedERData() external view returns (bool);

    function staderConfig() external view returns (IStaderConfig);

    function erChangeLimit() external view returns (uint256);

    // returns the last reported block number of withdrawn validators for a poolId
    function lastReportingBlockNumberForWithdrawnValidatorsByPoolId(uint8) external view returns (uint256);

    // returns the last reported block number of validator verification detail for a poolId
    function lastReportingBlockNumberForValidatorVerificationDetailByPoolId(uint8) external view returns (uint256);

    // returns the count of trusted nodes
    function trustedNodesCount() external view returns (uint256);

    //returns the latest consensus index for missed attestation penalty data report
    function lastReportedMAPDIndex() external view returns (uint256);

    function erInspectionModeStartBlock() external view returns (uint256);

    function safeMode() external view returns (bool);

    function isTrustedNode(address) external view returns (bool);

    function missedAttestationPenalty(bytes32 _pubkey) external view returns (uint16);

    // The last updated merkle tree index
    function getCurrentRewardsIndexByPoolId(uint8 _poolId) external view returns (uint256);

    function getERReportableBlock() external view returns (uint256);

    function getMerkleRootReportableBlockByPoolId(uint8 _poolId) external view returns (uint256);

    function getSDPriceReportableBlock() external view returns (uint256);

    function getValidatorStatsReportableBlock() external view returns (uint256);

    function getWithdrawnValidatorReportableBlock() external view returns (uint256);

    function getValidatorVerificationDetailReportableBlock() external view returns (uint256);

    function getMissedAttestationPenaltyReportableBlock() external view returns (uint256);

    function getExchangeRate() external view returns (ExchangeRate memory);

    function getValidatorStats() external view returns (ValidatorStats memory);

    // returns price of 1 SD in ETH
    function getSDPriceInETH() external view returns (uint256);
}