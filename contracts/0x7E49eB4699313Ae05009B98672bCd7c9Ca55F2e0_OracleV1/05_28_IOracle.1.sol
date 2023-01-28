//SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import "../state/oracle/CLSpec.sol";
import "../state/oracle/ReportBounds.sol";

/// @title Oracle Interface (v1)
/// @author Kiln
/// @notice This interface exposes methods to handle the input from the allowed oracle members.
/// @notice Highly inspired by Lido's implementation.
interface IOracleV1 {
    /// @notice Consensus Layer data has been reported by an oracle member
    /// @param epochId The epoch of the report
    /// @param newCLBalance The new consensus layer balance
    /// @param newCLValidatorCount The new consensus layer validator count
    /// @param oracleMember The oracle member that reported
    event CLReported(uint256 epochId, uint128 newCLBalance, uint32 newCLValidatorCount, address oracleMember);

    /// @notice The storage quorum value has been changed
    /// @param newQuorum The new quorum value
    event SetQuorum(uint256 newQuorum);

    /// @notice The expected epoch id has been changed
    /// @param epochId The new expected epoch id
    event ExpectedEpochIdUpdated(uint256 epochId);

    /// @notice The report has been submitted to river
    /// @param postTotalEth The new total ETH balance
    /// @param prevTotalEth The previous total ETH balance
    /// @param timeElapsed Time since last report
    /// @param totalShares The new total amount of shares
    event PostTotalShares(uint256 postTotalEth, uint256 prevTotalEth, uint256 timeElapsed, uint256 totalShares);

    /// @notice A member has been added to the oracle member list
    /// @param member The address of the member
    event AddMember(address indexed member);

    /// @notice A member has been removed from the oracle member list
    /// @param member The address of the member
    event RemoveMember(address indexed member);

    /// @notice A member address has been edited
    /// @param oldAddress The previous member address
    /// @param newAddress The new member address
    event SetMember(address indexed oldAddress, address indexed newAddress);

    /// @notice The storage river address value has been changed
    /// @param _river The new river address
    event SetRiver(address _river);

    /// @notice The consensus layer spec has been changed
    /// @param epochsPerFrame The number of epochs inside a frame (225 = 24 hours)
    /// @param slotsPerEpoch The number of slots inside an epoch (32 on ethereum mainnet)
    /// @param secondsPerSlot The time between two slots (12 seconds on ethereum mainnet)
    /// @param genesisTime The timestamp of block #0
    event SetSpec(uint64 epochsPerFrame, uint64 slotsPerEpoch, uint64 secondsPerSlot, uint64 genesisTime);

    /// @notice The report bounds have been changed
    /// @param annualAprUpperBound The maximum allowed apr. 10% means increases in balance extrapolated to a year should not exceed 10%.
    /// @param relativeLowerBound The maximum allowed balance decrease as a relative % of the total balance
    event SetBounds(uint256 annualAprUpperBound, uint256 relativeLowerBound);

    /// @notice The provided epoch is too old compared to the expected epoch id
    /// @param providedEpochId The epoch id provided as input
    /// @param minExpectedEpochId The minimum epoch id expected
    error EpochTooOld(uint256 providedEpochId, uint256 minExpectedEpochId);

    /// @notice The provided epoch is not at the beginning of its frame
    /// @param providedEpochId The epoch id provided as input
    /// @param expectedFrameFirstEpochId The frame first epoch id that was expected
    error NotFrameFirstEpochId(uint256 providedEpochId, uint256 expectedFrameFirstEpochId);

    /// @notice The member already reported on the given epoch id
    /// @param epochId The epoch id provided as input
    /// @param member The oracle member
    error AlreadyReported(uint256 epochId, address member);

    /// @notice The delta in balance is above the allowed upper bound
    /// @param prevTotalEth The previous total balance
    /// @param postTotalEth The new total balance
    /// @param timeElapsed The time since last report
    /// @param annualAprUpperBound The maximum apr allowed
    error TotalValidatorBalanceIncreaseOutOfBound(
        uint256 prevTotalEth, uint256 postTotalEth, uint256 timeElapsed, uint256 annualAprUpperBound
    );

    /// @notice The negative delta in balance is above the allowed lower bound
    /// @param prevTotalEth The previous total balance
    /// @param postTotalEth The new total balance
    /// @param timeElapsed The time since last report
    /// @param relativeLowerBound The maximum relative decrease allowed
    error TotalValidatorBalanceDecreaseOutOfBound(
        uint256 prevTotalEth, uint256 postTotalEth, uint256 timeElapsed, uint256 relativeLowerBound
    );

    /// @notice The address is already in use by an oracle member
    /// @param newAddress The address already in use
    error AddressAlreadyInUse(address newAddress);

    /// @notice Initializes the oracle
    /// @param _river Address of the River contract, able to receive oracle input data after quorum is met
    /// @param _administratorAddress Address able to call administrative methods
    /// @param _epochsPerFrame CL spec parameter. Number of epochs in a frame.
    /// @param _slotsPerEpoch CL spec parameter. Number of slots in one epoch.
    /// @param _secondsPerSlot CL spec parameter. Number of seconds between slots.
    /// @param _genesisTime CL spec parameter. Timestamp of the genesis slot.
    /// @param _annualAprUpperBound CL bound parameter. Maximum apr allowed for balance increase. Delta between updates is extrapolated on a year time frame.
    /// @param _relativeLowerBound CL bound parameter. Maximum relative balance decrease.
    function initOracleV1(
        address _river,
        address _administratorAddress,
        uint64 _epochsPerFrame,
        uint64 _slotsPerEpoch,
        uint64 _secondsPerSlot,
        uint64 _genesisTime,
        uint256 _annualAprUpperBound,
        uint256 _relativeLowerBound
    ) external;

