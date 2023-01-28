//SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import "./interfaces/IRiver.1.sol";
import "./interfaces/IOracle.1.sol";

import "./Administrable.sol";
import "./Initializable.sol";

import "./state/shared/RiverAddress.sol";
import "./state/oracle/OracleMembers.sol";
import "./state/oracle/Quorum.sol";
import "./state/oracle/ExpectedEpochId.sol";
import "./state/oracle/LastEpochId.sol";
import "./state/oracle/ReportsPositions.sol";
import "./state/oracle/ReportsVariants.sol";

/// @title Oracle (v1)
/// @author Kiln
/// @notice This contract handles the input from the allowed oracle members. Highly inspired by Lido's implementation.
contract OracleV1 is IOracleV1, Initializable, Administrable {
    /// @notice One Year value
    uint256 internal constant ONE_YEAR = 365 days;

    /// @notice Received ETH input has only 9 decimals
    uint128 internal constant DENOMINATION_OFFSET = 1e9;

    /// @inheritdoc IOracleV1
    function initOracleV1(
        address _river,
        address _administratorAddress,
        uint64 _epochsPerFrame,
        uint64 _slotsPerEpoch,
        uint64 _secondsPerSlot,
        uint64 _genesisTime,
        uint256 _annualAprUpperBound,
        uint256 _relativeLowerBound
    ) external init(0) {
        _setAdmin(_administratorAddress);
        RiverAddress.set(_river);
        emit SetRiver(_river);
        CLSpec.set(
            CLSpec.CLSpecStruct({
                epochsPerFrame: _epochsPerFrame,
                slotsPerEpoch: _slotsPerEpoch,
                secondsPerSlot: _secondsPerSlot,
                genesisTime: _genesisTime
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
    function getRiver() external view returns (address) {
        return RiverAddress.get();
    }

    /// @inheritdoc IOracleV1
    function getTime() external view returns (uint256) {
        return _getTime();
    }

    /// @inheritdoc IOracleV1
    function getExpectedEpochId() external view returns (uint256) {
        return ExpectedEpochId.get();
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
    function getReportVariant(uint256 _idx)
        external
        view
        returns (uint64 _clBalance, uint32 _clValidators, uint16 _reportCount)
    {
        uint256 report = ReportsVariants.get()[_idx];
        (_clBalance, _clValidators) = _decodeReport(report);
        _reportCount = _getReportCount(report);
    }

    /// @inheritdoc IOracleV1
    function getLastCompletedEpochId() external view returns (uint256) {
        return LastEpochId.get();
    }

    /// @inheritdoc IOracleV1
    function getCurrentEpochId() external view returns (uint256) {
        CLSpec.CLSpecStruct memory clSpec = CLSpec.get();
        return _getCurrentEpochId(clSpec);
    }

    /// @inheritdoc IOracleV1
    function getQuorum() external view returns (uint256) {
        return Quorum.get();
    }

    /// @inheritdoc IOracleV1
    function getCLSpec() external view returns (CLSpec.CLSpecStruct memory) {
        return CLSpec.get();
    }

    /// @inheritdoc IOracleV1
    function getCurrentFrame() external view returns (uint256 _startEpochId, uint256 _startTime, uint256 _endTime) {
        CLSpec.CLSpecStruct memory clSpec = CLSpec.get();
        _startEpochId = _getFrameFirstEpochId(_getCurrentEpochId(clSpec), clSpec);
        uint256 secondsPerEpoch = clSpec.secondsPerSlot * clSpec.slotsPerEpoch;
        _startTime = clSpec.genesisTime + _startEpochId * secondsPerEpoch;
        _endTime = _startTime + secondsPerEpoch * clSpec.epochsPerFrame - 1;
    }

    /// @inheritdoc IOracleV1
    function getFrameFirstEpochId(uint256 _epochId) external view returns (uint256) {
        CLSpec.CLSpecStruct memory clSpec = CLSpec.get();
        return _getFrameFirstEpochId(_epochId, clSpec);
    }

    /// @inheritdoc IOracleV1
    function getReportBounds() external view returns (ReportBounds.ReportBoundsStruct memory) {
        return ReportBounds.get();
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
    function setMember(address _oracleMember, address _newAddress) external onlyAdmin {
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
        _clearReports();
    }

    /// @inheritdoc IOracleV1
    function setCLSpec(uint64 _epochsPerFrame, uint64 _slotsPerEpoch, uint64 _secondsPerSlot, uint64 _genesisTime)
        external
        onlyAdmin
    {
        CLSpec.set(
            CLSpec.CLSpecStruct({
                epochsPerFrame: _epochsPerFrame,
                slotsPerEpoch: _slotsPerEpoch,
                secondsPerSlot: _secondsPerSlot,
                genesisTime: _genesisTime
            })
        );
        emit SetSpec(_epochsPerFrame, _slotsPerEpoch, _secondsPerSlot, _genesisTime);
    }

    /// @inheritdoc IOracleV1
    function setReportBounds(uint256 _annualAprUpperBound, uint256 _relativeLowerBound) external onlyAdmin {
        ReportBounds.set(
            ReportBounds.ReportBoundsStruct({
                annualAprUpperBound: _annualAprUpperBound,
                relativeLowerBound: _relativeLowerBound
            })
        );
        emit SetBounds(_annualAprUpperBound, _relativeLowerBound);
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
    function reportConsensusLayerData(uint256 _epochId, uint64 _clValidatorsBalance, uint32 _clValidatorCount)
        external
    {
        int256 memberIndex = OracleMembers.indexOf(msg.sender);
        if (memberIndex == -1) {
            revert LibErrors.Unauthorized(msg.sender);
        }

        CLSpec.CLSpecStruct memory clSpec = CLSpec.get();
        uint256 expectedEpochId = ExpectedEpochId.get();
        if (_epochId < expectedEpochId) {
            revert EpochTooOld(_epochId, expectedEpochId);
        }

        if (_epochId > expectedEpochId) {
            uint256 frameFirstEpochId = _getFrameFirstEpochId(_getCurrentEpochId(clSpec), clSpec);
            if (_epochId != frameFirstEpochId) {
                revert NotFrameFirstEpochId(_epochId, frameFirstEpochId);
            }
            _clearReportsAndUpdateExpectedEpochId(_epochId);
        }

        if (ReportsPositions.get(uint256(memberIndex))) {
            revert AlreadyReported(_epochId, msg.sender);
        }
        ReportsPositions.register(uint256(memberIndex));

        uint128 clBalanceEth1 = DENOMINATION_OFFSET * uint128(_clValidatorsBalance);
        emit CLReported(_epochId, clBalanceEth1, _clValidatorCount, msg.sender);

        uint256 report = _encodeReport(_clValidatorsBalance, _clValidatorCount);
        int256 reportIndex = ReportsVariants.indexOfReport(report);
        uint256 quorum = Quorum.get();

        if (reportIndex >= 0) {
            uint256 registeredReport = ReportsVariants.get()[uint256(reportIndex)];
            if (_getReportCount(registeredReport) + 1 >= quorum) {
                _pushToRiver(_epochId, clBalanceEth1, _clValidatorCount, clSpec);
            } else {
                ReportsVariants.set(uint256(reportIndex), registeredReport + 1);
            }
        } else {
            if (quorum == 1) {
                _pushToRiver(_epochId, clBalanceEth1, _clValidatorCount, clSpec);
            } else {
                ReportsVariants.push(report + 1);
            }
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

    /// @notice Retrieve the block timestamp
    /// @return The block timestamp
    function _getTime() internal view returns (uint256) {
        return block.timestamp; // solhint-disable-line not-rely-on-time
    }

    /// @notice Retrieve the current epoch id based on block timestamp
    /// @param _clSpec CL spec parameters
    /// @return The current epoch id
    function _getCurrentEpochId(CLSpec.CLSpecStruct memory _clSpec) internal view returns (uint256) {
        return (_getTime() - _clSpec.genesisTime) / (_clSpec.slotsPerEpoch * _clSpec.secondsPerSlot);
    }

    /// @notice Retrieve the first epoch id of the frame of the provided epoch id
    /// @param _epochId Epoch id used to get the frame
    /// @param _clSpec CL spec parameters
    /// @return The epoch id at the beginning of the frame
    function _getFrameFirstEpochId(uint256 _epochId, CLSpec.CLSpecStruct memory _clSpec)
        internal
        pure
        returns (uint256)
    {
        return (_epochId / _clSpec.epochsPerFrame) * _clSpec.epochsPerFrame;
    }

    /// @notice Clear reporting data
    /// @param _epochId Next expected epoch id (first epoch of the next frame)
    function _clearReportsAndUpdateExpectedEpochId(uint256 _epochId) internal {
        _clearReports();
        ExpectedEpochId.set(_epochId);
        emit ExpectedEpochIdUpdated(_epochId);
    }

    /// @notice Internal utility to clear the reporting data
    function _clearReports() internal {
        ReportsPositions.clear();
        ReportsVariants.clear();
    }

    /// @notice Encode report into one slot. Last 16 bits are free to use for vote counting.
    /// @param _clBalance Total validator balance
    /// @param _clValidators Total validator count
    /// @return The encoded report value
    function _encodeReport(uint64 _clBalance, uint32 _clValidators) internal pure returns (uint256) {
        return (uint256(_clBalance) << 48) | (uint256(_clValidators) << 16);
    }

    /// @notice Decode report from one slot to two variables, ignoring the last 16 bits
    /// @param _value Encoded report
    function _decodeReport(uint256 _value) internal pure returns (uint64 _clBalance, uint32 _clValidators) {
        _clBalance = uint64(_value >> 48);
        _clValidators = uint32(_value >> 16);
    }

    /// @notice Retrieve the vote count from the encoded report (last 16 bits)
    /// @param _report Encoded report
    /// @return The report count
    function _getReportCount(uint256 _report) internal pure returns (uint16) {
        return uint16(_report);
    }

    /// @notice Compute the max allowed increase based on the previous total balance and the time elapsed
    /// @param _prevTotalEth The previous total balance
    /// @param _timeElapsed The time since last report
    /// @return The maximum increase in balance allowed
    function _maxIncrease(uint256 _prevTotalEth, uint256 _timeElapsed) internal view returns (uint256) {
        uint256 annualAprUpperBound = ReportBounds.get().annualAprUpperBound;
        return (_prevTotalEth * annualAprUpperBound * _timeElapsed) / (LibBasisPoints.BASIS_POINTS_MAX * ONE_YEAR);
    }

    /// @notice Performs sanity checks to prevent an erroneous update to the River system
    /// @param _postTotalEth Total validator balance after update
    /// @param _prevTotalEth Total validator balance before update
    /// @param _timeElapsed Time since last update
    function _sanityChecks(uint256 _postTotalEth, uint256 _prevTotalEth, uint256 _timeElapsed) internal view {
        if (_postTotalEth >= _prevTotalEth) {
            // increase                 = _postTotalPooledEther - _preTotalPooledEther,
            // relativeIncrease         = increase / _preTotalPooledEther,
            // annualRelativeIncrease   = relativeIncrease / (timeElapsed / 365 days),
            // annualRelativeIncreaseBp = annualRelativeIncrease * 10000, in basis points 0.01% (1e-4)
            uint256 annualAprUpperBound = ReportBounds.get().annualAprUpperBound;
            // check that annualRelativeIncreaseBp <= allowedAnnualRelativeIncreaseBp
            if (
                LibBasisPoints.BASIS_POINTS_MAX * ONE_YEAR * (_postTotalEth - _prevTotalEth)
                    > annualAprUpperBound * _prevTotalEth * _timeElapsed
            ) {
                revert TotalValidatorBalanceIncreaseOutOfBound(
                    _prevTotalEth, _postTotalEth, _timeElapsed, annualAprUpperBound
                );
            }
        } else {
            // decrease           = _preTotalPooledEther - _postTotalPooledEther
            // relativeDecrease   = decrease / _preTotalPooledEther
            // relativeDecreaseBp = relativeDecrease * 10000, in basis points 0.01% (1e-4)
            uint256 relativeLowerBound = ReportBounds.get().relativeLowerBound;
            // check that relativeDecreaseBp <= allowedRelativeDecreaseBp
            if (LibBasisPoints.BASIS_POINTS_MAX * (_prevTotalEth - _postTotalEth) > relativeLowerBound * _prevTotalEth)
            {
                revert TotalValidatorBalanceDecreaseOutOfBound(
                    _prevTotalEth, _postTotalEth, _timeElapsed, relativeLowerBound
                );
            }
        }
    }

    /// @notice Push the new cl data to the river system and performs sanity checks
    /// @dev At this point, the maximum increase allowed to the previous total asset balance is computed and
    /// @dev provided to River. It's then up to River to manage how extra funds are injected in the system
    /// @dev and make sure the limit is not crossed. If the _totalBalance is already crossing this limit,
    /// @dev then there is nothing River can do to prevent it.
    /// @dev These extra funds are:
    /// @dev - the execution layer fees
    /// @param _epochId Id of the epoch
    /// @param _totalBalance Total validator balance
    /// @param _validatorCount Total validator count
    /// @param _clSpec CL spec parameters
    function _pushToRiver(
        uint256 _epochId,
        uint128 _totalBalance,
        uint32 _validatorCount,
        CLSpec.CLSpecStruct memory _clSpec
    ) internal {
        _clearReportsAndUpdateExpectedEpochId(_epochId + _clSpec.epochsPerFrame);

        IRiverV1 river = IRiverV1(payable(RiverAddress.get()));
        uint256 prevTotalEth = river.totalUnderlyingSupply();
        uint256 timeElapsed = (_epochId - LastEpochId.get()) * _clSpec.slotsPerEpoch * _clSpec.secondsPerSlot;
        uint256 maxIncrease = _maxIncrease(prevTotalEth, timeElapsed);
        river.setConsensusLayerData(_validatorCount, _totalBalance, bytes32(_epochId), maxIncrease);
        uint256 postTotalEth = river.totalUnderlyingSupply();

        _sanityChecks(postTotalEth, prevTotalEth, timeElapsed);
        LastEpochId.set(_epochId);

        emit PostTotalShares(postTotalEth, prevTotalEth, timeElapsed, river.totalSupply());
    }
}