//SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import "../../state/river/CLSpec.sol";
import "../../state/river/ReportBounds.sol";

/// @title Oracle Manager (v1)
/// @author Kiln
/// @notice This interface exposes methods to handle the inputs provided by the oracle
interface IOracleManagerV1 {
    /// @notice The stored oracle address changed
    /// @param oracleAddress The new oracle address
    event SetOracle(address indexed oracleAddress);

    /// @notice The consensus layer data provided by the oracle has been updated
    /// @param validatorCount The new count of validators running on the consensus layer
    /// @param validatorTotalBalance The new total balance sum of all validators
    /// @param roundId Round identifier
    event ConsensusLayerDataUpdate(uint256 validatorCount, uint256 validatorTotalBalance, bytes32 roundId);

    /// @notice The Consensus Layer Spec is changed
    /// @param epochsPerFrame The number of epochs inside a frame
    /// @param slotsPerEpoch The number of slots inside an epoch
    /// @param secondsPerSlot The number of seconds inside a slot
    /// @param genesisTime The genesis timestamp
    /// @param epochsToAssumedFinality The number of epochs before an epoch is considered final
    event SetSpec(
        uint64 epochsPerFrame,
        uint64 slotsPerEpoch,
        uint64 secondsPerSlot,
        uint64 genesisTime,
        uint64 epochsToAssumedFinality
    );

    /// @notice The Report Bounds are changed
    /// @param annualAprUpperBound The reporting upper bound
    /// @param relativeLowerBound The reporting lower bound
    event SetBounds(uint256 annualAprUpperBound, uint256 relativeLowerBound);

    /// @notice The provided report has beend processed
    /// @param report The report that was provided
    /// @param trace The trace structure providing more insights on internals
    event ProcessedConsensusLayerReport(
        IOracleManagerV1.ConsensusLayerReport report, ConsensusLayerDataReportingTrace trace
    );

    /// @notice The reported validator count is invalid
    /// @param providedValidatorCount The received validator count value
    /// @param depositedValidatorCount The number of deposits performed by the system
    /// @param lastReportedValidatorCount The last reported validator count
    error InvalidValidatorCountReport(
        uint256 providedValidatorCount, uint256 depositedValidatorCount, uint256 lastReportedValidatorCount
    );

    /// @notice Thrown when an invalid epoch was reported
    /// @param epoch Invalid epoch
    error InvalidEpoch(uint256 epoch);

    /// @notice The balance increase is higher than the maximum allowed by the upper bound
    /// @param prevTotalEthIncludingExited The previous total balance, including all exited balance
    /// @param postTotalEthIncludingExited The post-report total balance, including all exited balance
    /// @param timeElapsed The time in seconds since last report
    /// @param annualAprUpperBound The upper bound value that was used
    error TotalValidatorBalanceIncreaseOutOfBound(
        uint256 prevTotalEthIncludingExited,
        uint256 postTotalEthIncludingExited,
        uint256 timeElapsed,
        uint256 annualAprUpperBound
    );

    /// @notice The balance decrease is higher than the maximum allowed by the lower bound
    /// @param prevTotalEthIncludingExited The previous total balance, including all exited balance
    /// @param postTotalEthIncludingExited The post-report total balance, including all exited balance
    /// @param timeElapsed The time in seconds since last report
    /// @param relativeLowerBound The lower bound value that was used
    error TotalValidatorBalanceDecreaseOutOfBound(
        uint256 prevTotalEthIncludingExited,
        uint256 postTotalEthIncludingExited,
        uint256 timeElapsed,
        uint256 relativeLowerBound
    );

    /// @notice The total exited balance decreased
    /// @param currentValidatorsExitedBalance The current exited balance
    /// @param newValidatorsExitedBalance The new exited balance
    error InvalidDecreasingValidatorsExitedBalance(
        uint256 currentValidatorsExitedBalance, uint256 newValidatorsExitedBalance
    );

    /// @notice The total skimmed balance decreased
    /// @param currentValidatorsSkimmedBalance The current exited balance
    /// @param newValidatorsSkimmedBalance The new exited balance
    error InvalidDecreasingValidatorsSkimmedBalance(
        uint256 currentValidatorsSkimmedBalance, uint256 newValidatorsSkimmedBalance
    );

    /// @notice Trace structure emitted via logs during reporting
    struct ConsensusLayerDataReportingTrace {
        uint256 rewards;
        uint256 pulledELFees;
        uint256 pulledRedeemManagerExceedingEthBuffer;
        uint256 pulledCoverageFunds;
    }