    /// @notice Retrieve River address
    /// @return The address of River
    function getRiver() external view returns (address);

    /// @notice Retrieve the block timestamp
    /// @return The current timestamp from the EVM context
    function getTime() external view returns (uint256);

    /// @notice Retrieve expected epoch id
    /// @return The current expected epoch id
    function getExpectedEpochId() external view returns (uint256);

    /// @notice Retrieve member report status
    /// @param _oracleMember Address of member to check
    /// @return True if member has reported
    function getMemberReportStatus(address _oracleMember) external view returns (bool);

    /// @notice Retrieve member report status
    /// @return The raw report status value
    function getGlobalReportStatus() external view returns (uint256);

    /// @notice Retrieve report variants count
    /// @return The count of report variants
    function getReportVariantsCount() external view returns (uint256);

    /// @notice Retrieve decoded report at provided index
    /// @param _idx Index of report
    /// @return _clBalance The reported consensus layer balance sum of River's validators
    /// @return _clValidators The reported validator count
    /// @return _reportCount The number of similar reports
    function getReportVariant(uint256 _idx)
        external
        view
        returns (uint64 _clBalance, uint32 _clValidators, uint16 _reportCount);

    /// @notice Retrieve the last completed epoch id
    /// @return The last completed epoch id
    function getLastCompletedEpochId() external view returns (uint256);

    /// @notice Retrieve the current epoch id based on block timestamp
    /// @return The current epoch id
    function getCurrentEpochId() external view returns (uint256);

    /// @notice Retrieve the current quorum
    /// @return The current quorum
    function getQuorum() external view returns (uint256);

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

    /// @notice Retrieve the list of oracle members
    /// @return The oracle members
    function getOracleMembers() external view returns (address[] memory);

    /// @notice Returns true if address is member
    /// @dev Performs a naive search, do not call this on-chain, used as an off-chain helper
    /// @param _memberAddress Address of the member
    /// @return True if address is a member
    function isMember(address _memberAddress) external view returns (bool);

    /// @notice Adds new address as oracle member, giving the ability to push cl reports.
    /// @dev Only callable by the adminstrator
    /// @dev Modifying the quorum clears all the reporting data
    /// @param _newOracleMember Address of the new member
    /// @param _newQuorum New quorum value
    function addMember(address _newOracleMember, uint256 _newQuorum) external;

    /// @notice Removes an address from the oracle members.
    /// @dev Only callable by the adminstrator
    /// @dev Modifying the quorum clears all the reporting data
    /// @dev Remaining members that have already voted should vote again for the same frame.
    /// @param _oracleMember Address to remove
    /// @param _newQuorum New quorum value
    function removeMember(address _oracleMember, uint256 _newQuorum) external;

    /// @notice Changes the address of an oracle member
    /// @dev Only callable by the adminitrator
    /// @dev Cannot use an address already in use
    /// @dev This call will clear all the reporting data
    /// @param _oracleMember Address to change
    /// @param _newAddress New address for the member
    function setMember(address _oracleMember, address _newAddress) external;

    /// @notice Edits the cl spec parameters
    /// @dev Only callable by the adminstrator
    /// @param _epochsPerFrame Number of epochs in a frame.
    /// @param _slotsPerEpoch Number of slots in one epoch.
    /// @param _secondsPerSlot Number of seconds between slots.
    /// @param _genesisTime Timestamp of the genesis slot.
    function setCLSpec(uint64 _epochsPerFrame, uint64 _slotsPerEpoch, uint64 _secondsPerSlot, uint64 _genesisTime)
        external;

    /// @notice Edits the cl bounds parameters
    /// @dev Only callable by the adminstrator
    /// @param _annualAprUpperBound Maximum apr allowed for balance increase. Delta between updates is extrapolated on a year time frame.
    /// @param _relativeLowerBound Maximum relative balance decrease.
    function setReportBounds(uint256 _annualAprUpperBound, uint256 _relativeLowerBound) external;

    /// @notice Edits the quorum required to forward cl data to River
    /// @dev Modifying the quorum clears all the reporting data
    /// @param _newQuorum New quorum parameter
    function setQuorum(uint256 _newQuorum) external;

    /// @notice Report cl chain data
    /// @dev Only callable by an oracle member
    /// @dev The epoch id is expected to be >= to the expected epoch id stored in the contract
    /// @dev The epoch id is expected to be the first epoch of its frame
    /// @dev The Consensus Layer Validator count is the amount of running validators managed by River.
    /// @dev Until withdrawals are enabled, this count also takes into account any exited and slashed validator
    /// @dev as funds are still locked on the consensus layer.
    /// @param _epochId Epoch where the balance and validator count has been computed
    /// @param _clValidatorsBalance Total balance of River validators
    /// @param _clValidatorCount Total River validator count
    function reportConsensusLayerData(uint256 _epochId, uint64 _clValidatorsBalance, uint32 _clValidatorCount)
        external;
}