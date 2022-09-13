// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

// enum to keep track of versions of the dynamic struct for the encoding and
// decoding algorithms
enum Version {
    V1
}
struct DynamicValues {
    // first slot
    Version encoderVersion;
    uint24 proposalTimeout;
    uint32 preVoteTimeout;
    uint32 preCommitTimeout;
    uint32 maxBlockSize;
    uint64 dataStoreFee;
    uint64 valueStoreFee;
    // Second slot
    uint128 minScaledTransactionFee;
}

struct Configuration {
    uint128 minEpochsBetweenUpdates;
    uint128 maxEpochsBetweenUpdates;
}

struct CanonicalVersion {
    uint32 major;
    uint32 minor;
    uint32 patch;
    uint32 executionEpoch;
    bytes32 binaryHash;
}

interface IDynamics {
    event DeployedStorageContract(address contractAddr);
    event DynamicValueChanged(uint256 epoch, bytes rawDynamicValues);
    event NewAliceNetNodeVersionAvailable(CanonicalVersion version);
    event NewCanonicalAliceNetNodeVersion(CanonicalVersion version);

    function changeDynamicValues(uint32 relativeExecutionEpoch, DynamicValues memory newValue)
        external;

    function updateHead(uint32 currentEpoch) external;

    function updateAliceNetNodeVersion(
        uint32 relativeUpdateEpoch,
        uint32 majorVersion,
        uint32 minorVersion,
        uint32 patch,
        bytes32 binaryHash
    ) external;

    function setConfiguration(Configuration calldata newConfig) external;

    function deployStorage(bytes calldata data) external returns (address contractAddr);

    function getConfiguration() external view returns (Configuration memory);

    function getLatestAliceNetVersion() external view returns (CanonicalVersion memory);

    function getLatestDynamicValues() external view returns (DynamicValues memory);

    function getPreviousDynamicValues(uint256 epoch) external view returns (DynamicValues memory);

    function decodeDynamicValues(address addr) external view returns (DynamicValues memory);

    function encodeDynamicValues(DynamicValues memory value) external pure returns (bytes memory);

    function getEncodingVersion() external pure returns (Version);
}