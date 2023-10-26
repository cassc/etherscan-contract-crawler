//SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import "../interfaces/components/IOracleManager.1.sol";
import "../interfaces/IRedeemManager.1.sol";

import "../libraries/LibUint256.sol";

import "../state/river/LastConsensusLayerReport.sol";
import "../state/river/OracleAddress.sol";
import "../state/river/CLValidatorTotalBalance.sol";
import "../state/river/CLValidatorCount.sol";
import "../state/river/DepositedValidatorCount.sol";
import "../state/river/LastOracleRoundId.sol";

/// @title Oracle Manager (v1)
/// @author Kiln
/// @notice This contract handles the inputs provided by the oracle
/// @notice The Oracle contract is plugged to this contract and is in charge of pushing
/// @notice data whenever a new report has been deemed valid. The report consists in two
/// @notice values: the sum of all balances of all deposited validators and the count of
/// @notice validators that have been activated on the consensus layer.
abstract contract OracleManagerV1 is IOracleManagerV1 {
    uint256 internal constant ONE_YEAR = 365 days;
    /// @notice Size of a deposit in ETH
    uint256 public constant _DEPOSIT_SIZE = 32 ether;

    /// @notice Handler called if the delta between the last and new validator balance sum is positive
    /// @dev Must be overridden
    /// @param _profits The positive increase in the validator balance sum (staking rewards)
    function _onEarnings(uint256 _profits) internal virtual;

    /// @notice Handler called to pull the Execution layer fees from the recipient
    /// @dev Must be overridden
    /// @param _max The maximum amount to pull inside the system
    /// @return The amount pulled inside the system
    function _pullELFees(uint256 _max) internal virtual returns (uint256);

    /// @notice Handler called to pull the coverage funds
    /// @dev Must be overridden
    /// @param _max The maximum amount to pull inside the system
    /// @return The amount pulled inside the system
    function _pullCoverageFunds(uint256 _max) internal virtual returns (uint256);

    /// @notice Handler called to retrieve the system administrator address
    /// @dev Must be overridden
    /// @return The system administrator address
    function _getRiverAdmin() internal view virtual returns (address);

    /// @notice Overridden handler called whenever the total balance of ETH is requested
    /// @return The current total asset balance managed by River
    function _assetBalance() internal view virtual returns (uint256);

    /// @notice Pulls funds from the Withdraw contract, and adds funds to deposit and redeem balances
    /// @param _skimmedEthAmount The new amount of skimmed eth to pull
    /// @param _exitedEthAmount The new amount of exited eth to pull
    function _pullCLFunds(uint256 _skimmedEthAmount, uint256 _exitedEthAmount) internal virtual;

    /// @notice Pulls funds from the redeem manager exceeding eth buffer
    /// @param _max The maximum amount to pull
    /// @return The amount pulled
    function _pullRedeemManagerExceedingEth(uint256 _max) internal virtual returns (uint256);

    /// @notice Use the balance to redeem to report a withdrawal event on the redeem manager
    function _reportWithdrawToRedeemManager() internal virtual;

    /// @notice Requests exits of validators after possibly rebalancing deposit and redeem balances
    /// @param _exitingBalance The currently exiting funds, soon to be received on the execution layer
    /// @param _depositToRedeemRebalancingAllowed True if rebalancing from deposit to redeem is allowed
    function _requestExitsBasedOnRedeemDemandAfterRebalancings(
        uint256 _exitingBalance,
        uint32[] memory _stoppedValidatorCounts,
        bool _depositToRedeemRebalancingAllowed,
        bool _slashingContainmentModeEnabled
    ) internal virtual;

    /// @notice Skims the redeem balance and sends remaining funds to the deposit balance
    function _skimExcessBalanceToRedeem() internal virtual;

    /// @notice Commits the deposit balance up to the allowed daily limit
    /// @param _period The period between current and last report
    function _commitBalanceToDeposit(uint256 _period) internal virtual;

    /// @notice Prevents unauthorized calls
    modifier onlyAdmin_OMV1() {
        if (msg.sender != _getRiverAdmin()) {
            revert LibErrors.Unauthorized(msg.sender);
        }
        _;
    }

    /// @notice Set the initial oracle address
    /// @param _oracle Address of the oracle
    function initOracleManagerV1(address _oracle) internal {
        OracleAddress.set(_oracle);
        emit SetOracle(_oracle);
    }

    /// @notice Initializes version 1.1 of the oracle manager
    /// @param _epochsPerFrame The amounts of epochs in a frame
    /// @param _slotsPerEpoch The slots inside an epoch
    /// @param _secondsPerSlot The seconds inside a slot
    /// @param _genesisTime The genesis timestamp
    /// @param _epochsToAssumedFinality The number of epochs before an epoch is considered final on-chain
    /// @param _annualAprUpperBound The reporting upper bound
    /// @param _relativeLowerBound The reporting lower bound
    function initOracleManagerV1_1(
        uint64 _epochsPerFrame,
        uint64 _slotsPerEpoch,
        uint64 _secondsPerSlot,
        uint64 _genesisTime,
        uint64 _epochsToAssumedFinality,
        uint256 _annualAprUpperBound,
        uint256 _relativeLowerBound
    ) internal {
        CLSpec.set(
            CLSpec.CLSpecStruct({
                epochsPerFrame: _epochsPerFrame,
                slotsPerEpoch: _slotsPerEpoch,
                secondsPerSlot: _secondsPerSlot,
                genesisTime: _genesisTime,
                epochsToAssumedFinality: _epochsToAssumedFinality
            })
        );
        emit SetSpec(_epochsPerFrame, _slotsPerEpoch, _secondsPerSlot, _genesisTime, _epochsToAssumedFinality);
        ReportBounds.set(
            ReportBounds.ReportBoundsStruct({
                annualAprUpperBound: _annualAprUpperBound,
                relativeLowerBound: _relativeLowerBound
            })
        );
        emit SetBounds(_annualAprUpperBound, _relativeLowerBound);

        IOracleManagerV1.StoredConsensusLayerReport memory storedReport;
        storedReport.epoch = uint256(LastOracleRoundId.get());
        storedReport.validatorsBalance = CLValidatorTotalBalance.get();
        storedReport.validatorsSkimmedBalance = 0;
        storedReport.validatorsExitedBalance = 0;
        storedReport.validatorsExitingBalance = 0;
        storedReport.validatorsCount = uint32(CLValidatorCount.get());
        storedReport.rebalanceDepositToRedeemMode = false;
        storedReport.slashingContainmentMode = false;
        LastConsensusLayerReport.set(storedReport);
    }

    /// @inheritdoc IOracleManagerV1
    function getOracle() external view returns (address) {
        return OracleAddress.get();
    }

    /// @inheritdoc IOracleManagerV1
    function getCLValidatorTotalBalance() external view returns (uint256) {
        return LastConsensusLayerReport.get().validatorsBalance;
    }

    /// @inheritdoc IOracleManagerV1
    function getCLValidatorCount() external view returns (uint256) {
        return LastConsensusLayerReport.get().validatorsCount;
    }

    /// @inheritdoc IOracleManagerV1
    function getExpectedEpochId() external view returns (uint256) {
        CLSpec.CLSpecStruct memory cls = CLSpec.get();
        uint256 currentEpoch = _currentEpoch(cls);
        return LibUint256.max(
            LastConsensusLayerReport.get().epoch + cls.epochsPerFrame,
            currentEpoch - (currentEpoch % cls.epochsPerFrame)
        );
    }

    /// @inheritdoc IOracleManagerV1
    function isValidEpoch(uint256 _epoch) external view returns (bool) {
        return _isValidEpoch(CLSpec.get(), _epoch);
    }

    /// @inheritdoc IOracleManagerV1
    function getTime() external view returns (uint256) {
        return block.timestamp;
    }

    /// @inheritdoc IOracleManagerV1
    function getLastCompletedEpochId() external view returns (uint256) {
        return LastConsensusLayerReport.get().epoch;
    }

    /// @inheritdoc IOracleManagerV1
    function getCurrentEpochId() external view returns (uint256) {
        return _currentEpoch(CLSpec.get());
    }

    /// @inheritdoc IOracleManagerV1
    function getCLSpec() external view returns (CLSpec.CLSpecStruct memory) {
        return CLSpec.get();
    }

    /// @inheritdoc IOracleManagerV1
    function getCurrentFrame() external view returns (uint256 _startEpochId, uint256 _startTime, uint256 _endTime) {
        CLSpec.CLSpecStruct memory cls = CLSpec.get();
        uint256 currentEpoch = _currentEpoch(cls);
        _startEpochId = currentEpoch - (currentEpoch % cls.epochsPerFrame);
        _startTime = _startEpochId * cls.slotsPerEpoch * cls.secondsPerSlot;
        _endTime = (_startEpochId + cls.epochsPerFrame) * cls.slotsPerEpoch * cls.secondsPerSlot - 1;
    }

    /// @inheritdoc IOracleManagerV1
    function getFrameFirstEpochId(uint256 _epochId) external view returns (uint256) {
        return _epochId - (_epochId % CLSpec.get().epochsPerFrame);
    }

    /// @inheritdoc IOracleManagerV1
    function getReportBounds() external view returns (ReportBounds.ReportBoundsStruct memory) {
        return ReportBounds.get();
    }

    /// @inheritdoc IOracleManagerV1
    function getLastConsensusLayerReport() external view returns (IOracleManagerV1.StoredConsensusLayerReport memory) {
        return LastConsensusLayerReport.get();
    }

    /// @inheritdoc IOracleManagerV1
    function setOracle(address _oracleAddress) external onlyAdmin_OMV1 {
        OracleAddress.set(_oracleAddress);
        emit SetOracle(_oracleAddress);
    }

    /// @inheritdoc IOracleManagerV1
    function setCLSpec(CLSpec.CLSpecStruct calldata _newValue) external onlyAdmin_OMV1 {
        CLSpec.set(_newValue);
        emit SetSpec(
            _newValue.epochsPerFrame,
            _newValue.slotsPerEpoch,
            _newValue.secondsPerSlot,
            _newValue.genesisTime,
            _newValue.epochsToAssumedFinality
        );
    }

    /// @inheritdoc IOracleManagerV1
    function setReportBounds(ReportBounds.ReportBoundsStruct calldata _newValue) external onlyAdmin_OMV1 {
        ReportBounds.set(_newValue);
        emit SetBounds(_newValue.annualAprUpperBound, _newValue.relativeLowerBound);
    }

    /// @notice Structure holding internal variables used during reporting
    struct ConsensusLayerDataReportingVariables {
        uint256 preReportUnderlyingBalance;
        uint256 postReportUnderlyingBalance;
        uint256 lastReportExitedBalance;
        uint256 lastReportSkimmedBalance;
        uint256 exitedAmountIncrease;
        uint256 skimmedAmountIncrease;
        uint256 timeElapsedSinceLastReport;
        uint256 availableAmountToUpperBound;
        uint256 redeemManagerDemand;
        ConsensusLayerDataReportingTrace trace;
    }

    /// @inheritdoc IOracleManagerV1
    function setConsensusLayerData(IOracleManagerV1.ConsensusLayerReport calldata _report) external {
        // only the oracle is allowed to call this endpoint
        if (msg.sender != OracleAddress.get()) {
            revert LibErrors.Unauthorized(msg.sender);
        }

        CLSpec.CLSpecStruct memory cls = CLSpec.get();

        // we start by verifying that the reported epoch is valid based on the consensus layer spec
        if (!_isValidEpoch(cls, _report.epoch)) {
            revert InvalidEpoch(_report.epoch);
        }

        ConsensusLayerDataReportingVariables memory vars;

        {
            IOracleManagerV1.StoredConsensusLayerReport storage lastStoredReport = LastConsensusLayerReport.get();

            vars.lastReportExitedBalance = lastStoredReport.validatorsExitedBalance;

            // we ensure that the reported total exited balance is not decreasing
            if (_report.validatorsExitedBalance < vars.lastReportExitedBalance) {
                revert InvalidDecreasingValidatorsExitedBalance(
                    vars.lastReportExitedBalance, _report.validatorsExitedBalance
                );
            }

            // we compute the exited amount increase by taking the delta between reports
            vars.exitedAmountIncrease = _report.validatorsExitedBalance - vars.lastReportExitedBalance;

            vars.lastReportSkimmedBalance = lastStoredReport.validatorsSkimmedBalance;

            // we ensure that the reported total skimmed balance is not decreasing
            if (_report.validatorsSkimmedBalance < vars.lastReportSkimmedBalance) {
                revert InvalidDecreasingValidatorsSkimmedBalance(
                    vars.lastReportSkimmedBalance, _report.validatorsSkimmedBalance
                );
            }

            // we ensure that the reported validator count is not decreasing
            if (
                _report.validatorsCount > DepositedValidatorCount.get()
                    || _report.validatorsCount < lastStoredReport.validatorsCount
            ) {
                revert InvalidValidatorCountReport(
                    _report.validatorsCount, DepositedValidatorCount.get(), lastStoredReport.validatorsCount
                );
            }

            // we compute the new skimmed amount by taking the delta between reports
            vars.skimmedAmountIncrease = _report.validatorsSkimmedBalance - vars.lastReportSkimmedBalance;

            vars.timeElapsedSinceLastReport = _timeBetweenEpochs(cls, lastStoredReport.epoch, _report.epoch);
        }

        // we retrieve the current total underlying balance before any reporting data is applied to the system
        vars.preReportUnderlyingBalance = _assetBalance();

        // if we have new exited / skimmed eth available, we pull funds from the consensus layer recipient
        if (vars.exitedAmountIncrease + vars.skimmedAmountIncrease > 0) {
            // this method pulls and updates ethToDeposit / ethToRedeem accordingly
            _pullCLFunds(vars.skimmedAmountIncrease, vars.exitedAmountIncrease);
        }

        {
            // we update the system parameters, this will have an impact on how the total underlying balance is computed
            IOracleManagerV1.StoredConsensusLayerReport memory storedReport;

            storedReport.epoch = _report.epoch;
            storedReport.validatorsBalance = _report.validatorsBalance;
            storedReport.validatorsSkimmedBalance = _report.validatorsSkimmedBalance;
            storedReport.validatorsExitedBalance = _report.validatorsExitedBalance;
            storedReport.validatorsExitingBalance = _report.validatorsExitingBalance;
            storedReport.validatorsCount = _report.validatorsCount;
            storedReport.rebalanceDepositToRedeemMode = _report.rebalanceDepositToRedeemMode;
            storedReport.slashingContainmentMode = _report.slashingContainmentMode;
            LastConsensusLayerReport.set(storedReport);
        }

        ReportBounds.ReportBoundsStruct memory rb = ReportBounds.get();

        // we compute the maximum allowed increase in balance based on the pre report value
        uint256 maxIncrease = _maxIncrease(rb, vars.preReportUnderlyingBalance, vars.timeElapsedSinceLastReport);

        // we retrieve the new total underlying balance after system parameters are changed
        vars.postReportUnderlyingBalance = _assetBalance();

        // we can now compute the earned rewards from the consensus layer balances
        // in order to properly account for the balance increase, we compare the sums of current balances, skimmed balance and exited balances
        // we also synthetically increase the current balance by 32 eth per new activated validator, this way we have no discrepency due
        // to currently activating funds that were not yet accounted in the consensus layer balances
        if (vars.postReportUnderlyingBalance >= vars.preReportUnderlyingBalance) {
            // if this happens, we revert and the reporting process is cancelled
            if (vars.postReportUnderlyingBalance > vars.preReportUnderlyingBalance + maxIncrease) {
                revert TotalValidatorBalanceIncreaseOutOfBound(
                    vars.preReportUnderlyingBalance,
                    vars.postReportUnderlyingBalance,
                    vars.timeElapsedSinceLastReport,
                    rb.annualAprUpperBound
                );
            }

            // we update the rewards based on the balance delta
            vars.trace.rewards = vars.postReportUnderlyingBalance - vars.preReportUnderlyingBalance;

            // we update the available amount to upper bound (the amount of eth we can still pull and stay below the upper reporting bound)
            vars.availableAmountToUpperBound = maxIncrease - vars.trace.rewards;
        } else {
            // otherwise if the balance has decreased, we verify that we are not exceeding the lower reporting bound

            // we compute the maximum allowed decrease in balance
            uint256 maxDecrease = _maxDecrease(rb, vars.preReportUnderlyingBalance);

            // we verify that the bound is not crossed
            if (
                vars.postReportUnderlyingBalance
                    < vars.preReportUnderlyingBalance - LibUint256.min(maxDecrease, vars.preReportUnderlyingBalance)
            ) {
                revert TotalValidatorBalanceDecreaseOutOfBound(
                    vars.preReportUnderlyingBalance,
                    vars.postReportUnderlyingBalance,
                    vars.timeElapsedSinceLastReport,
                    rb.relativeLowerBound
                );
            }

            // we update the available amount to upper bound to be equal to the maximum allowed increase plus the negative delta due to the loss
            vars.availableAmountToUpperBound =
                maxIncrease + (vars.preReportUnderlyingBalance - vars.postReportUnderlyingBalance);
        }

        // if we have available amount to upper bound after the reporting values are applied
        if (vars.availableAmountToUpperBound > 0) {
            // we pull the funds from the execution layer fee recipient
            vars.trace.pulledELFees = _pullELFees(vars.availableAmountToUpperBound);
            // we update the rewards
            vars.trace.rewards += vars.trace.pulledELFees;
            // we update the available amount accordingly
            vars.availableAmountToUpperBound -= vars.trace.pulledELFees;
        }

        // if we have available amount to upper bound after the execution layer fees are pulled
        if (vars.availableAmountToUpperBound > 0) {
            // we pull the funds from the exceeding eth buffer of the redeem manager
            vars.trace.pulledRedeemManagerExceedingEthBuffer =
                _pullRedeemManagerExceedingEth(vars.availableAmountToUpperBound);
            // we update the available amount accordingly
            vars.availableAmountToUpperBound -= vars.trace.pulledRedeemManagerExceedingEthBuffer;
        }

        // if we have available amount to upper bound after pulling the exceeding eth buffer, we attempt to pull coverage funds
        if (vars.availableAmountToUpperBound > 0) {
            // we pull the funds from the coverage recipient
            vars.trace.pulledCoverageFunds = _pullCoverageFunds(vars.availableAmountToUpperBound);
            // we do not update the rewards as coverage is not considered rewards
            // we do not update the available amount as there are no more pulling actions to perform afterwards
        }

        // if our rewards are not null, we dispatch the fee to the collector
        if (vars.trace.rewards > 0) {
            _onEarnings(vars.trace.rewards);
        }

        _requestExitsBasedOnRedeemDemandAfterRebalancings(
            _report.validatorsExitingBalance,
            _report.stoppedValidatorCountPerOperator,
            _report.rebalanceDepositToRedeemMode,
            _report.slashingContainmentMode
        );

        // we use the updated balanceToRedeem value to report a withdraw event on the redeem manager
        _reportWithdrawToRedeemManager();

        // if funds are left in the balance to redeem, we move them to the deposit balance
        _skimExcessBalanceToRedeem();

        // we update the committable amount based on daily maximum allowed
        _commitBalanceToDeposit(vars.timeElapsedSinceLastReport);

        // we emit a summary event with all the reporting details
        emit ProcessedConsensusLayerReport(_report, vars.trace);
    }

    /// @notice Retrieve the current epoch based on the current timestamp
    /// @param _cls The consensus layer spec struct
    /// @return The current epoch
    function _currentEpoch(CLSpec.CLSpecStruct memory _cls) internal view returns (uint256) {
        return ((block.timestamp - _cls.genesisTime) / _cls.secondsPerSlot) / _cls.slotsPerEpoch;
    }

    /// @notice Verifies if the given epoch is valid
    /// @param _cls The consensus layer spec struct
    /// @param _epoch The epoch to verify
    /// @return True if valid
    function _isValidEpoch(CLSpec.CLSpecStruct memory _cls, uint256 _epoch) internal view returns (bool) {
        return (
            _currentEpoch(_cls) >= _epoch + _cls.epochsToAssumedFinality
                && _epoch > LastConsensusLayerReport.get().epoch && _epoch % _cls.epochsPerFrame == 0
        );
    }

    /// @notice Retrieves the maximum increase in balance based on current total underlying supply and period since last report
    /// @param _rb The report bounds struct
    /// @param _prevTotalEth The total underlying supply during reporting
    /// @param _timeElapsed The time since last report
    /// @return The maximum allowed increase in balance
    function _maxIncrease(ReportBounds.ReportBoundsStruct memory _rb, uint256 _prevTotalEth, uint256 _timeElapsed)
        internal
        pure
        returns (uint256)
    {
        return (_prevTotalEth * _rb.annualAprUpperBound * _timeElapsed) / (LibBasisPoints.BASIS_POINTS_MAX * ONE_YEAR);
    }

    /// @notice Retrieves the maximum decrease in balance based on current total underlying supply
    /// @param _rb The report bounds struct
    /// @param _prevTotalEth The total underlying supply during reporting
    /// @return The maximum allowed decrease in balance
    function _maxDecrease(ReportBounds.ReportBoundsStruct memory _rb, uint256 _prevTotalEth)
        internal
        pure
        returns (uint256)
    {
        return (_prevTotalEth * _rb.relativeLowerBound) / LibBasisPoints.BASIS_POINTS_MAX;
    }

    /// @notice Retrieve the number of seconds between two epochs
    /// @param _cls The consensus layer spec struct
    /// @param _epochPast The starting epoch
    /// @param _epochNow The current epoch
    /// @return The number of seconds between the two epochs
    function _timeBetweenEpochs(CLSpec.CLSpecStruct memory _cls, uint256 _epochPast, uint256 _epochNow)
        internal
        pure
        returns (uint256)
    {
        return (_epochNow - _epochPast) * (_cls.secondsPerSlot * _cls.slotsPerEpoch);
    }
}