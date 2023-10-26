//SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import "./IRiver.1.sol";
import "../state/oracle/ReportsVariants.sol";

/// @title Oracle Interface (v1)
/// @author Kiln
/// @notice This interface exposes methods to handle the input from the allowed oracle members.
/// @notice Highly inspired by Lido's implementation.
interface IOracleV1 {
    /// @notice The storage quorum value has been changed
    /// @param newQuorum The new quorum value
    event SetQuorum(uint256 newQuorum);

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

    /// @notice An oracle member performed a report
    /// @param member The oracle member
    /// @param variant The variant of the report
    /// @param report The raw report structure
    /// @param voteCount The vote count
    event ReportedConsensusLayerData(
        address indexed member,
        bytes32 indexed variant,
        IRiverV1.ConsensusLayerReport report,
        uint256 voteCount,
        uint256 quorum
    );

    /// @notice The last reported epoch has changed
    event SetLastReportedEpoch(uint256 lastReportedEpoch);

    /// @notice Cleared reporting data
    event ClearedReporting();

    /// @notice The provided epoch is too old compared to the expected epoch id
    /// @param providedEpochId The epoch id provided as input
    /// @param minExpectedEpochId The minimum epoch id expected
    error EpochTooOld(uint256 providedEpochId, uint256 minExpectedEpochId);

    /// @notice Thrown when the reported epoch is invalid
    /// @param epoch The invalid epoch
    error InvalidEpoch(uint256 epoch);

    /// @notice Thrown when the report indexs fetched is out of bounds
    /// @param index Requested index
    /// @param length Size of the variant array
    error ReportIndexOutOfBounds(uint256 index, uint256 length);

    /// @notice The member already reported on the given epoch id
    /// @param epochId The epoch id provided as input
    /// @param member The oracle member
    error AlreadyReported(uint256 epochId, address member);

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

    /// @notice Initializes the oracle
    function initOracleV1_1() external;

    /// @notice Retrieve River address
    /// @return The address of River
    function getRiver() external view returns (address);

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

    /// @notice Retrieve the details of a report variant
    /// @param _idx The index of the report variant
    /// @return The report variant details
    function getReportVariantDetails(uint256 _idx)
        external
        view
        returns (ReportsVariants.ReportVariantDetails memory);

    /// @notice Retrieve the current quorum
    /// @return The current quorum
    function getQuorum() external view returns (uint256);

    /// @notice Retrieve the list of oracle members
    /// @return The oracle members
    function getOracleMembers() external view returns (address[] memory);

    /// @notice Returns true if address is member
    /// @dev Performs a naive search, do not call this on-chain, used as an off-chain helper
    /// @param _memberAddress Address of the member
    /// @return True if address is a member
    function isMember(address _memberAddress) external view returns (bool);

    /// @notice Retrieve the last reported epoch id
    /// @dev The Oracle contracts expects reports on an epoch id >= that the returned value
    /// @return The last reported epoch id
    function getLastReportedEpochId() external view returns (uint256);

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
    /// @dev Only callable by the adminitrator or the member itself
    /// @dev Cannot use an address already in use
    /// @param _oracleMember Address to change
    /// @param _newAddress New address for the member
    function setMember(address _oracleMember, address _newAddress) external;

    /// @notice Edits the quorum required to forward cl data to River
    /// @dev Modifying the quorum clears all the reporting data
    /// @param _newQuorum New quorum parameter
    function setQuorum(uint256 _newQuorum) external;

    /// @notice Submit a report as an oracle member
    /// @param _report The report structure
    function reportConsensusLayerData(IRiverV1.ConsensusLayerReport calldata _report) external;
}