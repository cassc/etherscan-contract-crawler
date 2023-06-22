// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import './library/UtilLib.sol';

import './interfaces/IPoolUtils.sol';
import './interfaces/IStaderOracle.sol';
import './interfaces/ISocializingPool.sol';
import './interfaces/INodeRegistry.sol';
import './interfaces/IStaderStakePoolManager.sol';

import '@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol';
import '@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol';

contract StaderOracle is IStaderOracle, AccessControlUpgradeable, PausableUpgradeable, ReentrancyGuardUpgradeable {
    bool public override erInspectionMode;
    bool public override isPORFeedBasedERData;
    SDPriceData public lastReportedSDPriceData;
    IStaderConfig public override staderConfig;
    ExchangeRate public inspectionModeExchangeRate;
    ExchangeRate public exchangeRate;
    ValidatorStats public validatorStats;

    uint256 public constant MAX_ER_UPDATE_FREQUENCY = 7200 * 7; // 7 days
    uint256 public constant ER_CHANGE_MAX_BPS = 10000;
    uint256 public override erChangeLimit;
    uint256 public constant MIN_TRUSTED_NODES = 5;
    uint256 public override trustedNodeChangeCoolingPeriod;

    /// @inheritdoc IStaderOracle
    uint256 public override trustedNodesCount;
    /// @inheritdoc IStaderOracle
    uint256 public override lastReportedMAPDIndex;
    uint256 public override erInspectionModeStartBlock;
    uint256 public override lastTrustedNodeCountChangeBlock;

    // indicate the health of protocol on beacon chain
    // enabled by `MANAGER` if heavy slashing on protocol on beacon chain
    bool public override safeMode;

    /// @inheritdoc IStaderOracle
    mapping(address => bool) public override isTrustedNode;
    mapping(bytes32 => bool) private nodeSubmissionKeys;
    mapping(bytes32 => uint8) private submissionCountKeys;
    mapping(bytes32 => uint16) public override missedAttestationPenalty;
    /// @inheritdoc IStaderOracle
    mapping(uint8 => uint256) public override lastReportingBlockNumberForWithdrawnValidatorsByPoolId;
    /// @inheritdoc IStaderOracle
    mapping(uint8 => uint256) public override lastReportingBlockNumberForValidatorVerificationDetailByPoolId;

    uint256[] private sdPrices;

    bytes32 public constant ETHX_ER_UF = keccak256('ETHX_ER_UF'); // ETHx Exchange Rate, Balances Update Frequency
    bytes32 public constant SD_PRICE_UF = keccak256('SD_PRICE_UF'); // SD Price Update Frequency Key
    bytes32 public constant VALIDATOR_STATS_UF = keccak256('VALIDATOR_STATS_UF'); // Validator Status Update Frequency Key
    bytes32 public constant WITHDRAWN_VALIDATORS_UF = keccak256('WITHDRAWN_VALIDATORS_UF'); // Withdrawn Validator Update Frequency Key
    bytes32 public constant MISSED_ATTESTATION_PENALTY_UF = keccak256('MISSED_ATTESTATION_PENALTY_UF'); // Missed Attestation Penalty Update Frequency Key
    // Ready to Deposit Validators Update Frequency Key
    bytes32 public constant VALIDATOR_VERIFICATION_DETAIL_UF = keccak256('VALIDATOR_VERIFICATION_DETAIL_UF');
    mapping(bytes32 => uint256) public updateFrequencyMap;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address _admin, address _staderConfig) external initializer {
        UtilLib.checkNonZeroAddress(_admin);
        UtilLib.checkNonZeroAddress(_staderConfig);

        __AccessControl_init();
        __Pausable_init();
        __ReentrancyGuard_init();
        erChangeLimit = 500; //5% deviation threshold
        setUpdateFrequency(ETHX_ER_UF, 7200);
        setUpdateFrequency(SD_PRICE_UF, 7200);
        setUpdateFrequency(VALIDATOR_STATS_UF, 7200);
        setUpdateFrequency(WITHDRAWN_VALIDATORS_UF, 14400);
        setUpdateFrequency(MISSED_ATTESTATION_PENALTY_UF, 50400);
        setUpdateFrequency(VALIDATOR_VERIFICATION_DETAIL_UF, 7200);
        staderConfig = IStaderConfig(_staderConfig);
        _grantRole(DEFAULT_ADMIN_ROLE, _admin);
        emit UpdatedStaderConfig(_staderConfig);
    }

    /// @inheritdoc IStaderOracle
    function addTrustedNode(address _nodeAddress) external override {
        UtilLib.onlyManagerRole(msg.sender, staderConfig);
        UtilLib.checkNonZeroAddress(_nodeAddress);
        if (isTrustedNode[_nodeAddress]) {
            revert NodeAlreadyTrusted();
        }
        if (block.number < lastTrustedNodeCountChangeBlock + trustedNodeChangeCoolingPeriod) {
            revert CooldownNotComplete();
        }
        lastTrustedNodeCountChangeBlock = block.number;

        isTrustedNode[_nodeAddress] = true;
        trustedNodesCount++;

        emit TrustedNodeAdded(_nodeAddress);
    }

    /// @inheritdoc IStaderOracle
    function removeTrustedNode(address _nodeAddress) external override {
        UtilLib.onlyManagerRole(msg.sender, staderConfig);
        UtilLib.checkNonZeroAddress(_nodeAddress);
        if (!isTrustedNode[_nodeAddress]) {
            revert NodeNotTrusted();
        }
        if (block.number < lastTrustedNodeCountChangeBlock + trustedNodeChangeCoolingPeriod) {
            revert CooldownNotComplete();
        }
        lastTrustedNodeCountChangeBlock = block.number;

        isTrustedNode[_nodeAddress] = false;
        trustedNodesCount--;

        emit TrustedNodeRemoved(_nodeAddress);
    }

    /// @inheritdoc IStaderOracle
    function submitExchangeRateData(ExchangeRate calldata _exchangeRate)
        external
        override
        trustedNodeOnly
        checkMinTrustedNodes
        checkERInspectionMode
        whenNotPaused
    {
        if (isPORFeedBasedERData) {
            revert InvalidERDataSource();
        }
        if (_exchangeRate.reportingBlockNumber >= block.number) {
            revert ReportingFutureBlockData();
        }
        if (_exchangeRate.reportingBlockNumber % updateFrequencyMap[ETHX_ER_UF] > 0) {
            revert InvalidReportingBlock();
        }

        // Get submission keys
        bytes32 nodeSubmissionKey = keccak256(
            abi.encode(
                msg.sender,
                _exchangeRate.reportingBlockNumber,
                _exchangeRate.totalETHBalance,
                _exchangeRate.totalETHXSupply
            )
        );
        bytes32 submissionCountKey = keccak256(
            abi.encode(_exchangeRate.reportingBlockNumber, _exchangeRate.totalETHBalance, _exchangeRate.totalETHXSupply)
        );
        uint8 submissionCount = attestSubmission(nodeSubmissionKey, submissionCountKey);
        // Emit balances submitted event
        emit ExchangeRateSubmitted(
            msg.sender,
            _exchangeRate.reportingBlockNumber,
            _exchangeRate.totalETHBalance,
            _exchangeRate.totalETHXSupply,
            block.timestamp
        );

        if (
            submissionCount >= trustedNodesCount / 2 + 1 &&
            _exchangeRate.reportingBlockNumber > exchangeRate.reportingBlockNumber
        ) {
            updateWithInLimitER(
                _exchangeRate.totalETHBalance,
                _exchangeRate.totalETHXSupply,
                _exchangeRate.reportingBlockNumber
            );
        }
    }

    /// @inheritdoc IStaderOracle
    function updateERFromPORFeed() external override checkERInspectionMode whenNotPaused {
        if (!isPORFeedBasedERData) {
            revert InvalidERDataSource();
        }
        (uint256 newTotalETHBalance, uint256 newTotalETHXSupply, uint256 reportingBlockNumber) = getPORFeedData();
        updateWithInLimitER(newTotalETHBalance, newTotalETHXSupply, reportingBlockNumber);
    }

    /**
     * @notice update the exchange rate when er change limit crossed, after verifying `inspectionModeExchangeRate` data
     * @dev `erInspectionMode` must be true to call this function
     */
    function closeERInspectionMode() external override whenNotPaused {
        if (!erInspectionMode) {
            revert ERChangeLimitNotCrossed();
        }
        disableERInspectionMode();
        _updateExchangeRate(
            inspectionModeExchangeRate.totalETHBalance,
            inspectionModeExchangeRate.totalETHXSupply,
            inspectionModeExchangeRate.reportingBlockNumber
        );
    }

    // turn off erInspectionMode if `inspectionModeExchangeRate` is incorrect so that oracle/POR can push new data
    function disableERInspectionMode() public override whenNotPaused {
        if (
            !staderConfig.onlyManagerRole(msg.sender) &&
            erInspectionModeStartBlock + MAX_ER_UPDATE_FREQUENCY > block.number
        ) {
            revert CooldownNotComplete();
        }
        erInspectionMode = false;
    }

    /// @notice submits merkle root and handles reward
    /// sends user rewards to Stader Stake Pool Manager
    /// sends protocol rewards to stader treasury
    /// updates operator reward balances on socializing pool
    /// @param _rewardsData contains rewards merkleRoot and rewards split info
    /// @dev _rewardsData.index should not be zero
    function submitSocializingRewardsMerkleRoot(RewardsData calldata _rewardsData)
        external
        override
        nonReentrant
        trustedNodeOnly
        checkMinTrustedNodes
        whenNotPaused
    {
        if (_rewardsData.reportingBlockNumber >= block.number) {
            revert ReportingFutureBlockData();
        }
        if (_rewardsData.reportingBlockNumber != getMerkleRootReportableBlockByPoolId(_rewardsData.poolId)) {
            revert InvalidReportingBlock();
        }
        if (_rewardsData.index != getCurrentRewardsIndexByPoolId(_rewardsData.poolId)) {
            revert InvalidMerkleRootIndex();
        }

        // Get submission keys
        bytes32 nodeSubmissionKey = keccak256(
            abi.encode(
                msg.sender,
                _rewardsData.index,
                _rewardsData.merkleRoot,
                _rewardsData.poolId,
                _rewardsData.operatorETHRewards,
                _rewardsData.userETHRewards,
                _rewardsData.protocolETHRewards,
                _rewardsData.operatorSDRewards
            )
        );
        bytes32 submissionCountKey = keccak256(
            abi.encode(
                _rewardsData.index,
                _rewardsData.merkleRoot,
                _rewardsData.poolId,
                _rewardsData.operatorETHRewards,
                _rewardsData.userETHRewards,
                _rewardsData.protocolETHRewards,
                _rewardsData.operatorSDRewards
            )
        );

        // Emit merkle root submitted event
        emit SocializingRewardsMerkleRootSubmitted(
            msg.sender,
            _rewardsData.index,
            _rewardsData.merkleRoot,
            _rewardsData.poolId,
            block.number
        );

        uint8 submissionCount = attestSubmission(nodeSubmissionKey, submissionCountKey);

        if ((submissionCount >= trustedNodesCount / 2 + 1)) {
            address socializingPool = IPoolUtils(staderConfig.getPoolUtils()).getSocializingPoolAddress(
                _rewardsData.poolId
            );
            ISocializingPool(socializingPool).handleRewards(_rewardsData);

            emit SocializingRewardsMerkleRootUpdated(
                _rewardsData.index,
                _rewardsData.merkleRoot,
                _rewardsData.poolId,
                block.number
            );
        }
    }

    function submitSDPrice(SDPriceData calldata _sdPriceData) external override trustedNodeOnly checkMinTrustedNodes {
        if (_sdPriceData.reportingBlockNumber >= block.number) {
            revert ReportingFutureBlockData();
        }
        if (_sdPriceData.reportingBlockNumber != getSDPriceReportableBlock()) {
            revert InvalidReportingBlock();
        }
        if (_sdPriceData.reportingBlockNumber <= lastReportedSDPriceData.reportingBlockNumber) {
            revert ReportingPreviousCycleData();
        }

        // Get submission keys
        bytes32 nodeSubmissionKey = keccak256(abi.encode(msg.sender, _sdPriceData.reportingBlockNumber));
        bytes32 submissionCountKey = keccak256(abi.encode(_sdPriceData.reportingBlockNumber));
        uint8 submissionCount = attestSubmission(nodeSubmissionKey, submissionCountKey);
        // clean the sd price array before the start of every round of submissions
        if (submissionCount == 1) {
            delete sdPrices;
        }
        insertSDPrice(_sdPriceData.sdPriceInETH);
        // Emit SD Price submitted event
        emit SDPriceSubmitted(msg.sender, _sdPriceData.sdPriceInETH, _sdPriceData.reportingBlockNumber, block.number);

        // price can be derived once more than 66% percent oracles have submitted price
        if ((submissionCount >= (2 * trustedNodesCount) / 3 + 1)) {
            lastReportedSDPriceData = _sdPriceData;
            lastReportedSDPriceData.sdPriceInETH = getMedianValue(sdPrices);

            // Emit SD Price updated event
            emit SDPriceUpdated(_sdPriceData.sdPriceInETH, _sdPriceData.reportingBlockNumber, block.number);
        }
    }

    function insertSDPrice(uint256 _sdPrice) internal {
        sdPrices.push(_sdPrice);
        if (sdPrices.length == 1) return;

        uint256 j = sdPrices.length - 1;
        while ((j >= 1) && (_sdPrice < sdPrices[j - 1])) {
            sdPrices[j] = sdPrices[j - 1];
            j--;
        }
        sdPrices[j] = _sdPrice;
    }

    function getMedianValue(uint256[] storage dataArray) internal view returns (uint256 _medianValue) {
        uint256 len = dataArray.length;
        return (dataArray[(len - 1) / 2] + dataArray[len / 2]) / 2;
    }

    /// @inheritdoc IStaderOracle
    function submitValidatorStats(ValidatorStats calldata _validatorStats)
        external
        override
        trustedNodeOnly
        checkMinTrustedNodes
        whenNotPaused
    {
        if (_validatorStats.reportingBlockNumber >= block.number) {
            revert ReportingFutureBlockData();
        }
        if (_validatorStats.reportingBlockNumber % updateFrequencyMap[VALIDATOR_STATS_UF] > 0) {
            revert InvalidReportingBlock();
        }

        // Get submission keys
        bytes32 nodeSubmissionKey = keccak256(
            abi.encode(
                msg.sender,
                _validatorStats.reportingBlockNumber,
                _validatorStats.exitingValidatorsBalance,
                _validatorStats.exitedValidatorsBalance,
                _validatorStats.slashedValidatorsBalance,
                _validatorStats.exitingValidatorsCount,
                _validatorStats.exitedValidatorsCount,
                _validatorStats.slashedValidatorsCount
            )
        );
        bytes32 submissionCountKey = keccak256(
            abi.encode(
                _validatorStats.reportingBlockNumber,
                _validatorStats.exitingValidatorsBalance,
                _validatorStats.exitedValidatorsBalance,
                _validatorStats.slashedValidatorsBalance,
                _validatorStats.exitingValidatorsCount,
                _validatorStats.exitedValidatorsCount,
                _validatorStats.slashedValidatorsCount
            )
        );

        uint8 submissionCount = attestSubmission(nodeSubmissionKey, submissionCountKey);
        // Emit validator stats submitted event
        emit ValidatorStatsSubmitted(
            msg.sender,
            _validatorStats.reportingBlockNumber,
            _validatorStats.exitingValidatorsBalance,
            _validatorStats.exitedValidatorsBalance,
            _validatorStats.slashedValidatorsBalance,
            _validatorStats.exitingValidatorsCount,
            _validatorStats.exitedValidatorsCount,
            _validatorStats.slashedValidatorsCount,
            block.timestamp
        );

        if (
            submissionCount >= trustedNodesCount / 2 + 1 &&
            _validatorStats.reportingBlockNumber > validatorStats.reportingBlockNumber
        ) {
            validatorStats = _validatorStats;

            // Emit stats updated event
            emit ValidatorStatsUpdated(
                _validatorStats.reportingBlockNumber,
                _validatorStats.exitingValidatorsBalance,
                _validatorStats.exitedValidatorsBalance,
                _validatorStats.slashedValidatorsBalance,
                _validatorStats.exitingValidatorsCount,
                _validatorStats.exitedValidatorsCount,
                _validatorStats.slashedValidatorsCount,
                block.timestamp
            );
        }
    }

    /// @inheritdoc IStaderOracle
    function submitWithdrawnValidators(WithdrawnValidators calldata _withdrawnValidators)
        external
        override
        nonReentrant
        trustedNodeOnly
        checkMinTrustedNodes
        whenNotPaused
    {
        if (_withdrawnValidators.reportingBlockNumber >= block.number) {
            revert ReportingFutureBlockData();
        }
        if (_withdrawnValidators.reportingBlockNumber % updateFrequencyMap[WITHDRAWN_VALIDATORS_UF] > 0) {
            revert InvalidReportingBlock();
        }

        bytes memory encodedPubkeys = abi.encode(_withdrawnValidators.sortedPubkeys);
        // Get submission keys
        bytes32 nodeSubmissionKey = keccak256(
            abi.encode(
                msg.sender,
                _withdrawnValidators.poolId,
                _withdrawnValidators.reportingBlockNumber,
                encodedPubkeys
            )
        );
        bytes32 submissionCountKey = keccak256(
            abi.encode(_withdrawnValidators.poolId, _withdrawnValidators.reportingBlockNumber, encodedPubkeys)
        );

        uint8 submissionCount = attestSubmission(nodeSubmissionKey, submissionCountKey);
        // Emit withdrawn validators submitted event
        emit WithdrawnValidatorsSubmitted(
            msg.sender,
            _withdrawnValidators.poolId,
            _withdrawnValidators.reportingBlockNumber,
            _withdrawnValidators.sortedPubkeys,
            block.timestamp
        );

        if (
            submissionCount >= trustedNodesCount / 2 + 1 &&
            _withdrawnValidators.reportingBlockNumber >
            lastReportingBlockNumberForWithdrawnValidatorsByPoolId[_withdrawnValidators.poolId]
        ) {
            lastReportingBlockNumberForWithdrawnValidatorsByPoolId[_withdrawnValidators.poolId] = _withdrawnValidators
                .reportingBlockNumber;

            INodeRegistry(IPoolUtils(staderConfig.getPoolUtils()).getNodeRegistry(_withdrawnValidators.poolId))
                .withdrawnValidators(_withdrawnValidators.sortedPubkeys);

            // Emit withdrawn validators updated event
            emit WithdrawnValidatorsUpdated(
                _withdrawnValidators.poolId,
                _withdrawnValidators.reportingBlockNumber,
                _withdrawnValidators.sortedPubkeys,
                block.timestamp
            );
        }
    }

    /// @inheritdoc IStaderOracle
    function submitValidatorVerificationDetail(ValidatorVerificationDetail calldata _validatorVerificationDetail)
        external
        override
        nonReentrant
        trustedNodeOnly
        checkMinTrustedNodes
        whenNotPaused
    {
        if (_validatorVerificationDetail.reportingBlockNumber >= block.number) {
            revert ReportingFutureBlockData();
        }
        if (
            _validatorVerificationDetail.reportingBlockNumber % updateFrequencyMap[VALIDATOR_VERIFICATION_DETAIL_UF] > 0
        ) {
            revert InvalidReportingBlock();
        }

        bytes memory encodedPubkeys = abi.encode(
            _validatorVerificationDetail.sortedReadyToDepositPubkeys,
            _validatorVerificationDetail.sortedFrontRunPubkeys,
            _validatorVerificationDetail.sortedInvalidSignaturePubkeys
        );

        // Get submission keys
        bytes32 nodeSubmissionKey = keccak256(
            abi.encode(
                msg.sender,
                _validatorVerificationDetail.poolId,
                _validatorVerificationDetail.reportingBlockNumber,
                encodedPubkeys
            )
        );
        bytes32 submissionCountKey = keccak256(
            abi.encode(
                _validatorVerificationDetail.poolId,
                _validatorVerificationDetail.reportingBlockNumber,
                encodedPubkeys
            )
        );

        uint8 submissionCount = attestSubmission(nodeSubmissionKey, submissionCountKey);
        // Emit validator verification detail submitted event
        emit ValidatorVerificationDetailSubmitted(
            msg.sender,
            _validatorVerificationDetail.poolId,
            _validatorVerificationDetail.reportingBlockNumber,
            _validatorVerificationDetail.sortedReadyToDepositPubkeys,
            _validatorVerificationDetail.sortedFrontRunPubkeys,
            _validatorVerificationDetail.sortedInvalidSignaturePubkeys,
            block.timestamp
        );

        if (
            submissionCount >= trustedNodesCount / 2 + 1 &&
            _validatorVerificationDetail.reportingBlockNumber >
            lastReportingBlockNumberForValidatorVerificationDetailByPoolId[_validatorVerificationDetail.poolId]
        ) {
            lastReportingBlockNumberForValidatorVerificationDetailByPoolId[
                _validatorVerificationDetail.poolId
            ] = _validatorVerificationDetail.reportingBlockNumber;
            INodeRegistry(IPoolUtils(staderConfig.getPoolUtils()).getNodeRegistry(_validatorVerificationDetail.poolId))
                .markValidatorReadyToDeposit(
                    _validatorVerificationDetail.sortedReadyToDepositPubkeys,
                    _validatorVerificationDetail.sortedFrontRunPubkeys,
                    _validatorVerificationDetail.sortedInvalidSignaturePubkeys
                );

            // Emit validator verification detail updated event
            emit ValidatorVerificationDetailUpdated(
                _validatorVerificationDetail.poolId,
                _validatorVerificationDetail.reportingBlockNumber,
                _validatorVerificationDetail.sortedReadyToDepositPubkeys,
                _validatorVerificationDetail.sortedFrontRunPubkeys,
                _validatorVerificationDetail.sortedInvalidSignaturePubkeys,
                block.timestamp
            );
        }
    }

    /// @inheritdoc IStaderOracle
    function submitMissedAttestationPenalties(MissedAttestationPenaltyData calldata _mapd)
        external
        override
        trustedNodeOnly
        checkMinTrustedNodes
        whenNotPaused
    {
        if (_mapd.reportingBlockNumber >= block.number) {
            revert ReportingFutureBlockData();
        }
        if (_mapd.reportingBlockNumber != getMissedAttestationPenaltyReportableBlock()) {
            revert InvalidReportingBlock();
        }
        if (_mapd.index != lastReportedMAPDIndex + 1) {
            revert InvalidMAPDIndex();
        }

        bytes memory encodedPubkeys = abi.encode(_mapd.sortedPubkeys);

        // Get submission keys
        bytes32 nodeSubmissionKey = keccak256(abi.encode(msg.sender, _mapd.index, encodedPubkeys));
        bytes32 submissionCountKey = keccak256(abi.encode(_mapd.index, encodedPubkeys));
        uint8 submissionCount = attestSubmission(nodeSubmissionKey, submissionCountKey);

        // Emit missed attestation penalty submitted event
        emit MissedAttestationPenaltySubmitted(
            msg.sender,
            _mapd.index,
            block.number,
            _mapd.reportingBlockNumber,
            _mapd.sortedPubkeys
        );

        if ((submissionCount >= trustedNodesCount / 2 + 1)) {
            lastReportedMAPDIndex = _mapd.index;
            uint256 keyCount = _mapd.sortedPubkeys.length;
            for (uint256 i; i < keyCount; ) {
                bytes32 pubkeyRoot = UtilLib.getPubkeyRoot(_mapd.sortedPubkeys[i]);
                missedAttestationPenalty[pubkeyRoot]++;
                unchecked {
                    ++i;
                }
            }
            emit MissedAttestationPenaltyUpdated(_mapd.index, block.number, _mapd.sortedPubkeys);
        }
    }

    /// @inheritdoc IStaderOracle
    function enableSafeMode() external override {
        UtilLib.onlyManagerRole(msg.sender, staderConfig);
        safeMode = true;
        emit SafeModeEnabled();
    }

    function disableSafeMode() external override onlyRole(DEFAULT_ADMIN_ROLE) {
        safeMode = false;
        emit SafeModeDisabled();
    }

    function updateTrustedNodeChangeCoolingPeriod(uint256 _trustedNodeChangeCoolingPeriod) external {
        UtilLib.onlyManagerRole(msg.sender, staderConfig);
        trustedNodeChangeCoolingPeriod = _trustedNodeChangeCoolingPeriod;
        emit TrustedNodeChangeCoolingPeriodUpdated(_trustedNodeChangeCoolingPeriod);
    }

    //update the address of staderConfig
    function updateStaderConfig(address _staderConfig) external onlyRole(DEFAULT_ADMIN_ROLE) {
        UtilLib.checkNonZeroAddress(_staderConfig);
        staderConfig = IStaderConfig(_staderConfig);
        emit UpdatedStaderConfig(_staderConfig);
    }

    function setERUpdateFrequency(uint256 _updateFrequency) external override {
        UtilLib.onlyManagerRole(msg.sender, staderConfig);
        if (_updateFrequency > MAX_ER_UPDATE_FREQUENCY) {
            revert InvalidUpdate();
        }
        setUpdateFrequency(ETHX_ER_UF, _updateFrequency);
    }

    function togglePORFeedBasedERData() external override checkERInspectionMode {
        UtilLib.onlyManagerRole(msg.sender, staderConfig);
        isPORFeedBasedERData = !isPORFeedBasedERData;
        emit ERDataSourceToggled(isPORFeedBasedERData);
    }

    //update the deviation threshold value, 0 deviationThreshold not allowed
    function updateERChangeLimit(uint256 _erChangeLimit) external override {
        UtilLib.onlyManagerRole(msg.sender, staderConfig);
        if (_erChangeLimit == 0 || _erChangeLimit > ER_CHANGE_MAX_BPS) {
            revert ERPermissibleChangeOutofBounds();
        }
        erChangeLimit = _erChangeLimit;
        emit UpdatedERChangeLimit(erChangeLimit);
    }

    function setSDPriceUpdateFrequency(uint256 _updateFrequency) external override {
        UtilLib.onlyManagerRole(msg.sender, staderConfig);
        setUpdateFrequency(SD_PRICE_UF, _updateFrequency);
    }

    function setValidatorStatsUpdateFrequency(uint256 _updateFrequency) external override {
        UtilLib.onlyManagerRole(msg.sender, staderConfig);
        setUpdateFrequency(VALIDATOR_STATS_UF, _updateFrequency);
    }

    function setWithdrawnValidatorsUpdateFrequency(uint256 _updateFrequency) external override {
        UtilLib.onlyManagerRole(msg.sender, staderConfig);
        setUpdateFrequency(WITHDRAWN_VALIDATORS_UF, _updateFrequency);
    }

    function setValidatorVerificationDetailUpdateFrequency(uint256 _updateFrequency) external override {
        UtilLib.onlyManagerRole(msg.sender, staderConfig);
        setUpdateFrequency(VALIDATOR_VERIFICATION_DETAIL_UF, _updateFrequency);
    }

    function setMissedAttestationPenaltyUpdateFrequency(uint256 _updateFrequency) external override {
        UtilLib.onlyManagerRole(msg.sender, staderConfig);
        setUpdateFrequency(MISSED_ATTESTATION_PENALTY_UF, _updateFrequency);
    }

    function setUpdateFrequency(bytes32 _key, uint256 _updateFrequency) internal {
        if (_updateFrequency == 0) {
            revert ZeroFrequency();
        }
        if (_updateFrequency == updateFrequencyMap[_key]) {
            revert FrequencyUnchanged();
        }
        updateFrequencyMap[_key] = _updateFrequency;

        emit UpdateFrequencyUpdated(_updateFrequency);
    }

    function getERReportableBlock() external view override returns (uint256) {
        return getReportableBlockFor(ETHX_ER_UF);
    }

    function getMerkleRootReportableBlockByPoolId(uint8 _poolId) public view override returns (uint256) {
        (, , uint256 currentEndBlock) = ISocializingPool(
            IPoolUtils(staderConfig.getPoolUtils()).getSocializingPoolAddress(_poolId)
        ).getRewardDetails();
        return currentEndBlock;
    }

    function getSDPriceReportableBlock() public view override returns (uint256) {
        return getReportableBlockFor(SD_PRICE_UF);
    }

    function getValidatorStatsReportableBlock() external view override returns (uint256) {
        return getReportableBlockFor(VALIDATOR_STATS_UF);
    }

    function getWithdrawnValidatorReportableBlock() external view override returns (uint256) {
        return getReportableBlockFor(WITHDRAWN_VALIDATORS_UF);
    }

    function getValidatorVerificationDetailReportableBlock() external view override returns (uint256) {
        return getReportableBlockFor(VALIDATOR_VERIFICATION_DETAIL_UF);
    }

    function getMissedAttestationPenaltyReportableBlock() public view override returns (uint256) {
        return getReportableBlockFor(MISSED_ATTESTATION_PENALTY_UF);
    }

    function getReportableBlockFor(bytes32 _key) internal view returns (uint256) {
        uint256 updateFrequency = updateFrequencyMap[_key];
        if (updateFrequency == 0) {
            revert UpdateFrequencyNotSet();
        }
        return (block.number / updateFrequency) * updateFrequency;
    }

    function getCurrentRewardsIndexByPoolId(uint8 _poolId) public view returns (uint256) {
        return
            ISocializingPool(IPoolUtils(staderConfig.getPoolUtils()).getSocializingPoolAddress(_poolId))
                .getCurrentRewardsIndex();
    }

    function getValidatorStats() external view override returns (ValidatorStats memory) {
        return (validatorStats);
    }

    function getExchangeRate() external view override returns (ExchangeRate memory) {
        return (exchangeRate);
    }

    function attestSubmission(bytes32 _nodeSubmissionKey, bytes32 _submissionCountKey)
        internal
        returns (uint8 _submissionCount)
    {
        // Check & update node submission status
        if (nodeSubmissionKeys[_nodeSubmissionKey]) {
            revert DuplicateSubmissionFromNode();
        }
        nodeSubmissionKeys[_nodeSubmissionKey] = true;
        submissionCountKeys[_submissionCountKey]++;
        _submissionCount = submissionCountKeys[_submissionCountKey];
    }

    function getSDPriceInETH() external view override returns (uint256) {
        return lastReportedSDPriceData.sdPriceInETH;
    }

    function getPORFeedData()
        internal
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        (, int256 totalETHBalanceInInt, , , ) = AggregatorV3Interface(staderConfig.getETHBalancePORFeedProxy())
            .latestRoundData();
        (, int256 totalETHXSupplyInInt, , , ) = AggregatorV3Interface(staderConfig.getETHXSupplyPORFeedProxy())
            .latestRoundData();
        return (uint256(totalETHBalanceInInt), uint256(totalETHXSupplyInInt), block.number);
    }

    function updateWithInLimitER(
        uint256 _newTotalETHBalance,
        uint256 _newTotalETHXSupply,
        uint256 _reportingBlockNumber
    ) internal {
        uint256 currentExchangeRate = UtilLib.computeExchangeRate(
            exchangeRate.totalETHBalance,
            exchangeRate.totalETHXSupply,
            staderConfig
        );
        uint256 newExchangeRate = UtilLib.computeExchangeRate(_newTotalETHBalance, _newTotalETHXSupply, staderConfig);
        if (
            !(newExchangeRate >= (currentExchangeRate * (ER_CHANGE_MAX_BPS - erChangeLimit)) / ER_CHANGE_MAX_BPS &&
                newExchangeRate <= ((currentExchangeRate * (ER_CHANGE_MAX_BPS + erChangeLimit)) / ER_CHANGE_MAX_BPS))
        ) {
            erInspectionMode = true;
            erInspectionModeStartBlock = block.number;
            inspectionModeExchangeRate.totalETHBalance = _newTotalETHBalance;
            inspectionModeExchangeRate.totalETHXSupply = _newTotalETHXSupply;
            inspectionModeExchangeRate.reportingBlockNumber = _reportingBlockNumber;
            emit ERInspectionModeActivated(erInspectionMode, block.timestamp);
            return;
        }
        _updateExchangeRate(_newTotalETHBalance, _newTotalETHXSupply, _reportingBlockNumber);
    }

    function _updateExchangeRate(
        uint256 _totalETHBalance,
        uint256 _totalETHXSupply,
        uint256 _reportingBlockNumber
    ) internal {
        exchangeRate.totalETHBalance = _totalETHBalance;
        exchangeRate.totalETHXSupply = _totalETHXSupply;
        exchangeRate.reportingBlockNumber = _reportingBlockNumber;

        // Emit balances updated event
        emit ExchangeRateUpdated(
            exchangeRate.reportingBlockNumber,
            exchangeRate.totalETHBalance,
            exchangeRate.totalETHXSupply,
            block.timestamp
        );
    }

    /**
     * @dev Triggers stopped state.
     * Contract must not be paused.
     */
    function pause() external {
        UtilLib.onlyManagerRole(msg.sender, staderConfig);
        _pause();
    }

    /**
     * @dev Returns to normal state.
     * Contract must be paused
     */
    function unpause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
    }

    modifier checkERInspectionMode() {
        if (erInspectionMode) {
            revert InspectionModeActive();
        }
        _;
    }

    modifier trustedNodeOnly() {
        if (!isTrustedNode[msg.sender]) {
            revert NotATrustedNode();
        }
        _;
    }

    modifier checkMinTrustedNodes() {
        if (trustedNodesCount < MIN_TRUSTED_NODES) {
            revert InsufficientTrustedNodes();
        }
        _;
    }
}