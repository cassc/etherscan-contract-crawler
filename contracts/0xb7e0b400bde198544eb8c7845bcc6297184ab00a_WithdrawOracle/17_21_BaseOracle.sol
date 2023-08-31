// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.8;

import "openzeppelin-contracts/utils/math/SafeCast.sol";
import "openzeppelin-contracts-upgradeable/access/OwnableUpgradeable.sol";
import "openzeppelin-contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "openzeppelin-contracts-upgradeable/security/PausableUpgradeable.sol";
import "src/utils/Versioned.sol";
import "src/utils/Dao.sol";
import {IReportAsyncProcessor} from "src/oracles/MultiHashConsensus.sol";

interface IConsensusContract {
    function getIsMember(address addr) external view returns (bool);

    function getCurrentFrame() external view returns (uint256 refSlot, uint256 reportProcessingDeadlineSlot);

    function getChainConfig()
        external
        view
        returns (uint256 slotsPerEpoch, uint256 secondsPerSlot, uint256 genesisTime);

    function getFrameConfig() external view returns (uint256 initialEpoch, uint256 epochsPerFrame);

    function getInitialRefSlot() external view returns (uint256);

    function getReportModuleId(address reportProcessor) external view returns (uint256);
}

abstract contract BaseOracle is
    OwnableUpgradeable,
    UUPSUpgradeable,
    PausableUpgradeable,
    Dao,
    Versioned,
    IReportAsyncProcessor
{
    using SafeCast for uint256;

    error SenderNotAllowed();
    error InvalidAddr();
    error AddressCannotBeZero();
    error AddressCannotBeSame();
    error VersionCannotBeSame();
    error UnexpectedChainConfig();
    error OnlyConsensusContractCanSubmitReport();
    error ModuleIdIsZero();
    error ModuleIdNotEqual();
    error PermissionDenied();
    error InitialRefSlotCannotBeLessThanProcessingOne(uint256 initialRefSlot, uint256 processingRefSlot);
    error RefSlotMustBeGreaterThanProcessingOne(uint256 refSlot, uint256 processingRefSlot);
    error RefSlotCannotDecrease(uint256 refSlot, uint256 prevRefSlot);
    error ProcessingDeadlineMissed(uint256 deadline);
    error RefSlotAlreadyProcessing();
    error UnexpectedRefSlot(uint256 consensusRefSlot, uint256 dataRefSlot);
    error UnexpectedConsensusVersion(uint256 expectedVersion, uint256 receivedVersion);
    error UnexpectedDataHash(bytes32 consensusHash, bytes32 receivedHash);

    event ConsensusHashContractSet(address indexed addr, address indexed prevAddr);
    event ConsensusVersionSet(uint256 indexed version, uint256 indexed prevVersion);
    event WarnProcessingMissed(uint256 indexed refSlot);

    struct ConsensusReport {
        bytes32 hash;
        uint64 refSlot;
        uint64 processingDeadlineTime;
    }

    address internal consensusContract;

    uint256 internal consensusVersion;

    uint256 internal lastProcessingRefSlot;

    ConsensusReport internal consensusReport;

    uint256 public SECONDS_PER_SLOT;

    uint256 public GENESIS_TIME;

    ///
    /// Descendant contract interface
    ///

    /// @notice Initializes the contract storage. Must be called by a descendant
    /// contract as part of its initialization.
    ///
    function __BaseOracle_init(
        uint256 secondsPerSlot,
        uint256 genesisTime,
        address _consensusContract,
        uint256 _consensusVersion,
        uint256 _lastProcessingRefSlot,
        address _dao
    ) internal virtual onlyInitializing {
        __Ownable_init();
        __UUPSUpgradeable_init();
        __Pausable_init();

        if (_dao == address(0)) revert DaoCannotBeZero();
        dao = _dao;
        SECONDS_PER_SLOT = secondsPerSlot;
        GENESIS_TIME = genesisTime;

        _initializeContractVersionTo(1);
        _setConsensusContract(_consensusContract, _lastProcessingRefSlot);
        _setConsensusVersion(_consensusVersion);
        lastProcessingRefSlot = _lastProcessingRefSlot;

        consensusReport.refSlot = uint64(_lastProcessingRefSlot);
    }

    /**
     * @notice In the event of an emergency, stop protocol
     */
    function pause() external onlyDao {
        _pause();
    }

    /**
     * @notice restart protocol
     */
    function unpause() external onlyDao {
        _unpause();
    }

    // set dao vault address
    function setDaoAddress(address _dao) external override onlyOwner {
        if (_dao == address(0)) revert InvalidAddr();
        emit DaoAddressChanged(dao, _dao);
        dao = _dao;
    }

    /// @notice Returns the address of the HashConsensus contract.
    ///
    function getConsensusContract() external view returns (address) {
        return consensusContract;
    }

    /// @notice Sets the address of the HashConsensus contract.
    ///
    function setConsensusContract(address addr) external onlyOwner {
        _setConsensusContract(addr, lastProcessingRefSlot);
    }

    /// @notice Returns the current consensus version expected by the oracle contract.
    ///
    /// Consensus version must change every time consensus rules change, meaning that
    /// an oracle looking at the same reference slot would calculate a different hash.
    ///
    function getConsensusVersion() external view returns (uint256) {
        return consensusVersion;
    }

    /// @notice Sets the consensus version expected by the oracle contract.
    ///
    function setConsensusVersion(uint256 version) external onlyDao {
        _setConsensusVersion(version);
    }

    /// @notice Sets the oracle contract version.
    function updateContractVersion(uint256 version) external onlyDao {
        _updateContractVersion(version);
    }

    ///
    /// Data provider interface
    ///

    /// @notice Returns the last consensus report hash and metadata.
    ///
    function getConsensusReport()
        external
        view
        returns (bytes32 hash, uint256 refSlot, uint256 processingDeadlineTime, bool processingStarted)
    {
        ConsensusReport memory report = consensusReport;
        uint256 processingRefSlot = lastProcessingRefSlot;
        return (
            report.hash,
            report.refSlot,
            report.processingDeadlineTime,
            report.hash != bytes32(0) && report.refSlot == processingRefSlot
        );
    }

    ///
    /// Consensus contract interface
    ///

    /// @notice Called by HashConsensus contract to push a consensus report for processing.
    ///
    /// Note that submitting the report doesn't require the oracle to start processing it
    /// right away, this can happen later. Until the processing is started, HashConsensus is
    /// free to reach consensus on another report for the same reporting frame and submit it
    /// using this same function.
    ///
    function submitConsensusReport(bytes32 reportHash, uint256 refSlot, uint256 deadline, uint256 _moduleId) external {
        uint256 moduleId = IConsensusContract(consensusContract).getReportModuleId(address(this));
        if (moduleId == 0) revert ModuleIdIsZero();
        if (moduleId != _moduleId) revert ModuleIdNotEqual();

        if (_msgSender() != consensusContract) {
            revert OnlyConsensusContractCanSubmitReport();
        }

        uint256 prevSubmittedRefSlot = consensusReport.refSlot;
        if (refSlot < prevSubmittedRefSlot) {
            revert RefSlotCannotDecrease(refSlot, prevSubmittedRefSlot);
        }

        uint256 prevProcessingRefSlot = lastProcessingRefSlot;
        if (refSlot <= prevProcessingRefSlot) {
            revert RefSlotMustBeGreaterThanProcessingOne(refSlot, prevProcessingRefSlot);
        }

        if (refSlot != prevSubmittedRefSlot && prevProcessingRefSlot != prevSubmittedRefSlot) {
            emit WarnProcessingMissed(prevSubmittedRefSlot);
        }

        ConsensusReport memory report = ConsensusReport({
            hash: reportHash,
            refSlot: refSlot.toUint64(),
            processingDeadlineTime: deadline.toUint64()
        });

        consensusReport = report;
        _handleConsensusReport(report, prevSubmittedRefSlot, prevProcessingRefSlot);
    }

    /// @notice Returns the last reference slot for which processing of the report was started.
    ///
    function getLastProcessingRefSlot() external view returns (uint256) {
        return lastProcessingRefSlot;
    }

    /// @notice Returns whether the given address is a member of the oracle committee.
    ///
    function _isConsensusMember(address addr) internal view returns (bool) {
        return IConsensusContract(consensusContract).getIsMember(addr);
    }

    /// @notice Called when oracle gets a new consensus report from the HashConsensus contract.
    ///
    /// Keep in mind that, until you call `_startProcessing`, the oracle committee is free to
    /// reach consensus on another report for the same reporting frame and re-submit it using
    /// this function.
    ///
    function _handleConsensusReport(
        ConsensusReport memory report,
        uint256 prevSubmittedRefSlot,
        uint256 prevProcessingRefSlot
    ) internal virtual;

    function _checkMsgSenderIsAllowedToSubmitData() internal view {
        address sender = _msgSender();
        if (!_isConsensusMember(sender)) {
            revert SenderNotAllowed();
        }
    }

    /// @notice May be called by a descendant contract to check if the received data matches
    /// the currently submitted consensus report, and that processing deadline is not missed.
    /// Reverts otherwise.
    function _checkConsensusData(uint256 refSlot, uint256 _consensusVersion, bytes32 hash, uint256 _moduleId)
        internal
        view
    {
        // If the processing deadline for the current consensus report is missed, an error is reported
        _checkProcessingDeadline();

        uint256 moduleId = IConsensusContract(consensusContract).getReportModuleId(address(this));

        if (moduleId == 0) revert ModuleIdIsZero();
        if (moduleId != _moduleId) revert ModuleIdNotEqual();

        ConsensusReport memory report = consensusReport;
        if (refSlot != report.refSlot) {
            revert UnexpectedRefSlot(report.refSlot, refSlot);
        }

        uint256 expectedConsensusVersion = _consensusVersion;
        if (consensusVersion != expectedConsensusVersion) {
            revert UnexpectedConsensusVersion(expectedConsensusVersion, consensusVersion);
        }

        if (hash != report.hash) {
            revert UnexpectedDataHash(report.hash, hash);
        }
    }

    /// @notice Called by a descendant contract to mark the current consensus report
    /// as being processed. Returns the last ref. slot which processing was started
    /// before the call.
    ///
    /// Before this function is called, the oracle committee is free to reach consensus
    /// on another report for the same reporting frame. After this function is called,
    /// the consensus report for the current frame is guaranteed to remain the same.
    ///
    function _startProcessing() internal returns (uint256) {
        _checkProcessingDeadline();

        ConsensusReport memory report = consensusReport;

        // If the slot has been reported, an error is reported
        uint256 prevProcessingRefSlot = lastProcessingRefSlot;
        if (prevProcessingRefSlot == report.refSlot) {
            revert RefSlotAlreadyProcessing();
        }

        lastProcessingRefSlot = report.refSlot;
        return prevProcessingRefSlot;
    }

    /// @notice Reverts if the processing deadline for the current consensus report is missed.
    ///
    function _checkProcessingDeadline() internal view {
        uint256 deadline = consensusReport.processingDeadlineTime;
        if (_getTime() > deadline) revert ProcessingDeadlineMissed(deadline);
    }

    /// @notice Returns the reference slot for the current frame.
    ///
    function _getCurrentRefSlot() internal view returns (uint256) {
        (uint256 refSlot,) = IConsensusContract(consensusContract).getCurrentFrame();
        return refSlot;
    }

    ///
    /// Implementation & helpers
    ///

    function _setConsensusVersion(uint256 version) internal {
        uint256 prevVersion = consensusVersion;
        if (version == prevVersion) revert VersionCannotBeSame();
        consensusVersion = version;
        emit ConsensusVersionSet(version, prevVersion);
    }

    function _setConsensusContract(address addr, uint256 _lastProcessingRefSlot) internal {
        if (addr == address(0)) revert AddressCannotBeZero();

        address prevAddr = consensusContract;
        if (addr == prevAddr) revert AddressCannotBeSame();

        (, uint256 secondsPerSlot, uint256 genesisTime) = IConsensusContract(addr).getChainConfig();
        if (secondsPerSlot != SECONDS_PER_SLOT || genesisTime != GENESIS_TIME) {
            revert UnexpectedChainConfig();
        }

        uint256 initialRefSlot = IConsensusContract(addr).getInitialRefSlot();
        if (initialRefSlot < _lastProcessingRefSlot) {
            revert InitialRefSlotCannotBeLessThanProcessingOne(initialRefSlot, _lastProcessingRefSlot);
        }

        consensusContract = addr;
        emit ConsensusHashContractSet(addr, prevAddr);
    }

    function _getTime() internal view virtual returns (uint256) {
        return block.timestamp; // solhint-disable-line not-rely-on-time
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}
}