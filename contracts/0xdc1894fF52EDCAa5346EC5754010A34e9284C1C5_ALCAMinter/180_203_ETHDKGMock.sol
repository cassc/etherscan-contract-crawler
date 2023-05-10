// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

import "contracts/libraries/math/CryptoLibrary.sol";
import "contracts/utils/AtomicCounter.sol";
import "contracts/interfaces/IValidatorPool.sol";
import "contracts/interfaces/IETHDKG.sol";
import "contracts/interfaces/IETHDKGEvents.sol";
import "contracts/libraries/ethdkg/ETHDKGStorage.sol";
import "contracts/utils/ETHDKGUtils.sol";
import "contracts/utils/auth/ImmutableFactory.sol";
import "contracts/utils/auth/ImmutableETHDKGAccusations.sol";
import "contracts/utils/auth/ImmutableETHDKGPhases.sol";
import "contracts/libraries/errors/ETHDKGErrors.sol";
import "contracts/libraries/proxy/ProxyImplementationGetter.sol";
import "@openzeppelin/contracts/utils/Address.sol";

contract ETHDKGMock is
    ETHDKGStorage,
    IETHDKG,
    ETHDKGUtils,
    ImmutableETHDKGAccusations,
    ImmutableETHDKGPhases,
    IETHDKGEvents,
    ProxyImplementationGetter
{
    using Address for address;

    modifier onlyValidator() {
        if (!IValidatorPool(_validatorPoolAddress()).isValidator(msg.sender)) {
            revert ETHDKGErrors.OnlyValidatorsAllowed(msg.sender);
        }
        _;
    }

    constructor() ETHDKGStorage() ImmutableETHDKGAccusations() ImmutableETHDKGPhases() {}

    function minorSlash(address validator, address accussator) external {
        IValidatorPool(_validatorPoolAddress()).minorSlash(validator, accussator);
    }

    function majorSlash(address validator, address accussator) external {
        IValidatorPool(_validatorPoolAddress()).majorSlash(validator, accussator);
    }

    function setConsensusRunning() external {
        IValidatorPool(_validatorPoolAddress()).completeETHDKG();
    }

    function initialize(uint256 phaseLength_, uint256 confirmationLength_) public initializer {
        _phaseLength = uint16(phaseLength_);
        _confirmationLength = uint16(confirmationLength_);
    }

    function reinitialize(
        uint256 phaseLength_,
        uint256 confirmationLength_
    ) public reinitializer(2) {
        _phaseLength = uint16(phaseLength_);
        _confirmationLength = uint16(confirmationLength_);
    }

    function setPhaseLength(uint16 phaseLength_) public {
        if (_isETHDKGRunning()) {
            revert ETHDKGErrors.VariableNotSettableWhileETHDKGRunning();
        }
        _phaseLength = phaseLength_;
    }

    function setConfirmationLength(uint16 confirmationLength_) public {
        if (_isETHDKGRunning()) {
            revert ETHDKGErrors.VariableNotSettableWhileETHDKGRunning();
        }
        _confirmationLength = confirmationLength_;
    }

    function setCustomAliceNetHeight(uint256 aliceNetHeight) public {
        _customAliceNetHeight = aliceNetHeight;
        emit ValidatorSetCompleted(
            0,
            _nonce,
            ISnapshots(_snapshotsAddress()).getEpoch(),
            ISnapshots(_snapshotsAddress()).getCommittedHeightFromLatestSnapshot(),
            aliceNetHeight,
            0x0,
            0x0,
            0x0,
            0x0
        );
    }

    function initializeETHDKG() public {
        _initializeETHDKG();
    }

    function register(uint256[2] memory publicKey) public onlyValidator {
        _callPhaseContract(abi.encodeWithSignature("register(uint256[2])", publicKey));
    }

    function accuseParticipantNotRegistered(address[] memory dishonestAddresses) public {
        _callAccusationContract(
            abi.encodeWithSignature("accuseParticipantNotRegistered(address[])", dishonestAddresses)
        );
    }

    function distributeShares(
        uint256[] memory encryptedShares,
        uint256[2][] memory commitments
    ) public onlyValidator {
        _callPhaseContract(
            abi.encodeWithSignature(
                "distributeShares(uint256[],uint256[2][])",
                encryptedShares,
                commitments
            )
        );
    }

    ///
    function accuseParticipantDidNotDistributeShares(address[] memory dishonestAddresses) public {
        _callAccusationContract(
            abi.encodeWithSignature(
                "accuseParticipantDidNotDistributeShares(address[])",
                dishonestAddresses
            )
        );
    }

    // Someone sent bad shares
    function accuseParticipantDistributedBadShares(
        address dishonestAddress,
        uint256[] memory encryptedShares,
        uint256[2][] memory commitments,
        uint256[2] memory sharedKey,
        uint256[2] memory sharedKeyCorrectnessProof
    ) public onlyValidator {
        _callAccusationContract(
            abi.encodeWithSignature(
                "accuseParticipantDistributedBadShares(address,uint256[],uint256[2][],uint256[2],uint256[2])",
                dishonestAddress,
                encryptedShares,
                commitments,
                sharedKey,
                sharedKeyCorrectnessProof
            )
        );
    }

    function submitKeyShare(
        uint256[2] memory keyShareG1,
        uint256[2] memory keyShareG1CorrectnessProof,
        uint256[4] memory keyShareG2
    ) public onlyValidator {
        _callPhaseContract(
            abi.encodeWithSignature(
                "submitKeyShare(uint256[2],uint256[2],uint256[4])",
                keyShareG1,
                keyShareG1CorrectnessProof,
                keyShareG2
            )
        );
    }

    function accuseParticipantDidNotSubmitKeyShares(address[] memory dishonestAddresses) public {
        _callAccusationContract(
            abi.encodeWithSignature(
                "accuseParticipantDidNotSubmitKeyShares(address[])",
                dishonestAddresses
            )
        );
    }

    function submitMasterPublicKey(uint256[4] memory masterPublicKey_) public {
        _callPhaseContract(
            abi.encodeWithSignature("submitMasterPublicKey(uint256[4])", masterPublicKey_)
        );
    }

    function submitGPKJ(uint256[4] memory gpkj) public onlyValidator {
        _callPhaseContract(abi.encodeWithSignature("submitGPKJ(uint256[4])", gpkj));
    }

    function accuseParticipantDidNotSubmitGPKJ(address[] memory dishonestAddresses) public {
        _callAccusationContract(
            abi.encodeWithSignature(
                "accuseParticipantDidNotSubmitGPKJ(address[])",
                dishonestAddresses
            )
        );
    }

    function accuseParticipantSubmittedBadGPKJ(
        address[] memory validators,
        bytes32[] memory encryptedSharesHash,
        uint256[2][][] memory commitments,
        address dishonestAddress
    ) public onlyValidator {
        _callAccusationContract(
            abi.encodeWithSignature(
                "accuseParticipantSubmittedBadGPKJ(address[],bytes32[],uint256[2][][],address)",
                validators,
                encryptedSharesHash,
                commitments,
                dishonestAddress
            )
        );
    }

    // Successful_Completion should be called at the completion of the DKG algorithm.
    function complete() public {
        _callPhaseContract(abi.encodeWithSignature("complete()"));
    }

    function setValidMasterPublicKey(bytes32 mpk_) public {
        _masterPublicKeyRegistry[mpk_] = true;
    }

    function isETHDKGRunning() public view returns (bool) {
        return _isETHDKGRunning();
    }

    function isETHDKGCompleted() public view returns (bool) {
        return _isETHDKGCompleted();
    }

    function isETHDKGHalted() public view returns (bool) {
        return _isETHDKGHalted();
    }

    function isMasterPublicKeySet() public view returns (bool) {
        return ((_masterPublicKey[0] != 0) ||
            (_masterPublicKey[1] != 0) ||
            (_masterPublicKey[2] != 0) ||
            (_masterPublicKey[3] != 0));
    }

    function isValidMasterPublicKey(bytes32 masterPublicKeyHash) public view returns (bool) {
        return _masterPublicKeyRegistry[masterPublicKeyHash];
    }

    function getNonce() public view returns (uint256) {
        return _nonce;
    }

    function getPhaseStartBlock() public view returns (uint256) {
        return _phaseStartBlock;
    }

    function getPhaseLength() public view returns (uint256) {
        return _phaseLength;
    }

    function getConfirmationLength() public view returns (uint256) {
        return _confirmationLength;
    }

    function getETHDKGPhase() public view returns (Phase) {
        return _ethdkgPhase;
    }

    function getNumParticipants() public view returns (uint256) {
        return _numParticipants;
    }

    function getBadParticipants() public view returns (uint256) {
        return _badParticipants;
    }

    function getParticipantInternalState(
        address participant
    ) public view returns (Participant memory) {
        return _participants[participant];
    }

    function getParticipantsInternalState(
        address[] calldata participantAddresses
    ) public view returns (Participant[] memory) {
        Participant[] memory participants = new Participant[](participantAddresses.length);

        for (uint256 i = 0; i < participantAddresses.length; i++) {
            participants[i] = _participants[participantAddresses[i]];
        }

        return participants;
    }

    function getLastRoundParticipantIndex(address participant) public view returns (uint256) {
        uint256 participantDataIndex = _participants[participant].index;
        uint256 participantDataNonce = _participants[participant].nonce;
        uint256 nonce = _nonce;
        if (nonce == 0 || participantDataNonce != nonce) {
            revert ETHDKGErrors.ParticipantNotFoundInLastRound(participant);
        }
        return participantDataIndex;
    }

    function getMasterPublicKey() public view returns (uint256[4] memory) {
        return _masterPublicKey;
    }

    function getMasterPublicKeyHash() public view returns (bytes32) {
        return _masterPublicKeyHash;
    }

    function migrateValidators(
        address[] memory validatorsAccounts_,
        uint256[] memory validatorIndexes_,
        uint256[4][] memory validatorShares_,
        uint8 validatorCount_,
        uint256 epoch_,
        uint256 sideChainHeight_,
        uint256 ethHeight_,
        uint256[4] memory masterPublicKey_
    ) public pure {
        validatorsAccounts_;
        validatorIndexes_;
        validatorShares_;
        validatorCount_;
        epoch_;
        sideChainHeight_;
        ethHeight_;
        masterPublicKey_;
    }

    function getMinValidators() public pure returns (uint256) {
        return _MIN_VALIDATORS;
    }

    function _callAccusationContract(bytes memory callData) internal returns (bytes memory) {
        return _getETHDKGAccusationsAddress().functionDelegateCall(callData);
    }

    function _callPhaseContract(bytes memory callData) internal returns (bytes memory) {
        return _getETHDKGPhasesAddress().functionDelegateCall(callData);
    }

    function _initializeETHDKG() internal {
        //todo: should we reward ppl here?
        uint256 numberValidators = IValidatorPool(_validatorPoolAddress()).getValidatorsCount();
        if (numberValidators < _MIN_VALIDATORS) {
            revert ETHDKGErrors.MinimumValidatorsNotMet(numberValidators);
        }

        _phaseStartBlock = uint64(block.number);
        _nonce++;
        _numParticipants = 0;
        _badParticipants = 0;
        _mpkG1 = [uint256(0), uint256(0)];
        _ethdkgPhase = Phase.RegistrationOpen;

        delete _masterPublicKey;

        emit RegistrationOpened(
            block.number,
            numberValidators,
            _nonce,
            _phaseLength,
            _confirmationLength
        );
    }

    function _getETHDKGPhasesAddress() internal view returns (address ethdkgPhases) {
        ethdkgPhases = __getProxyImplementation(_ethdkgPhasesAddress());
        if (!ethdkgPhases.isContract()) {
            revert ETHDKGErrors.ETHDKGSubContractNotSet();
        }
    }

    function _getETHDKGAccusationsAddress() internal view returns (address ethdkgAccusations) {
        ethdkgAccusations = __getProxyImplementation(_ethdkgAccusationsAddress());
        if (!ethdkgAccusations.isContract()) {
            revert ETHDKGErrors.ETHDKGSubContractNotSet();
        }
    }

    function _isETHDKGCompleted() internal view returns (bool) {
        return _ethdkgPhase == Phase.Completion;
    }

    function _isETHDKGRunning() internal view returns (bool) {
        // Handling initial case
        if (_phaseStartBlock == 0) {
            return false;
        }
        return !_isETHDKGCompleted() && !_isETHDKGHalted();
    }

    // todo: generate truth table
    function _isETHDKGHalted() internal view returns (bool) {
        bool ethdkgFailedInDisputePhase = (_ethdkgPhase == Phase.DisputeShareDistribution ||
            _ethdkgPhase == Phase.DisputeGPKJSubmission) &&
            block.number >= _phaseStartBlock + _phaseLength &&
            _badParticipants != 0;
        bool ethdkgFailedInNormalPhase = block.number >= _phaseStartBlock + 2 * _phaseLength;
        return ethdkgFailedInNormalPhase || ethdkgFailedInDisputePhase;
    }
}