//SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import "./interfaces/IRiver.1.sol";
import "./interfaces/IOracle.1.sol";

import "./Administrable.sol";
import "./Initializable.sol";

import "./state/shared/RiverAddress.sol";

import "./state/oracle/LastEpochId.sol";
import "./state/oracle/OracleMembers.sol";
import "./state/oracle/Quorum.sol";
import "./state/oracle/ReportsPositions.sol";

/// @title Oracle (v1)
/// @author Kiln
/// @notice This contract handles the input from the allowed oracle members. Highly inspired by Lido's implementation.
contract OracleV1 is IOracleV1, Initializable, Administrable {
    modifier onlyAdminOrMember(address _oracleMember) {
        if (msg.sender != _getAdmin() && msg.sender != _oracleMember) {
            revert LibErrors.Unauthorized(msg.sender);
        }
        _;
    }

    /// @inheritdoc IOracleV1
    function initOracleV1(
        address _riverAddress,
        address _administratorAddress,
        uint64 _epochsPerFrame,
        uint64 _slotsPerEpoch,
        uint64 _secondsPerSlot,
        uint64 _genesisTime,
        uint256 _annualAprUpperBound,
        uint256 _relativeLowerBound
    ) external init(0) {
        _setAdmin(_administratorAddress);
        RiverAddress.set(_riverAddress);
        emit SetRiver(_riverAddress);
        CLSpec.set(
            CLSpec.CLSpecStruct({
                epochsPerFrame: _epochsPerFrame,
                slotsPerEpoch: _slotsPerEpoch,
                secondsPerSlot: _secondsPerSlot,
                genesisTime: _genesisTime,
                epochsToAssumedFinality: 0
            })
        );
        emit SetSpec(_epochsPerFrame, _slotsPerEpoch, _secondsPerSlot, _genesisTime);
        ReportBounds.set(
            ReportBounds.ReportBoundsStruct({
                annualAprUpperBound: _annualAprUpperBound,
                relativeLowerBound: _relativeLowerBound
            })
        );
        emit SetBounds(_annualAprUpperBound, _relativeLowerBound);
        Quorum.set(0);
        emit SetQuorum(0);
    }

    /// @inheritdoc IOracleV1
    function initOracleV1_1() external init(1) {
        _clearReports();
    }

    /// @inheritdoc IOracleV1
    function getRiver() external view returns (address) {
        return RiverAddress.get();
    }

    /// @inheritdoc IOracleV1
    function getMemberReportStatus(address _oracleMember) external view returns (bool) {
        int256 memberIndex = OracleMembers.indexOf(_oracleMember);
        return memberIndex != -1 && ReportsPositions.get(uint256(memberIndex));
    }

    /// @inheritdoc IOracleV1
    function getGlobalReportStatus() external view returns (uint256) {
        return ReportsPositions.getRaw();
    }

    /// @inheritdoc IOracleV1
    function getReportVariantsCount() external view returns (uint256) {
        return ReportsVariants.get().length;
    }

    /// @inheritdoc IOracleV1
    function getReportVariantDetails(uint256 _idx)
        external
        view
        returns (ReportsVariants.ReportVariantDetails memory)
    {
        if (ReportsVariants.get().length <= _idx) {
            revert ReportIndexOutOfBounds(_idx, ReportsVariants.get().length);
        }
        return ReportsVariants.get()[_idx];
    }

    /// @inheritdoc IOracleV1
    function getQuorum() external view returns (uint256) {
        return Quorum.get();
    }

    /// @inheritdoc IOracleV1
    function getOracleMembers() external view returns (address[] memory) {
        return OracleMembers.get();
    }

    /// @inheritdoc IOracleV1
    function isMember(address _memberAddress) external view returns (bool) {
        return OracleMembers.indexOf(_memberAddress) >= 0;
    }

    /// @inheritdoc IOracleV1
    function getLastReportedEpochId() external view returns (uint256) {
        return LastEpochId.get();
    }

    /// @inheritdoc IOracleV1
    function addMember(address _newOracleMember, uint256 _newQuorum) external onlyAdmin {
        int256 memberIdx = OracleMembers.indexOf(_newOracleMember);
        if (memberIdx >= 0) {
            revert AddressAlreadyInUse(_newOracleMember);
        }
        OracleMembers.push(_newOracleMember);
        uint256 previousQuorum = Quorum.get();
        _clearReportsAndSetQuorum(_newQuorum, previousQuorum);
        emit AddMember(_newOracleMember);
    }

    /// @inheritdoc IOracleV1
    function removeMember(address _oracleMember, uint256 _newQuorum) external onlyAdmin {
        int256 memberIdx = OracleMembers.indexOf(_oracleMember);
        if (memberIdx < 0) {
            revert LibErrors.InvalidCall();
        }
        OracleMembers.deleteItem(uint256(memberIdx));
        uint256 previousQuorum = Quorum.get();
        _clearReportsAndSetQuorum(_newQuorum, previousQuorum);
        emit RemoveMember(_oracleMember);
    }

    /// @inheritdoc IOracleV1
    function setMember(address _oracleMember, address _newAddress) external onlyAdminOrMember(_oracleMember) {
        LibSanitize._notZeroAddress(_newAddress);
        if (OracleMembers.indexOf(_newAddress) >= 0) {
            revert AddressAlreadyInUse(_newAddress);
        }
        int256 memberIdx = OracleMembers.indexOf(_oracleMember);
        if (memberIdx < 0) {
            revert LibErrors.InvalidCall();
        }
        OracleMembers.set(uint256(memberIdx), _newAddress);
        emit SetMember(_oracleMember, _newAddress);
    }

    /// @inheritdoc IOracleV1
    function setQuorum(uint256 _newQuorum) external onlyAdmin {
        uint256 previousQuorum = Quorum.get();
        if (previousQuorum == _newQuorum) {
            revert LibErrors.InvalidArgument();
        }
        _clearReportsAndSetQuorum(_newQuorum, previousQuorum);
    }

    /// @inheritdoc IOracleV1
    function reportConsensusLayerData(IRiverV1.ConsensusLayerReport calldata _report) external {
        // retrieve member index and revert if not oracle member
        int256 memberIndex = OracleMembers.indexOf(msg.sender);
        if (memberIndex == -1) {
            revert LibErrors.Unauthorized(msg.sender);
        }

        // store last reported epoch to stack
        uint256 lastReportedEpochValue = LastEpochId.get();

        // checks that the report epoch is not too old
        if (_report.epoch < lastReportedEpochValue) {
            revert EpochTooOld(_report.epoch, LastEpochId.get());
        }
        IRiverV1 river = IRiverV1(payable(RiverAddress.get()));
        // checks that the report epoch is not invalid
        if (!river.isValidEpoch(_report.epoch)) {
            revert InvalidEpoch(_report.epoch);
        }
        // if valid and greater than the lastReportedEpoch, we clear the reporting data
        if (_report.epoch > lastReportedEpochValue) {
            _clearReports();
            LastEpochId.set(_report.epoch);
            emit SetLastReportedEpoch(_report.epoch);
        }
        // we retrieve the voting status of the caller, and revert if already voted
        if (ReportsPositions.get(uint256(memberIndex))) {
            revert AlreadyReported(_report.epoch, msg.sender);
        }
        // we register the caller
        ReportsPositions.register(uint256(memberIndex));

        // we compute the variant by hashing the report
        bytes32 variant = _reportChecksum(_report);
        // we retrieve the details for the given variant
        (int256 variantIndex, uint256 variantVotes) = _getReportVariantIndexAndVotes(variant);
        // we retrieve the quorum to stack
        uint256 quorum = Quorum.get();

        emit ReportedConsensusLayerData(msg.sender, variant, _report, variantVotes + 1, quorum);

        // if adding this vote reaches quorum
        if (variantVotes + 1 >= quorum) {
            // we clear the reporting data
            _clearReports();
            // we increment the lastReportedEpoch to force reports to be on the last frame
            LastEpochId.set(_report.epoch + 1);
            // we push the report to river
            river.setConsensusLayerData(_report);
            emit SetLastReportedEpoch(_report.epoch + 1);
        } else if (variantVotes == 0) {
            // if we have no votes for the variant, we create the variant details
            ReportsVariants.push(ReportsVariants.ReportVariantDetails({variant: variant, votes: 1}));
        } else {
            // otherwise we increment the vote
            ReportsVariants.get()[uint256(variantIndex)].votes += 1;
        }
    }

    /// @notice Internal utility to clear all the reports and edit the quorum if a new value is provided
    /// @dev Ensures that the quorum respects invariants
    /// @dev The admin is in charge of providing a proper quorum based on the oracle member count
    /// @dev The quorum value Q should respect the following invariant, where O is oracle member count
    /// @dev (O / 2) + 1 <= Q <= O
    /// @param _newQuorum New quorum value
    /// @param _previousQuorum The old quorum value
    function _clearReportsAndSetQuorum(uint256 _newQuorum, uint256 _previousQuorum) internal {
        uint256 memberCount = OracleMembers.get().length;
        if ((_newQuorum == 0 && memberCount > 0) || _newQuorum > memberCount) {
            revert LibErrors.InvalidArgument();
        }
        _clearReports();
        if (_newQuorum != _previousQuorum) {
            Quorum.set(_newQuorum);
            emit SetQuorum(_newQuorum);
        }
    }

    /// @notice Internal utility to hash and retrieve the variant id of a report
    /// @param _report The reported data structure
    /// @return The report variant
    function _reportChecksum(IRiverV1.ConsensusLayerReport calldata _report) internal pure returns (bytes32) {
        return keccak256(abi.encode(_report));
    }

    /// @notice Internal utility to clear all reporting details
    function _clearReports() internal {
        ReportsVariants.clear();
        ReportsPositions.clear();
        emit ClearedReporting();
    }

    /// @notice Internal utility to retrieve index and vote count for a given variant
    /// @param _variant The variant to lookup
    /// @return The index of the variant, -1 if not found
    /// @return The vote count of the variant
    function _getReportVariantIndexAndVotes(bytes32 _variant) internal view returns (int256, uint256) {
        uint256 reportVariantsLength = ReportsVariants.get().length;
        for (uint256 idx = 0; idx < reportVariantsLength;) {
            if (ReportsVariants.get()[idx].variant == _variant) {
                return (int256(idx), ReportsVariants.get()[idx].votes);
            }
            unchecked {
                ++idx;
            }
        }
        return (-1, 0);
    }

    /// @notice Internal utility to retrieve a casted River interface
    /// @return The casted River interface
    function _river() internal view returns (IRiverV1) {
        return IRiverV1(payable(RiverAddress.get()));
    }
}