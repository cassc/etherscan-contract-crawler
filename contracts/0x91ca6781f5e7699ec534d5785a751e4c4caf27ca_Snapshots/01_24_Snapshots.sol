// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

import "contracts/interfaces/ISnapshots.sol";
import "contracts/interfaces/IValidatorPool.sol";
import "contracts/interfaces/IETHDKG.sol";
import "contracts/interfaces/IDynamics.sol";
import "contracts/libraries/parsers/RCertParserLibrary.sol";
import "contracts/libraries/parsers/BClaimsParserLibrary.sol";
import "contracts/libraries/math/CryptoLibrary.sol";
import "contracts/libraries/snapshots/SnapshotsStorage.sol";
import "contracts/utils/DeterministicAddress.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "contracts/libraries/errors/SnapshotsErrors.sol";

/// @custom:salt Snapshots
/// @custom:deploy-type deployUpgradeable
contract Snapshots is Initializable, SnapshotsStorage, ISnapshots {
    using EpochLib for Epoch;

    constructor(uint256 chainID_, uint256 epochLength_) SnapshotsStorage(chainID_, epochLength_) {}

    function initialize(uint32 desperationDelay_, uint32 desperationFactor_)
        public
        onlyFactory
        initializer
    {
        // considering that in optimum conditions 1 Sidechain block is at every 3 seconds and 1 block at
        // ethereum is approx at 13 seconds
        _minimumIntervalBetweenSnapshots = uint32(_epochLength / 4);
        _snapshotDesperationDelay = desperationDelay_;
        _snapshotDesperationFactor = desperationFactor_;
    }

    // todo: compute this value using the dynamic system and the alicenet block times.
    function setSnapshotDesperationDelay(uint32 desperationDelay_) public onlyFactory {
        _snapshotDesperationDelay = desperationDelay_;
    }

    function setSnapshotDesperationFactor(uint32 desperationFactor_) public onlyFactory {
        _snapshotDesperationFactor = desperationFactor_;
    }

    function setMinimumIntervalBetweenSnapshots(uint32 minimumIntervalBetweenSnapshots_)
        public
        onlyFactory
    {
        _minimumIntervalBetweenSnapshots = minimumIntervalBetweenSnapshots_;
    }

    /// @notice Saves next snapshot
    /// @param groupSignature_ The group signature used to sign the snapshots' block claims
    /// @param bClaims_ The claims being made about given block
    /// @return returns true if the execution succeeded
    function snapshot(bytes calldata groupSignature_, bytes calldata bClaims_)
        public
        returns (bool)
    {
        if (!IValidatorPool(_validatorPoolAddress()).isValidator(msg.sender)) {
            revert SnapshotsErrors.OnlyValidatorsAllowed(msg.sender);
        }
        if (!IValidatorPool(_validatorPoolAddress()).isConsensusRunning()) {
            revert SnapshotsErrors.ConsensusNotRunning();
        }

        uint32 epoch = _epochRegister().get() + 1;
        BClaimsParserLibrary.BClaims memory blockClaims = _parseAndValidateBClaims(epoch, bClaims_);

        uint256 lastSnapshotCommittedAt = _getLatestSnapshot().committedAt;
        _checkSnapshotMinimumInterval(lastSnapshotCommittedAt);

        _isValidatorElectedToPerformSnapshot(
            msg.sender,
            lastSnapshotCommittedAt,
            keccak256(groupSignature_)
        );

        (uint256[4] memory masterPublicKey, uint256[2] memory signature) = _checkBClaimsSignature(
            groupSignature_,
            bClaims_
        );

        bool isSafeToProceedConsensus = true;
        if (IValidatorPool(_validatorPoolAddress()).isMaintenanceScheduled()) {
            isSafeToProceedConsensus = false;
            IValidatorPool(_validatorPoolAddress()).pauseConsensus();
        }

        _setSnapshot(Snapshot(block.number, blockClaims));
        _epochRegister().set(epoch);

        emit SnapshotTaken(
            _chainId,
            epoch,
            blockClaims.height,
            msg.sender,
            isSafeToProceedConsensus,
            masterPublicKey,
            signature,
            blockClaims
        );

        // check and update the latest dynamics values in case the scheduled changes
        // start to become valid on this epoch
        IDynamics(_dynamicsAddress()).updateHead(epoch);

        return isSafeToProceedConsensus;
    }

    /// @notice Migrates a set of snapshots to bootstrap the side chain.
    /// @param groupSignature_ Array of group signature used to sign the snapshots' block claims
    /// @param bClaims_ Array of BClaims being migrated as snapshots
    /// @return returns true if the execution succeeded
    function migrateSnapshots(bytes[] memory groupSignature_, bytes[] memory bClaims_)
        public
        onlyFactory
        returns (bool)
    {
        Epoch storage epochReg = _epochRegister();
        {
            if (epochReg.get() != 0) {
                revert SnapshotsErrors.MigrationNotAllowedAtCurrentEpoch();
            }
            if (groupSignature_.length != bClaims_.length || groupSignature_.length == 0) {
                revert SnapshotsErrors.MigrationInputDataMismatch(
                    groupSignature_.length,
                    bClaims_.length
                );
            }
        }
        uint256 epoch;
        for (uint256 i = 0; i < bClaims_.length; i++) {
            BClaimsParserLibrary.BClaims memory blockClaims = BClaimsParserLibrary.extractBClaims(
                bClaims_[i]
            );
            if (blockClaims.height % _epochLength != 0) {
                revert SnapshotsErrors.BlockHeightNotMultipleOfEpochLength(
                    blockClaims.height,
                    _epochLength
                );
            }
            (
                uint256[4] memory masterPublicKey,
                uint256[2] memory signature
            ) = _checkBClaimsSignature(groupSignature_[i], bClaims_[i]);
            epoch = getEpochFromHeight(blockClaims.height);
            _setSnapshot(Snapshot(block.number, blockClaims));
            emit SnapshotTaken(
                _chainId,
                epoch,
                blockClaims.height,
                msg.sender,
                true,
                masterPublicKey,
                signature,
                blockClaims
            );
        }
        epochReg.set(uint32(epoch));
        return true;
    }

    function getSnapshotDesperationFactor() public view returns (uint256) {
        return _snapshotDesperationFactor;
    }

    function getSnapshotDesperationDelay() public view returns (uint256) {
        return _snapshotDesperationDelay;
    }

    function getMinimumIntervalBetweenSnapshots() public view returns (uint256) {
        return _minimumIntervalBetweenSnapshots;
    }

    function getChainId() public view returns (uint256) {
        return _chainId;
    }

    function getEpoch() public view returns (uint256) {
        return _epochRegister().get();
    }

    function getEpochLength() public view returns (uint256) {
        return _epochLength;
    }

    function getChainIdFromSnapshot(uint256 epoch_) public view returns (uint256) {
        return _getSnapshot(uint32(epoch_)).blockClaims.chainId;
    }

    function getChainIdFromLatestSnapshot() public view returns (uint256) {
        return _getLatestSnapshot().blockClaims.chainId;
    }

    function getBlockClaimsFromSnapshot(uint256 epoch_)
        public
        view
        returns (BClaimsParserLibrary.BClaims memory)
    {
        return _getSnapshot(uint32(epoch_)).blockClaims;
    }

    function getBlockClaimsFromLatestSnapshot()
        public
        view
        returns (BClaimsParserLibrary.BClaims memory)
    {
        return _getLatestSnapshot().blockClaims;
    }

    function getCommittedHeightFromSnapshot(uint256 epoch_) public view returns (uint256) {
        return _getSnapshot(uint32(epoch_)).committedAt;
    }

    function getCommittedHeightFromLatestSnapshot() public view returns (uint256) {
        return _getLatestSnapshot().committedAt;
    }

    function getAliceNetHeightFromSnapshot(uint256 epoch_) public view returns (uint256) {
        return _getSnapshot(uint32(epoch_)).blockClaims.height;
    }

    function getAliceNetHeightFromLatestSnapshot() public view returns (uint256) {
        return _getLatestSnapshot().blockClaims.height;
    }

    function getSnapshot(uint256 epoch_) public view returns (Snapshot memory) {
        return _getSnapshot(uint32(epoch_));
    }

    function getLatestSnapshot() public view returns (Snapshot memory) {
        return _getLatestSnapshot();
    }

    function getEpochFromHeight(uint256 height) public view returns (uint256) {
        return _getEpochFromHeight(uint32(height));
    }

    function checkBClaimsSignature(bytes calldata groupSignature_, bytes calldata bClaims_)
        public
        view
        returns (bool)
    {
        // if the function does not revert, it means that the signature is valid
        _checkBClaimsSignature(groupSignature_, bClaims_);
        return true;
    }

    function isValidatorElectedToPerformSnapshot(
        address validator,
        uint256 lastSnapshotCommittedAt,
        bytes32 groupSignatureHash
    ) public view returns (bool) {
        // if the function does not revert, it means that the validator is the selected to perform the snapshot
        _isValidatorElectedToPerformSnapshot(
            validator,
            lastSnapshotCommittedAt,
            groupSignatureHash
        );
        return true;
    }

    function mayValidatorSnapshot(
        uint256 numValidators,
        uint256 myIdx,
        uint256 blocksSinceDesperation,
        bytes32 randomSeed,
        uint256 desperationFactor
    ) public pure returns (bool) {
        (bool isValidatorElected, , ) = _mayValidatorSnapshot(
            numValidators,
            myIdx,
            blocksSinceDesperation,
            randomSeed,
            desperationFactor
        );
        return isValidatorElected;
    }

    function _isValidatorElectedToPerformSnapshot(
        address validator,
        uint256 lastSnapshotCommittedAt,
        bytes32 groupSignatureHash
    ) internal view {
        // Check if sender is the elected validator allowed to make the snapshot
        uint256 validatorIndex = IETHDKG(_ethdkgAddress()).getLastRoundParticipantIndex(validator);
        uint256 ethBlocksSinceLastSnapshot = block.number - lastSnapshotCommittedAt;
        uint256 desperationDelay = _snapshotDesperationDelay;
        uint256 blocksSinceDesperation = ethBlocksSinceLastSnapshot >= desperationDelay
            ? ethBlocksSinceLastSnapshot - desperationDelay
            : 0;
        (bool isValidatorElected, uint256 startIndex, uint256 endIndex) = _mayValidatorSnapshot(
            IValidatorPool(_validatorPoolAddress()).getValidatorsCount(),
            validatorIndex - 1,
            blocksSinceDesperation,
            groupSignatureHash,
            uint256(_snapshotDesperationFactor)
        );
        if (!isValidatorElected) {
            revert SnapshotsErrors.ValidatorNotElected(
                validatorIndex - 1,
                startIndex,
                endIndex,
                groupSignatureHash
            );
        }
    }

    function _parseAndValidateBClaims(uint32 epoch, bytes calldata bClaims_)
        internal
        view
        returns (BClaimsParserLibrary.BClaims memory blockClaims)
    {
        blockClaims = BClaimsParserLibrary.extractBClaims(bClaims_);

        if (epoch * _epochLength != blockClaims.height) {
            revert SnapshotsErrors.UnexpectedBlockHeight(blockClaims.height, epoch * _epochLength);
        }

        if (blockClaims.chainId != _chainId) {
            revert SnapshotsErrors.InvalidChainId(blockClaims.chainId);
        }
    }

    function _checkBClaimsSignature(bytes memory groupSignature_, bytes memory bClaims_)
        internal
        view
        returns (uint256[4] memory, uint256[2] memory)
    {
        (uint256[4] memory masterPublicKey, uint256[2] memory signature) = RCertParserLibrary
            .extractSigGroup(groupSignature_, 0);

        bytes32 calculatedMasterPublicKeyHash = keccak256(abi.encodePacked(masterPublicKey));
        bytes32 expectedMasterPublicKeyHash = IETHDKG(_ethdkgAddress()).getMasterPublicKeyHash();

        if (calculatedMasterPublicKeyHash != expectedMasterPublicKeyHash) {
            revert SnapshotsErrors.InvalidMasterPublicKey(
                calculatedMasterPublicKeyHash,
                expectedMasterPublicKeyHash
            );
        }

        if (
            !CryptoLibrary.verifySignatureASM(
                abi.encodePacked(keccak256(bClaims_)),
                signature,
                masterPublicKey
            )
        ) {
            revert SnapshotsErrors.SignatureVerificationFailed();
        }
        return (masterPublicKey, signature);
    }

    function _checkSnapshotMinimumInterval(uint256 lastSnapshotCommittedAt) internal view {
        uint256 minimumIntervalBetweenSnapshots = _minimumIntervalBetweenSnapshots;
        if (block.number < lastSnapshotCommittedAt + minimumIntervalBetweenSnapshots) {
            revert SnapshotsErrors.MinimumBlocksIntervalNotPassed(
                block.number,
                lastSnapshotCommittedAt + minimumIntervalBetweenSnapshots
            );
        }
    }

    function _mayValidatorSnapshot(
        uint256 numValidators,
        uint256 myIdx,
        uint256 blocksSinceDesperation,
        bytes32 randomSeed,
        uint256 desperationFactor
    )
        internal
        pure
        returns (
            bool,
            uint256,
            uint256
        )
    {
        uint256 numValidatorsAllowed = 1;

        uint256 desperation = 0;
        while (desperation < blocksSinceDesperation && numValidatorsAllowed < numValidators) {
            desperation += desperationFactor / numValidatorsAllowed;
            numValidatorsAllowed++;
        }

        uint256 rand = uint256(randomSeed);
        uint256 start = (rand % numValidators);
        uint256 end = (start + numValidatorsAllowed) % numValidators;
        bool isAllowedToDoSnapshots;
        if (end > start) {
            isAllowedToDoSnapshots = myIdx >= start && myIdx < end;
        } else {
            isAllowedToDoSnapshots = myIdx >= start || myIdx < end;
        }
        return (isAllowedToDoSnapshots, start, end);
    }
}