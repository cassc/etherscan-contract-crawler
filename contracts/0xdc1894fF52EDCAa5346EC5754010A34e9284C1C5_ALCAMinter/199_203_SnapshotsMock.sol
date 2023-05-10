// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

import "contracts/interfaces/ISnapshots.sol";
import "contracts/interfaces/IValidatorPool.sol";
import "contracts/utils/auth/ImmutableFactory.sol";
import "contracts/utils/auth/ImmutableValidatorPool.sol";
import "contracts/utils/auth/ImmutableDynamics.sol";
import "contracts/libraries/parsers/BClaimsParserLibrary.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "contracts/interfaces/IDynamics.sol";

contract SnapshotsMock is Initializable, ImmutableValidatorPool, ISnapshots, ImmutableDynamics {
    error onlyAdminAllowed();
    uint32 internal _epoch;
    uint32 internal _epochLength;

    // after how many eth blocks of not having a snapshot will we start allowing more validators to
    // make it
    uint32 internal _snapshotDesperationDelay;
    // how quickly more validators will be allowed to make a snapshot, once
    // _snapshotDesperationDelay has passed
    uint32 internal _snapshotDesperationFactor;

    mapping(uint256 => Snapshot) internal _snapshots;

    address internal _admin;
    uint256 internal immutable _chainId;
    uint256 internal _minimumIntervalBetweenSnapshots;

    modifier onlyAdmin() {
        if (msg.sender != _admin) {
            revert onlyAdminAllowed();
        }
        _;
    }

    constructor(
        uint32 chainID_,
        uint32 epochLength_
    ) ImmutableFactory(msg.sender) ImmutableValidatorPool() {
        _admin = msg.sender;
        _chainId = chainID_;
        _epochLength = epochLength_;
    }

    function initialize(uint32 desperationDelay_, uint32 desperationFactor_) public initializer {
        // considering that in optimum conditions 1 Sidechain block is at every 3 seconds and 1 block at
        // ethereum is approx at 13 seconds
        _minimumIntervalBetweenSnapshots = 0;
        _snapshotDesperationDelay = desperationDelay_;
        _snapshotDesperationFactor = desperationFactor_;
    }

    function setEpochLength(uint32 epochLength_) public {
        _epochLength = epochLength_;
    }

    function setSnapshotDesperationDelay(uint32 desperationDelay_) public onlyAdmin {
        _snapshotDesperationDelay = desperationDelay_;
    }

    function setSnapshotDesperationFactor(uint32 desperationFactor_) public onlyAdmin {
        _snapshotDesperationFactor = desperationFactor_;
    }

    function setMinimumIntervalBetweenSnapshots(uint32 minimumIntervalBetweenSnapshots_) public {
        _minimumIntervalBetweenSnapshots = minimumIntervalBetweenSnapshots_;
    }

    function snapshot(
        bytes calldata groupSignature_,
        bytes calldata bClaims_
    ) public returns (bool) {
        bool isSafeToProceedConsensus = true;
        if (IValidatorPool(_validatorPoolAddress()).isMaintenanceScheduled()) {
            isSafeToProceedConsensus = false;
            IValidatorPool(_validatorPoolAddress()).pauseConsensus();
        }
        // dummy to silence compiling warnings
        groupSignature_;
        bClaims_;
        BClaimsParserLibrary.BClaims memory blockClaims = BClaimsParserLibrary.BClaims(
            0,
            0,
            0,
            0x00,
            0x00,
            0x00,
            0x00
        );
        _epoch++;
        _snapshots[_epoch] = Snapshot(block.number, blockClaims);
        IDynamics(_dynamicsAddress()).updateHead(_epoch);

        return true;
    }

    function snapshotWithValidData(
        bytes calldata groupSignature_,
        bytes calldata bClaims_
    ) public returns (bool) {
        bool isSafeToProceedConsensus = true;
        if (IValidatorPool(_validatorPoolAddress()).isMaintenanceScheduled()) {
            isSafeToProceedConsensus = false;
            IValidatorPool(_validatorPoolAddress()).pauseConsensus();
        }
        groupSignature_;
        BClaimsParserLibrary.BClaims memory blockClaims = BClaimsParserLibrary.extractBClaims(
            bClaims_
        );

        _epoch++;
        _snapshots[_epoch] = Snapshot(block.number, blockClaims);
        IDynamics(_dynamicsAddress()).updateHead(_epoch);

        return true;
    }

    function setCommittedHeightFromLatestSnapshot(uint256 height_) public returns (uint256) {
        _snapshots[_epoch].committedAt = height_;
        return height_;
    }

    function getEpochFromHeight(uint256 height) public view returns (uint256) {
        if (height <= _epochLength) {
            return 1;
        }
        if (height % _epochLength == 0) {
            return height / _epochLength;
        }
        return (height / _epochLength) + 1;
    }

    function getSnapshotDesperationDelay() public view returns (uint256) {
        return _snapshotDesperationDelay;
    }

    function getSnapshotDesperationFactor() public view returns (uint256) {
        return _snapshotDesperationFactor;
    }

    function getMinimumIntervalBetweenSnapshots() public view returns (uint256) {
        return _minimumIntervalBetweenSnapshots;
    }

    function getChainId() public view returns (uint256) {
        return _chainId;
    }

    function getEpoch() public view returns (uint256) {
        return _epoch;
    }

    function getEpochLength() public view returns (uint256) {
        return _epochLength;
    }

    function getChainIdFromSnapshot(uint256 epoch_) public view returns (uint256) {
        return _snapshots[epoch_].blockClaims.chainId;
    }

    function getChainIdFromLatestSnapshot() public view returns (uint256) {
        return _snapshots[_epoch].blockClaims.chainId;
    }

    function getBlockClaimsFromSnapshot(
        uint256 epoch_
    ) public view returns (BClaimsParserLibrary.BClaims memory) {
        return _snapshots[epoch_].blockClaims;
    }

    function getBlockClaimsFromLatestSnapshot()
        public
        view
        returns (BClaimsParserLibrary.BClaims memory)
    {
        return _snapshots[_epoch].blockClaims;
    }

    function getCommittedHeightFromSnapshot(uint256 epoch_) public view returns (uint256) {
        return _snapshots[epoch_].committedAt;
    }

    function getCommittedHeightFromLatestSnapshot() public view returns (uint256) {
        return _snapshots[_epoch].committedAt;
    }

    function getAliceNetHeightFromSnapshot(uint256 epoch_) public view returns (uint256) {
        return _snapshots[epoch_].blockClaims.height;
    }

    function getAliceNetHeightFromLatestSnapshot() public view returns (uint256) {
        return _snapshots[_epoch].blockClaims.height;
    }

    function getSnapshot(uint256 epoch_) public view returns (Snapshot memory) {
        return _snapshots[epoch_];
    }

    function getLatestSnapshot() public view returns (Snapshot memory) {
        return _snapshots[_epoch];
    }

    function isMock() public pure returns (bool) {
        return true;
    }

    function migrateSnapshots(
        bytes[] memory groupSignature_,
        bytes[] memory bClaims_
    ) public pure returns (bool) {
        groupSignature_;
        bClaims_;
        return true;
    }

    function mayValidatorSnapshot(
        uint256 numValidators,
        uint256 myIdx,
        uint256 blocksSinceDesperation,
        bytes32 blsig,
        uint256 desperationFactor
    ) public pure returns (bool) {
        numValidators;
        myIdx;
        blocksSinceDesperation;
        blsig;
        desperationFactor;
        return true;
    }

    function checkBClaimsSignature(
        bytes calldata groupSignature_,
        bytes calldata bClaims_
    ) public pure returns (bool) {
        groupSignature_;
        bClaims_;
        return true;
    }

    function isValidatorElectedToPerformSnapshot(
        address validator,
        uint256 lastSnapshotCommittedAt,
        bytes32 groupSignatureHash
    ) public pure returns (bool) {
        validator;
        lastSnapshotCommittedAt;
        groupSignatureHash;
        return true;
    }
}