    /// @notice The format of the oracle report
    struct ConsensusLayerReport {
        // this is the epoch at which the report was performed
        // data should be fetched up to the state of this epoch by the oracles
        uint256 epoch;
        // the sum of all the validator balances on the consensus layer
        // when a validator enters the exit queue, the validator is considered stopped, its balance is accounted in both validatorsExitingBalance and validatorsBalance
        // when a validator leaves the exit queue and the funds are sweeped onto the execution layer, the balance is only accounted in validatorsExitedBalance and not in validatorsBalance
        // this value can decrease between reports
        uint256 validatorsBalance;
        // the sum of all the skimmings performed on the validators
        // these values can be found in the execution layer block bodies under the withdrawals field
        // a withdrawal is considered skimming if
        // - the epoch at which it happened is < validator.withdrawableEpoch
        // - the epoch at which it happened is >= validator.withdrawableEpoch and in that case we only account for what would be above 32 eth as skimming
        // this value cannot decrease over reports
        uint256 validatorsSkimmedBalance;
        // the sum of all the exits performed on the validators
        // these values can be found in the execution layer block bodies under the withdrawals field
        // a withdrawal is considered exit if
        // - the epoch at which it happened is >= validator.withdrawableEpoch and in that case we only account for what would be <= 32 eth as exit
        // this value cannot decrease over reports
        uint256 validatorsExitedBalance;
        // the sum of all the exiting balance, which is all the validators on their way to get sweeped and exited
        // this includes voluntary exits and slashings
        // this value can decrease between reports
        uint256 validatorsExitingBalance;
        // the count of activated validators
        // even validators that are exited are still accounted
        // this value cannot decrease over reports
        uint32 validatorsCount;
        // an array containing the count of stopped validators per operator
        // the first element of the array is the sum of all stopped validators
        // then index 1 would be operator 0
        // these values cannot decrease over reports
        uint32[] stoppedValidatorCountPerOperator;
        // flag enabled by the oracles when the buffer rebalancing is activated
        // the activation logic is written in the oracle specification and all oracle members must agree on the activation
        // when active, the eth in the deposit buffer can be used to pay for exits in the redeem manager
        bool rebalanceDepositToRedeemMode;
        // flag enabled by the oracles when the slashing containment is activated
        // the activation logic is written in the oracle specification and all oracle members must agree on the activation
        // This flag is activated when a pre-defined threshold of slashed validators in our set of validators is reached
        // This flag is deactivated when a bottom threshold is met, this means that when we reach the upper threshold and activate the flag, we will deactivate it when we reach the bottom threshold and not before
        // when active, no more validator exits can be requested by the protocol
        bool slashingContainmentMode;
    }

    /// @notice The format of the oracle report in storage
    /// @notice These fields have the exact same function as the ones in ConsensusLayerReport, but this struct is optimized for storage
    struct StoredConsensusLayerReport {
        uint256 epoch;
        uint256 validatorsBalance;
        uint256 validatorsSkimmedBalance;
        uint256 validatorsExitedBalance;
        uint256 validatorsExitingBalance;
        uint32 validatorsCount;
        bool rebalanceDepositToRedeemMode;
        bool slashingContainmentMode;
    }

    /// @notice Get oracle address
    /// @return The oracle address
    function getOracle() external view returns (address);

    /// @notice Get CL validator total balance
    /// @return The CL Validator total balance
    function getCLValidatorTotalBalance() external view returns (uint256);

    /// @notice Get CL validator count (the amount of validator reported by the oracles)
    /// @return The CL validator count
    function getCLValidatorCount() external view returns (uint256);

    /// @notice Verifies if the provided epoch is valid
    /// @param epoch The epoch to lookup
    /// @return True if valid
    function isValidEpoch(uint256 epoch) external view returns (bool);

    /// @notice Retrieve the block timestamp
    /// @return The current timestamp from the EVM context
    function getTime() external view returns (uint256);

    /// @notice Retrieve expected epoch id
    /// @return The current expected epoch id
    function getExpectedEpochId() external view returns (uint256);

    /// @notice Retrieve the last completed epoch id
    /// @return The last completed epoch id
    function getLastCompletedEpochId() external view returns (uint256);

    /// @notice Retrieve the current epoch id based on block timestamp
    /// @return The current epoch id
    function getCurrentEpochId() external view returns (uint256);

    /// @notice Retrieve the current cl spec
    /// @return The Consensus Layer Specification
    function getCLSpec() external view returns (CLSpec.CLSpecStruct memory);

    /// @notice Retrieve the current frame details
    /// @return _startEpochId The epoch at the beginning of the frame
    /// @return _startTime The timestamp of the beginning of the frame in seconds
    /// @return _endTime The timestamp of the end of the frame in seconds
    function getCurrentFrame() external view returns (uint256 _startEpochId, uint256 _startTime, uint256 _endTime);

    /// @notice Retrieve the first epoch id of the frame of the provided epoch id
    /// @param _epochId Epoch id used to get the frame
    /// @return The first epoch id of the frame containing the given epoch id
    function getFrameFirstEpochId(uint256 _epochId) external view returns (uint256);

    /// @notice Retrieve the report bounds
    /// @return The report bounds
    function getReportBounds() external view returns (ReportBounds.ReportBoundsStruct memory);

    /// @notice Retrieve the last consensus layer report
    /// @return The stored consensus layer report
    function getLastConsensusLayerReport() external view returns (IOracleManagerV1.StoredConsensusLayerReport memory);

    /// @notice Set the oracle address
    /// @param _oracleAddress Address of the oracle
    function setOracle(address _oracleAddress) external;

    /// @notice Set the consensus layer spec
    /// @param _newValue The new consensus layer spec value
    function setCLSpec(CLSpec.CLSpecStruct calldata _newValue) external;

    /// @notice Set the report bounds
    /// @param _newValue The new report bounds value
    function setReportBounds(ReportBounds.ReportBoundsStruct calldata _newValue) external;

    /// @notice Performs all the reporting logics
    /// @param _report The consensus layer report structure
    function setConsensusLayerData(ConsensusLayerReport calldata _report) external;
}