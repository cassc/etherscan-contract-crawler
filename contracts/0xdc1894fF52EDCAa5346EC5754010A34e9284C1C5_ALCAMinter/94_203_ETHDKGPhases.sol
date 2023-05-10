// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

import "contracts/libraries/math/CryptoLibrary.sol";
import "contracts/interfaces/IETHDKG.sol";
import "contracts/interfaces/IETHDKGEvents.sol";
import "contracts/libraries/ethdkg/ETHDKGStorage.sol";
import "contracts/utils/ETHDKGUtils.sol";
import "contracts/libraries/errors/ETHDKGErrors.sol";

/// @custom:salt ETHDKGPhases
/// @custom:deploy-type deployUpgradeable
/// @custom:deploy-group ethdkg
/// @custom:deploy-group-index 1
contract ETHDKGPhases is ETHDKGStorage, IETHDKGEvents, ETHDKGUtils {
    constructor() ETHDKGStorage() {}

    function register(uint256[2] memory publicKey) external {
        if (
            _ethdkgPhase != Phase.RegistrationOpen ||
            block.number < _phaseStartBlock ||
            block.number >= _phaseStartBlock + _phaseLength
        ) {
            PhaseInformation[] memory expectedPhaseInfos = new PhaseInformation[](1);
            expectedPhaseInfos[0] = PhaseInformation(
                Phase.RegistrationOpen,
                _phaseStartBlock,
                _phaseStartBlock + _phaseLength
            );
            revert ETHDKGErrors.IncorrectPhase(_ethdkgPhase, block.number, expectedPhaseInfos);
        }
        if (publicKey[0] == 0 || publicKey[1] == 0) {
            revert ETHDKGErrors.PublicKeyZero();
        }

        if (!CryptoLibrary.bn128IsOnCurve(publicKey)) {
            revert ETHDKGErrors.PublicKeyNotOnCurve();
        }

        if (_participants[msg.sender].nonce >= _nonce) {
            revert ETHDKGErrors.ParticipantParticipatingInRound(
                msg.sender,
                _participants[msg.sender].nonce,
                _nonce - 1
            );
        }

        uint32 numRegistered = uint32(_numParticipants);
        numRegistered++;
        _participants[msg.sender] = Participant({
            publicKey: publicKey,
            index: numRegistered,
            nonce: _nonce,
            phase: _ethdkgPhase,
            distributedSharesHash: 0x0,
            commitmentsFirstCoefficient: [uint256(0), uint256(0)],
            keyShares: [uint256(0), uint256(0)],
            gpkj: [uint256(0), uint256(0), uint256(0), uint256(0)]
        });

        emit AddressRegistered(msg.sender, numRegistered, _nonce, publicKey);
        if (
            _moveToNextPhase(
                Phase.ShareDistribution,
                IValidatorPool(_validatorPoolAddress()).getValidatorsCount(),
                numRegistered
            )
        ) {
            emit RegistrationComplete(block.number);
        }
    }

    function distributeShares(
        uint256[] memory encryptedShares,
        uint256[2][] memory commitments
    ) external {
        if (
            _ethdkgPhase != Phase.ShareDistribution ||
            block.number < _phaseStartBlock ||
            block.number >= _phaseStartBlock + _phaseLength
        ) {
            PhaseInformation[] memory expectedPhaseInfos = new PhaseInformation[](1);
            expectedPhaseInfos[0] = PhaseInformation(
                Phase.ShareDistribution,
                _phaseStartBlock,
                _phaseStartBlock + _phaseLength
            );
            revert ETHDKGErrors.IncorrectPhase(_ethdkgPhase, block.number, expectedPhaseInfos);
        }

        Participant memory participant = _participants[msg.sender];
        if (participant.nonce != _nonce) {
            revert ETHDKGErrors.InvalidNonce(participant.nonce, _nonce);
        }

        if (participant.phase != Phase.RegistrationOpen) {
            revert ETHDKGErrors.ParticipantDistributedSharesInRound(msg.sender);
        }

        uint256 numValidators = IValidatorPool(_validatorPoolAddress()).getValidatorsCount();
        uint256 threshold = _getThreshold(numValidators);
        if (encryptedShares.length != numValidators - 1) {
            revert ETHDKGErrors.InvalidEncryptedSharesAmount(
                encryptedShares.length,
                numValidators - 1
            );
        }

        if (commitments.length != threshold + 1) {
            revert ETHDKGErrors.InvalidCommitmentsAmount(commitments.length, threshold + 1);
        }
        for (uint256 k = 0; k <= threshold; k++) {
            if (!CryptoLibrary.bn128IsOnCurve(commitments[k])) {
                revert ETHDKGErrors.CommitmentNotOnCurve();
            }
            if (commitments[k][0] == 0) {
                revert ETHDKGErrors.CommitmentZero();
            }
        }

        bytes32 encryptedSharesHash = keccak256(abi.encodePacked(encryptedShares));
        bytes32 commitmentsHash = keccak256(abi.encodePacked(commitments));
        participant.distributedSharesHash = keccak256(
            abi.encodePacked(encryptedSharesHash, commitmentsHash)
        );
        if (participant.distributedSharesHash == 0x0) {
            revert ETHDKGErrors.DistributedShareHashZero();
        }
        participant.commitmentsFirstCoefficient = commitments[0];
        participant.phase = Phase.ShareDistribution;

        _participants[msg.sender] = participant;
        uint256 numParticipants = _numParticipants + 1;

        emit SharesDistributed(
            msg.sender,
            participant.index,
            participant.nonce,
            encryptedShares,
            commitments
        );

        if (_moveToNextPhase(Phase.DisputeShareDistribution, numValidators, numParticipants)) {
            emit ShareDistributionComplete(block.number);
        }
    }

    function submitKeyShare(
        uint256[2] memory keyShareG1,
        uint256[2] memory keyShareG1CorrectnessProof,
        uint256[4] memory keyShareG2
    ) external {
        // Only progress if all participants distributed their shares
        // and no bad participant was found
        {
            bool isInKeyShareSubmission = _ethdkgPhase == Phase.KeyShareSubmission &&
                block.number >= _phaseStartBlock &&
                block.number < _phaseStartBlock + _phaseLength;
            bool isInDisputeShareDistribution = _ethdkgPhase == Phase.DisputeShareDistribution &&
                block.number >= _phaseStartBlock + _phaseLength &&
                block.number < _phaseStartBlock + 2 * _phaseLength &&
                _badParticipants == 0;
            if (!isInKeyShareSubmission && !isInDisputeShareDistribution) {
                PhaseInformation[] memory expectedPhaseInfos = new PhaseInformation[](2);
                expectedPhaseInfos[0] = PhaseInformation(
                    Phase.KeyShareSubmission,
                    _phaseStartBlock,
                    _phaseStartBlock + _phaseLength
                );
                expectedPhaseInfos[1] = PhaseInformation(
                    Phase.DisputeShareDistribution,
                    _phaseStartBlock + _phaseLength,
                    _phaseStartBlock + 2 * _phaseLength
                );
                revert ETHDKGErrors.IncorrectPhase(_ethdkgPhase, block.number, expectedPhaseInfos);
            }
        }

        // Since we had a dispute stage prior this state we need to set global state in here
        if (_ethdkgPhase != Phase.KeyShareSubmission) {
            _setPhase(Phase.KeyShareSubmission);
        }
        Participant memory participant = _participants[msg.sender];
        if (participant.nonce != _nonce) {
            revert ETHDKGErrors.InvalidNonce(participant.nonce, _nonce);
        }
        if (participant.phase != Phase.ShareDistribution) {
            revert ETHDKGErrors.ParticipantSubmittedKeysharesInRound(msg.sender);
        }

        if (
            !CryptoLibrary.discreteLogEquality(
                [CryptoLibrary.H1_X, CryptoLibrary.H1_Y],
                keyShareG1,
                [CryptoLibrary.G1_X, CryptoLibrary.G1_Y],
                participant.commitmentsFirstCoefficient,
                keyShareG1CorrectnessProof
            )
        ) {
            revert ETHDKGErrors.InvalidKeyshareG1();
        }

        if (
            !CryptoLibrary.bn128CheckPairing(
                [
                    keyShareG1[0],
                    keyShareG1[1],
                    CryptoLibrary.H2_XI,
                    CryptoLibrary.H2_X,
                    CryptoLibrary.H2_YI,
                    CryptoLibrary.H2_Y,
                    CryptoLibrary.H1_X,
                    CryptoLibrary.H1_Y,
                    keyShareG2[0],
                    keyShareG2[1],
                    keyShareG2[2],
                    keyShareG2[3]
                ]
            )
        ) {
            revert ETHDKGErrors.InvalidKeyshareG2();
        }

        participant.keyShares = keyShareG1;
        participant.phase = Phase.KeyShareSubmission;
        _participants[msg.sender] = participant;

        uint256 numParticipants = _numParticipants + 1;
        uint256[2] memory mpkG1;
        if (numParticipants > 1) {
            mpkG1 = _mpkG1;
        }
        _mpkG1 = CryptoLibrary.bn128Add(
            [mpkG1[0], mpkG1[1], participant.keyShares[0], participant.keyShares[1]]
        );

        emit KeyShareSubmitted(
            msg.sender,
            participant.index,
            participant.nonce,
            keyShareG1,
            keyShareG1CorrectnessProof,
            keyShareG2
        );

        if (
            _moveToNextPhase(
                Phase.MPKSubmission,
                IValidatorPool(_validatorPoolAddress()).getValidatorsCount(),
                numParticipants
            )
        ) {
            emit KeyShareSubmissionComplete(block.number);
        }
    }

    function submitMasterPublicKey(uint256[4] memory masterPublicKey_) external {
        if (
            _ethdkgPhase != Phase.MPKSubmission ||
            block.number < _phaseStartBlock ||
            block.number >= _phaseStartBlock + _phaseLength
        ) {
            PhaseInformation[] memory expectedPhaseInfos = new PhaseInformation[](1);
            expectedPhaseInfos[0] = PhaseInformation(
                Phase.MPKSubmission,
                _phaseStartBlock,
                _phaseStartBlock + _phaseLength
            );
            revert ETHDKGErrors.IncorrectPhase(_ethdkgPhase, block.number, expectedPhaseInfos);
        }
        uint256[2] memory mpkG1 = _mpkG1;
        if (
            !CryptoLibrary.bn128CheckPairing(
                [
                    mpkG1[0],
                    mpkG1[1],
                    CryptoLibrary.H2_XI,
                    CryptoLibrary.H2_X,
                    CryptoLibrary.H2_YI,
                    CryptoLibrary.H2_Y,
                    CryptoLibrary.H1_X,
                    CryptoLibrary.H1_Y,
                    masterPublicKey_[0],
                    masterPublicKey_[1],
                    masterPublicKey_[2],
                    masterPublicKey_[3]
                ]
            )
        ) {
            revert ETHDKGErrors.MasterPublicKeyPairingCheckFailure();
        }

        _masterPublicKey = masterPublicKey_;
        _masterPublicKeyHash = keccak256(abi.encodePacked(masterPublicKey_));

        _setPhase(Phase.GPKJSubmission);
        emit MPKSet(block.number, _nonce, masterPublicKey_);
    }

    function submitGPKJ(uint256[4] memory gpkj) external {
        //todo: should we evict all validators if no one sent the master public key in time?
        if (
            _ethdkgPhase != Phase.GPKJSubmission ||
            block.number < _phaseStartBlock ||
            block.number >= _phaseStartBlock + _phaseLength
        ) {
            PhaseInformation[] memory expectedPhaseInfos = new PhaseInformation[](1);
            expectedPhaseInfos[0] = PhaseInformation(
                Phase.GPKJSubmission,
                _phaseStartBlock,
                _phaseStartBlock + _phaseLength
            );
            revert ETHDKGErrors.IncorrectPhase(_ethdkgPhase, block.number, expectedPhaseInfos);
        }

        Participant memory participant = _participants[msg.sender];

        if (participant.nonce != _nonce) {
            revert ETHDKGErrors.InvalidNonce(participant.nonce, _nonce);
        }
        if (participant.phase != Phase.KeyShareSubmission) {
            revert ETHDKGErrors.ParticipantSubmittedGPKJInRound(msg.sender);
        }

        if (gpkj[0] == 0 && gpkj[1] == 0 && gpkj[2] == 0 && gpkj[3] == 0) {
            revert ETHDKGErrors.GPKJZero();
        }

        participant.gpkj = gpkj;
        participant.phase = Phase.GPKJSubmission;
        _participants[msg.sender] = participant;

        emit ValidatorMemberAdded(
            msg.sender,
            participant.index,
            participant.nonce,
            ISnapshots(_snapshotsAddress()).getEpoch(),
            participant.gpkj[0],
            participant.gpkj[1],
            participant.gpkj[2],
            participant.gpkj[3]
        );

        uint256 numParticipants = _numParticipants + 1;
        if (
            _moveToNextPhase(
                Phase.DisputeGPKJSubmission,
                IValidatorPool(_validatorPoolAddress()).getValidatorsCount(),
                numParticipants
            )
        ) {
            emit GPKJSubmissionComplete(block.number);
        }
    }

    function complete() external {
        //todo: should we reward ppl here?
        if (
            _ethdkgPhase != Phase.DisputeGPKJSubmission ||
            block.number < _phaseStartBlock + _phaseLength ||
            block.number >= _phaseStartBlock + 2 * _phaseLength
        ) {
            PhaseInformation[] memory expectedPhaseInfos = new PhaseInformation[](1);
            expectedPhaseInfos[0] = PhaseInformation(
                Phase.DisputeGPKJSubmission,
                _phaseStartBlock + _phaseLength,
                _phaseStartBlock + 2 * _phaseLength
            );
            revert ETHDKGErrors.IncorrectPhase(_ethdkgPhase, block.number, expectedPhaseInfos);
        }
        if (_badParticipants != 0) {
            revert ETHDKGErrors.ETHDKGRequisitesIncomplete();
        }

        // Since we had a dispute stage prior this state we need to set global state in here
        _setPhase(Phase.Completion);

        // add the current master public key in the registry
        _masterPublicKeyRegistry[_masterPublicKeyHash] = true;

        IValidatorPool(_validatorPoolAddress()).completeETHDKG();

        uint256 epoch = ISnapshots(_snapshotsAddress()).getEpoch();
        uint256 ethHeight = ISnapshots(_snapshotsAddress()).getCommittedHeightFromLatestSnapshot();
        uint256 aliceNetHeight;
        if (_customAliceNetHeight == 0) {
            aliceNetHeight = ISnapshots(_snapshotsAddress()).getAliceNetHeightFromLatestSnapshot();
        } else {
            aliceNetHeight = _customAliceNetHeight;
            _customAliceNetHeight = 0;
        }
        emit ValidatorSetCompleted(
            uint8(IValidatorPool(_validatorPoolAddress()).getValidatorsCount()),
            _nonce,
            epoch,
            ethHeight,
            aliceNetHeight,
            _masterPublicKey[0],
            _masterPublicKey[1],
            _masterPublicKey[2],
            _masterPublicKey[3]
        );
    }

    function getMyAddress() public view returns (address) {
        return address(this);
    }

    function _setPhase(Phase phase_) internal {
        _ethdkgPhase = phase_;
        _phaseStartBlock = uint64(block.number);
        _numParticipants = 0;
    }

    function _moveToNextPhase(
        Phase phase_,
        uint256 numValidators_,
        uint256 numParticipants_
    ) internal returns (bool) {
        // if all validators have registered, we can proceed to the next phase
        if (numParticipants_ == numValidators_) {
            _setPhase(phase_);
            _phaseStartBlock += _confirmationLength;
            return true;
        } else {
            _numParticipants = uint32(numParticipants_);
            return false;
        }
    }

    function _isMasterPublicKeySet() internal view returns (bool) {
        return ((_masterPublicKey[0] != 0) ||
            (_masterPublicKey[1] != 0) ||
            (_masterPublicKey[2] != 0) ||
            (_masterPublicKey[3] != 0));
    }
}