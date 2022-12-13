// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

import "contracts/libraries/parsers/BClaimsParserLibrary.sol";

struct Snapshot {
    uint256 committedAt;
    BClaimsParserLibrary.BClaims blockClaims;
}

interface ISnapshots {
    event SnapshotTaken(
        uint256 chainId,
        uint256 indexed epoch,
        uint256 height,
        address indexed validator,
        bool isSafeToProceedConsensus,
        uint256[4] masterPublicKey,
        uint256[2] signature,
        BClaimsParserLibrary.BClaims bClaims
    );

    function setSnapshotDesperationDelay(uint32 desperationDelay_) external;

    function setSnapshotDesperationFactor(uint32 desperationFactor_) external;

    function setMinimumIntervalBetweenSnapshots(uint32 minimumIntervalBetweenSnapshots_) external;

    function snapshot(
        bytes calldata signatureGroup_,
        bytes calldata bClaims_
    ) external returns (bool);

    function migrateSnapshots(
        bytes[] memory groupSignature_,
        bytes[] memory bClaims_
    ) external returns (bool);

    function getSnapshotDesperationDelay() external view returns (uint256);

    function getSnapshotDesperationFactor() external view returns (uint256);

    function getMinimumIntervalBetweenSnapshots() external view returns (uint256);

    function getChainId() external view returns (uint256);

    function getEpoch() external view returns (uint256);

    function getEpochLength() external view returns (uint256);

    function getChainIdFromSnapshot(uint256 epoch_) external view returns (uint256);

    function getChainIdFromLatestSnapshot() external view returns (uint256);

    function getBlockClaimsFromSnapshot(
        uint256 epoch_
    ) external view returns (BClaimsParserLibrary.BClaims memory);

    function getBlockClaimsFromLatestSnapshot()
        external
        view
        returns (BClaimsParserLibrary.BClaims memory);

    function getCommittedHeightFromSnapshot(uint256 epoch_) external view returns (uint256);

    function getCommittedHeightFromLatestSnapshot() external view returns (uint256);

    function getAliceNetHeightFromSnapshot(uint256 epoch_) external view returns (uint256);

    function getAliceNetHeightFromLatestSnapshot() external view returns (uint256);

    function getSnapshot(uint256 epoch_) external view returns (Snapshot memory);

    function getLatestSnapshot() external view returns (Snapshot memory);

    function getEpochFromHeight(uint256 height) external view returns (uint256);

    function checkBClaimsSignature(
        bytes calldata groupSignature_,
        bytes calldata bClaims_
    ) external view returns (bool);

    function isValidatorElectedToPerformSnapshot(
        address validator,
        uint256 lastSnapshotCommittedAt,
        bytes32 groupSignatureHash
    ) external view returns (bool);

    function mayValidatorSnapshot(
        uint256 numValidators,
        uint256 myIdx,
        uint256 blocksSinceDesperation,
        bytes32 blsig,
        uint256 desperationFactor
    ) external pure returns (bool);
}