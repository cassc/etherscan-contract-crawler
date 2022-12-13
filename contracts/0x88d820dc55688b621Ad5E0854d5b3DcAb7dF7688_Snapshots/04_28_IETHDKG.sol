// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

import "contracts/libraries/ethdkg/ETHDKGStorage.sol";

interface IETHDKG {
    function setPhaseLength(uint16 phaseLength_) external;

    function setConfirmationLength(uint16 confirmationLength_) external;

    function setCustomAliceNetHeight(uint256 aliceNetHeight) external;

    function initializeETHDKG() external;

    function register(uint256[2] memory publicKey) external;

    function distributeShares(
        uint256[] memory encryptedShares,
        uint256[2][] memory commitments
    ) external;

    function submitKeyShare(
        uint256[2] memory keyShareG1,
        uint256[2] memory keyShareG1CorrectnessProof,
        uint256[4] memory keyShareG2
    ) external;

    function submitMasterPublicKey(uint256[4] memory masterPublicKey_) external;

    function submitGPKJ(uint256[4] memory gpkj) external;

    function complete() external;

    function migrateValidators(
        address[] memory validatorsAccounts_,
        uint256[] memory validatorIndexes_,
        uint256[4][] memory validatorShares_,
        uint8 validatorCount_,
        uint256 epoch_,
        uint256 sideChainHeight_,
        uint256 ethHeight_,
        uint256[4] memory masterPublicKey_
    ) external;

    function accuseParticipantNotRegistered(address[] memory dishonestAddresses) external;

    function accuseParticipantDidNotDistributeShares(address[] memory dishonestAddresses) external;

    function accuseParticipantDistributedBadShares(
        address dishonestAddress,
        uint256[] memory encryptedShares,
        uint256[2][] memory commitments,
        uint256[2] memory sharedKey,
        uint256[2] memory sharedKeyCorrectnessProof
    ) external;

    function accuseParticipantDidNotSubmitKeyShares(address[] memory dishonestAddresses) external;

    function accuseParticipantDidNotSubmitGPKJ(address[] memory dishonestAddresses) external;

    function accuseParticipantSubmittedBadGPKJ(
        address[] memory validators,
        bytes32[] memory encryptedSharesHash,
        uint256[2][][] memory commitments,
        address dishonestAddress
    ) external;

    function isETHDKGRunning() external view returns (bool);

    function isMasterPublicKeySet() external view returns (bool);

    function isValidMasterPublicKey(bytes32 masterPublicKeyHash) external view returns (bool);

    function getNonce() external view returns (uint256);

    function getPhaseStartBlock() external view returns (uint256);

    function getPhaseLength() external view returns (uint256);

    function getConfirmationLength() external view returns (uint256);

    function getETHDKGPhase() external view returns (Phase);

    function getNumParticipants() external view returns (uint256);

    function getBadParticipants() external view returns (uint256);

    function getMinValidators() external view returns (uint256);

    function getParticipantInternalState(
        address participant
    ) external view returns (Participant memory);

    function getMasterPublicKey() external view returns (uint256[4] memory);

    function getMasterPublicKeyHash() external view returns (bytes32);

    function getLastRoundParticipantIndex(address participant) external view returns (uint256);
}