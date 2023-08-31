// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.8;

import "openzeppelin-contracts/utils/math/SafeCast.sol";
import "src/oracles/BaseOracle.sol";
import "src/interfaces/IWithdrawOracle.sol";
import "src/interfaces/IVaultManager.sol";
import {WithdrawInfo, ExitValidatorInfo} from "src/library/ConsensusStruct.sol";

contract WithdrawOracle is IWithdrawOracle, BaseOracle {
    using SafeCast for uint256;

    event UpdateExitRequestLimit(uint256 exitRequestLimit);
    event UpdateTotalBalanceTolerate(uint256 old, uint256 totalBalanceTolerate);
    event UpdateClVaultMinSettleLimit(uint256 clVaultMinSettleLimit);
    event PendingBalancesAdd(uint256 _addBalance, uint256 _totalBalance);
    event PendingBalancesReset(uint256 totalBalance);
    event LiquidStakingChanged(address oldLiq, address newLiq);
    event VaultManagerChanged(address oldVaultManager, address newVaultManager);
    event ReportDataSuccess(
        uint256 indexed refSlot, uint256 reportExitedCount, uint256 clBalance, uint256 clVaultBalance
    );

    error UnsupportedRequestsDataFormat(uint256 format);
    error InvalidRequestsData();
    error InvalidRequestsDataLength();
    error UnexpectedRequestsDataLength();
    error ArgumentOutOfBounds();
    error ExitRequestLimitNotZero();
    error ClVaultMinSettleLimitNotZero();
    error ValidatorReportedExited(uint256 tokenId);
    error ClVaultBalanceNotMinSettleLimit();
    error InvalidTotalBalance(uint256 curTotal, uint256 minTotal, uint256 maxTotal);

    struct DataProcessingState {
        uint64 refSlot;
        uint64 reportExitedCount;
    }

    struct ProcessingState {
        /// @notice Reference slot for the current reporting frame.
        uint256 currentFrameRefSlot;
        /// @notice The last time at which a report data can be submitted for the current
        /// reporting frame.
        uint256 processingDeadlineTime;
        /// @notice Hash of the report data. Zero bytes if consensus on the hash hasn't
        /// been reached yet for the current reporting frame.
        bytes32 dataHash;
        /// @notice Whether any report data for the for the current reporting frame has been
        /// already submitted.
        bool dataSubmitted;
        /// @notice Number of exits reported for the current reporting frame.
        uint256 reportExitedCount;
    }

    /// Data provider interface
    struct ReportData {
        /// @dev Version of the oracle consensus rules. Current version expected
        /// by the oracle can be obtained by calling getConsensusVersion().
        uint256 consensusVersion;
        /// @dev Reference slot for which the report was calculated. If the slot
        /// contains a block, the exitBlockNumbers being reported should include all state
        /// changes resulting from that block. The epoch containing the slot
        /// should be finalized prior to calculating the report.
        // beacon slot for reference
        uint256 refSlot;
        /// Consensus layer NodeDao's validators balance
        uint256 clBalance;
        /// Consensus Vault contract balance
        uint256 clVaultBalance;
        // clSettleAmount  The total amount settled at the consensus level this time
        uint256 clSettleAmount;
        /// Number of exits reported
        uint256 reportExitedCount;
        // operator exit principal and reward reinvestment distribution
        // sum(clReward + clCapital)  = clSettleAmount
        WithdrawInfo[] withdrawInfos;
        // To exit the validator's info
        ExitValidatorInfo[] exitValidatorInfos;
    }

    DataProcessingState internal dataProcessingState;

    // Specifies the maximum number of validator exits reported each time
    uint256 public exitRequestLimit;

    // Minimum value limit for oracle Clearing clvault (unit: wei, default: 10 ether)
    uint256 public clVaultMinSettleLimit;

    // current pending balance
    uint256 public pendingBalances;

    /// Consensus layer NodeDao's validators balance
    uint256 public clBalances;

    /// Consensus Vault contract balance
    uint256 public clVaultBalance;

    // The total amount settled at the consensus level this time
    uint256 public lastClSettleAmount;

    // Acceptable difference in reported totalBalance
    uint256 public totalBalanceTolerate;

    address public liquidStakingContractAddress;

    address public vaultManager;

    uint256 public lastRefSlot;

    modifier onlyLiquidStaking() {
        if (liquidStakingContractAddress != msg.sender) revert PermissionDenied();
        _;
    }

    function initialize(
        uint256 secondsPerSlot,
        uint256 genesisTime,
        address consensusContract,
        uint256 consensusVersion,
        uint256 lastProcessingRefSlot,
        address _dao,
        uint256 _exitRequestLimit,
        uint256 _clVaultMinSettleLimit,
        uint256 _clBalance,
        uint256 _pendingBalance
    ) public initializer {
        __BaseOracle_init(secondsPerSlot, genesisTime, consensusContract, consensusVersion, lastProcessingRefSlot, _dao);

        exitRequestLimit = _exitRequestLimit;
        clVaultMinSettleLimit = _clVaultMinSettleLimit;
        clBalances = _clBalance;
        pendingBalances = _pendingBalance;
    }

    function initializeV2(address _consensus, uint256 _lastProcessingRefSlot) public reinitializer(2) onlyOwner {
        _setConsensusContract(_consensus, _lastProcessingRefSlot);
        _updateContractVersion(2);
        _setConsensusVersion(2);
    }

    /// Set the number limit for the validator to report
    function setExitRequestLimit(uint256 _exitRequestLimit) external onlyDao {
        if (_exitRequestLimit == 0) revert ExitRequestLimitNotZero();
        exitRequestLimit = _exitRequestLimit;
        emit UpdateExitRequestLimit(_exitRequestLimit);
    }

    function setTotalBalanceTolerate(uint256 _totalBalanceTolerate) external onlyDao {
        uint256 old = totalBalanceTolerate;
        totalBalanceTolerate = _totalBalanceTolerate;
        emit UpdateTotalBalanceTolerate(old, _totalBalanceTolerate);
    }

    function setClVaultMinSettleLimit(uint256 _clVaultMinSettleLimit) external onlyDao {
        if (_clVaultMinSettleLimit == 0) revert ClVaultMinSettleLimitNotZero();
        clVaultMinSettleLimit = _clVaultMinSettleLimit;

        emit UpdateClVaultMinSettleLimit(_clVaultMinSettleLimit);
    }

    /**
     * @return The total balance of the consensus layer
     */
    function getClBalances() external view returns (uint256) {
        return clBalances;
    }

    /**
     * @return {uint256} Consensus reward settle amounte
     */
    function getLastClSettleAmount() external view returns (uint256) {
        return lastClSettleAmount;
    }

    /**
     * @return {uint256} Consensus Vault contract balance
     */
    function getClVaultBalances() external view returns (uint256) {
        return clVaultBalance;
    }

    /**
     * @return The total balance of the pending validators
     */
    function getPendingBalances() external view returns (uint256) {
        return pendingBalances;
    }

    /**
     * @notice add pending validator value
     */
    function addPendingBalances(uint256 _pendingBalance) external onlyLiquidStaking {
        pendingBalances += _pendingBalance;
        emit PendingBalancesAdd(_pendingBalance, pendingBalances);
    }

    /**
     * @notice set LiquidStaking contract address
     * @param _liquidStakingContractAddress - contract address
     */
    function setLiquidStaking(address _liquidStakingContractAddress) external onlyDao {
        if (_liquidStakingContractAddress == address(0)) revert InvalidAddr();
        emit LiquidStakingChanged(liquidStakingContractAddress, _liquidStakingContractAddress);
        liquidStakingContractAddress = _liquidStakingContractAddress;
    }

    function setVaultManager(address _vaultManagerContractAddress) external onlyDao {
        if (_vaultManagerContractAddress == address(0)) revert InvalidAddr();
        emit VaultManagerChanged(vaultManager, _vaultManagerContractAddress);
        vaultManager = _vaultManagerContractAddress;
    }

    /// @notice Submits report data for processing.
    ///
    /// @param data The data. See the `ReportData` structure's docs for details.
    /// @param _contractVersion Expected version of the oracle contract.
    ///
    /// Reverts if:
    /// - The caller is not a member of the oracle committee and doesn't possess the
    ///   SUBMIT_DATA_ROLE.
    /// - The provided contract version is different from the current one.
    /// - The provided consensus version is different from the expected one.
    /// - The provided reference slot differs from the current consensus frame's one.
    /// - The processing deadline for the current consensus frame is missed.
    /// - The keccak256 hash of the ABI-encoded data is different from the last hash
    ///   provided by the hash consensus contract.
    /// - The provided data doesn't meet safety checks.
    function submitReportData(ReportData calldata data, uint256 _contractVersion, uint256 _moduleId)
        external
        whenNotPaused
    {
        _checkMsgSenderIsAllowedToSubmitData();
        _checkContractVersion(_contractVersion);
        // it's a waste of gas to copy the whole calldata into mem but seems there's no way around
        _checkConsensusData(data.refSlot, data.consensusVersion, keccak256(abi.encode(data)), _moduleId);
        _startProcessing();
        _handleConsensusReportData(data);
    }

    /// @notice Returns data processing state for the current reporting frame.
    /// @return result See the docs for the `ProcessingState` struct.
    function getProcessingState() external view returns (ProcessingState memory result) {
        ConsensusReport memory report = consensusReport;
        result.currentFrameRefSlot = _getCurrentRefSlot();

        if (result.currentFrameRefSlot != report.refSlot) {
            return result;
        }

        result.processingDeadlineTime = report.processingDeadlineTime;
        result.dataHash = report.hash;

        DataProcessingState memory procState = dataProcessingState;

        result.dataSubmitted = procState.refSlot == result.currentFrameRefSlot;
        if (!result.dataSubmitted) {
            return result;
        }

        result.reportExitedCount = procState.reportExitedCount;
    }

    function _handleConsensusReportData(ReportData calldata data) internal {
        if (data.exitValidatorInfos.length != data.reportExitedCount) revert InvalidRequestsDataLength();
        if (data.reportExitedCount > exitRequestLimit) revert UnexpectedRequestsDataLength();

        // TotalClBalance check
        _checkTotalClBalance(data.refSlot, data.clBalance, data.clVaultBalance);

        // Invoke vault Manager to process the reported data
        IVaultManager(vaultManager).reportConsensusData(
            data.withdrawInfos, data.exitValidatorInfos, data.clSettleAmount
        );

        // oracle maintains the necessary data
        _dealReportOracleData(data.refSlot, data.clBalance, data.clVaultBalance, data.clSettleAmount);

        dataProcessingState = DataProcessingState({
            refSlot: data.refSlot.toUint64(),
            reportExitedCount: data.reportExitedCount.toUint64()
        });
        emit ReportDataSuccess(data.refSlot, data.reportExitedCount, data.clBalance, data.clVaultBalance);
    }

    /// revert case
    /// preTotal = clVaultBalance + clBalances - lastClSettleAmount
    /// curTotal = _curClVaultBalance + _curClBalances
    /// culTotal < preTotal - totalBalanceTolerate
    /// culTotal > preTotal + pendingBalances + preTotal * (curRefSlot - preRefSlot) * 10 / 100 / 365 / 7200 + totalBalanceTolerate
    function _checkTotalClBalance(uint256 _curRefSlot, uint256 _curClBalances, uint256 _curClVaultBalance)
        internal
        view
    {
        uint256 preTotal = clVaultBalance + clBalances - lastClSettleAmount;
        uint256 curTotal = _curClVaultBalance + _curClBalances;
        uint256 minTotal = preTotal - totalBalanceTolerate;
        uint256 maxTotal = preTotal + pendingBalances + preTotal * (_curRefSlot - lastRefSlot) * 10 / 100 / 365 / 7200
            + totalBalanceTolerate;

        if (curTotal < minTotal || (maxTotal != 0 && maxTotal != pendingBalances && curTotal > maxTotal)) {
            revert InvalidTotalBalance(curTotal, minTotal, maxTotal);
        }
    }

    function _dealReportOracleData(
        uint256 _refSlot,
        uint256 _clBalances,
        uint256 _clVaultBalance,
        uint256 _clSettleAmount
    ) internal {
        pendingBalances = 0;
        emit PendingBalancesReset(0);

        lastRefSlot = _refSlot;
        clBalances = _clBalances;
        clVaultBalance = _clVaultBalance;
        lastClSettleAmount = _clSettleAmount;
    }

    /// @notice Called when oracle gets a new consensus report from the HashConsensus contract.
    ///
    /// Keep in mind that, until you call `_startProcessing`, the oracle committee is free to
    /// reach consensus on another report for the same reporting frame and re-submit it using
    /// this function.
    /// use for submitConsensusReport
    function _handleConsensusReport(
        ConsensusReport memory report,
        uint256 prevSubmittedRefSlot,
        uint256 prevProcessingRefSlot
    ) internal override {}
}