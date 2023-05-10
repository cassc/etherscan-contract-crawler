// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "contracts/interfaces/ISnapshots.sol";
import "contracts/utils/auth/ImmutableFactory.sol";
import "contracts/utils/auth/ImmutableSnapshots.sol";
import "contracts/libraries/dynamics/DoublyLinkedList.sol";
import "contracts/libraries/errors/DynamicsErrors.sol";
import "contracts/interfaces/IDynamics.sol";

/// @custom:salt Dynamics
/// @custom:deploy-type deployUpgradeable
contract Dynamics is Initializable, IDynamics, ImmutableSnapshots {
    using DoublyLinkedListLogic for DoublyLinkedList;

    bytes8 internal constant _UNIVERSAL_DEPLOY_CODE = 0x38585839386009f3;
    Version internal constant _CURRENT_VERSION = Version.V1;

    DoublyLinkedList internal _dynamicValues;
    Configuration internal _configuration;
    CanonicalVersion internal _aliceNetCanonicalVersion;

    constructor() ImmutableFactory(msg.sender) ImmutableSnapshots() {}

    /// Initializes the dynamic value linked list and configurations.
    function initialize(uint24 initialProposalTimeout_) public onlyFactory initializer {
        DynamicValues memory initialValues = DynamicValues(
            Version.V1,
            initialProposalTimeout_,
            3000,
            3000,
            3000000,
            0,
            0,
            0
        );
        // minimum 2 epochs,
        uint128 minEpochsBetweenUpdates = 2;
        // max 336 epochs (approx 1 month considering a snapshot every 2h)
        uint128 maxEpochsBetweenUpdates = 336;
        _configuration = Configuration(minEpochsBetweenUpdates, maxEpochsBetweenUpdates);
        _addNode(1, initialValues);
    }

    /// Change the dynamic values in a epoch in the future.
    /// @param relativeExecutionEpoch the relative execution epoch in which the new
    /// changes will become active.
    /// @param newValue DynamicValue struct with the new values.
    function changeDynamicValues(
        uint32 relativeExecutionEpoch,
        DynamicValues memory newValue
    ) public onlyFactory {
        _changeDynamicValues(relativeExecutionEpoch, newValue);
    }

    /// Updates the current head of the dynamic values linked list. The head always
    /// contain the values that is execution at a moment.
    /// @param currentEpoch the current execution epoch to check if head should be
    /// updated or not.
    function updateHead(uint32 currentEpoch) public onlySnapshots {
        uint32 nextEpoch = _dynamicValues.getNextEpoch(_dynamicValues.getHead());
        if (nextEpoch != 0 && currentEpoch >= nextEpoch) {
            _dynamicValues.setHead(nextEpoch);
        }
        CanonicalVersion memory currentVersion = _aliceNetCanonicalVersion;
        if (currentVersion.executionEpoch != 0 && currentVersion.executionEpoch == currentEpoch) {
            emit NewCanonicalAliceNetNodeVersion(currentVersion);
        }
    }

    /// Updates the aliceNet node version. The new version should always be greater
    /// than the old version. The new major version cannot be greater than 1 unit
    /// comparing with the previous version.
    /// @param relativeUpdateEpoch how many epochs from current epoch that the new
    /// version will become canonical (and maybe mandatory if its a major update).
    /// @param majorVersion major version of the aliceNet Node.
    /// @param minorVersion minor version of the aliceNet Node.
    /// @param patch patch version of the aliceNet Node.
    /// @param binaryHash hash of the aliceNet Node.
    function updateAliceNetNodeVersion(
        uint32 relativeUpdateEpoch,
        uint32 majorVersion,
        uint32 minorVersion,
        uint32 patch,
        bytes32 binaryHash
    ) public onlyFactory {
        _updateAliceNetNodeVersion(
            relativeUpdateEpoch,
            majorVersion,
            minorVersion,
            patch,
            binaryHash
        );
    }

    /// Sets the configuration for the dynamic system.
    /// @param newConfig the struct with the new configuration.
    function setConfiguration(Configuration calldata newConfig) public onlyFactory {
        _configuration = newConfig;
    }

    /// Deploys a new storage contract. A storage contract contains arbitrary data
    /// sent in the `data` parameter as its runtime byte code. I.e, it is a basic a
    /// blob of data with an address.
    /// @param data the data to be stored in the storage contract runtime byte code.
    /// @return contractAddr the address of the storage contract.
    function deployStorage(bytes calldata data) public returns (address contractAddr) {
        return _deployStorage(data);
    }

    /// Gets the latest configuration.
    function getConfiguration() public view returns (Configuration memory) {
        return _configuration;
    }

    /// Get the latest dynamic values that are currently in execution in the side chain.
    function getLatestDynamicValues() public view returns (DynamicValues memory) {
        return _decodeDynamicValues(_dynamicValues.getValue(_dynamicValues.getHead()));
    }

    /// Get the furthest dynamic values that will be in execution in the future.
    function getFurthestDynamicValues() public view returns (DynamicValues memory) {
        return _decodeDynamicValues(_dynamicValues.getValue(_dynamicValues.getTail()));
    }

    /// Get the latest version of the aliceNet node and when it becomes canonical.
    function getLatestAliceNetVersion() public view returns (CanonicalVersion memory) {
        return _aliceNetCanonicalVersion;
    }

    /// Get the dynamic value in execution from an epoch in the past. The value has
    /// to be greater than the previous head execution epoch.
    /// @param epoch The epoch in the past to get the dynamic value.
    function getPreviousDynamicValues(uint256 epoch) public view returns (DynamicValues memory) {
        uint256 head = _dynamicValues.getHead();
        if (head <= epoch) {
            return _decodeDynamicValues(_dynamicValues.getValue(head));
        }
        uint256 previous = _dynamicValues.getPreviousEpoch(head);
        if (previous != 0 && previous <= epoch) {
            return _decodeDynamicValues(_dynamicValues.getValue(previous));
        }
        revert DynamicsErrors.DynamicValueNotFound(epoch);
    }

    /// Get all the dynamic values in the doubly linked list
    function getAllDynamicValues() public view returns (DynamicValues[] memory) {
        DynamicValues[] memory dynamicValuesArray = new DynamicValues[](_dynamicValues.totalNodes);
        uint256 position = 0;
        for (uint256 epoch = 1; epoch != 0; epoch = _dynamicValues.getNextEpoch(epoch)) {
            address data = _dynamicValues.getValue(epoch);
            dynamicValuesArray[position] = _decodeDynamicValues(data);
            position++;
        }
        return dynamicValuesArray;
    }

    /// Decodes a dynamic struct from a storage contract.
    /// @param addr The address of the storage contract that contains the dynamic
    /// values as its runtime byte code.
    function decodeDynamicValues(address addr) public view returns (DynamicValues memory) {
        return _decodeDynamicValues(addr);
    }

    /// Encode a dynamic value struct to be stored in a storage contract.
    /// @param value the dynamic value struct to be encoded.
    function encodeDynamicValues(DynamicValues memory value) public pure returns (bytes memory) {
        return _encodeDynamicValues(value);
    }

    /// Get the latest encoding version that its being used to encode and decode the
    /// dynamic values from the storage contracts.
    function getEncodingVersion() public pure returns (Version) {
        return _CURRENT_VERSION;
    }

    // Internal function to deploy a new storage contract with the `data` as its
    // runtime byte code.
    // @param data the data that will be used to deploy the new storage contract.
    // @return the new storage contract address.
    function _deployStorage(bytes memory data) internal returns (address) {
        bytes memory deployCode = abi.encodePacked(_UNIVERSAL_DEPLOY_CODE, data);
        address addr;
        assembly ("memory-safe") {
            addr := create(0, add(deployCode, 0x20), mload(deployCode))
            if iszero(addr) {
                //if contract creation fails, we want to return any err messages
                let ptr := mload(0x40)
                mstore(0x40, add(ptr, returndatasize()))
                returndatacopy(ptr, 0x00, returndatasize())
                revert(ptr, returndatasize())
            }
        }
        emit DeployedStorageContract(addr);
        return addr;
    }

    // Internal function to update the aliceNet Node version. The new version should
    // always be greater than the old version. The new major version cannot be
    // greater than 1 unit comparing with the previous version.
    // @param relativeUpdateEpoch how many epochs from current epoch that the new
    // version will become canonical (and maybe mandatory if its a major update).
    // @param majorVersion major version of the aliceNet Node.
    // @param minorVersion minor version of the aliceNet Node.
    // @param patch patch version of the aliceNet Node.
    // @param binaryHash hash of the aliceNet Node.
    function _updateAliceNetNodeVersion(
        uint32 relativeUpdateEpoch,
        uint32 majorVersion,
        uint32 minorVersion,
        uint32 patch,
        bytes32 binaryHash
    ) internal {
        CanonicalVersion memory currentVersion = _aliceNetCanonicalVersion;
        uint256 currentCompactedVersion = _computeCompactedVersion(
            currentVersion.major,
            currentVersion.minor,
            currentVersion.patch
        );
        CanonicalVersion memory newVersion = CanonicalVersion(
            majorVersion,
            minorVersion,
            patch,
            _computeExecutionEpoch(relativeUpdateEpoch),
            binaryHash
        );
        uint256 newCompactedVersion = _computeCompactedVersion(majorVersion, minorVersion, patch);
        if (
            newCompactedVersion <= currentCompactedVersion ||
            majorVersion > currentVersion.major + 1
        ) {
            revert DynamicsErrors.InvalidAliceNetNodeVersion(newVersion, currentVersion);
        }
        if (binaryHash == 0 || binaryHash == currentVersion.binaryHash) {
            revert DynamicsErrors.InvalidAliceNetNodeHash(binaryHash, currentVersion.binaryHash);
        }
        _aliceNetCanonicalVersion = newVersion;
        emit NewAliceNetNodeVersionAvailable(newVersion);
    }

    // Internal function to change the dynamic values in a epoch in the future.
    // @param relativeExecutionEpoch the relative execution epoch in which the new
    // changes will become active.
    // @param newValue DynamicValue struct with the new values.
    function _changeDynamicValues(
        uint32 relativeExecutionEpoch,
        DynamicValues memory newValue
    ) internal {
        _addNode(_computeExecutionEpoch(relativeExecutionEpoch), newValue);
    }

    // Add a new node (in the future) to dynamic linked list and emit the event that
    // will be listened by the side chain.
    // @param executionEpoch the epoch where the new values will become active in
    // the side chain.
    // @param value the new dynamic values.
    function _addNode(uint32 executionEpoch, DynamicValues memory value) internal {
        // The new value is encoded and a new storage contract is deployed with its data
        // before adding the new node.
        bytes memory encodedData = _encodeDynamicValues(value);
        address dataAddress = _deployStorage(encodedData);
        _dynamicValues.addNode(executionEpoch, dataAddress);
        emit DynamicValueChanged(executionEpoch, encodedData);
    }

    // Internal function to compute the execution epoch. This function gets the
    // latest epoch from the snapshots contract and sums the
    // `relativeExecutionEpoch`. The `relativeExecutionEpoch` should respect the
    // configuration requirements.
    // @param relativeExecutionEpoch the relative execution epoch
    // @return the absolute execution epoch
    function _computeExecutionEpoch(uint32 relativeExecutionEpoch) internal view returns (uint32) {
        Configuration memory config = _configuration;
        if (
            relativeExecutionEpoch < config.minEpochsBetweenUpdates ||
            relativeExecutionEpoch > config.maxEpochsBetweenUpdates
        ) {
            revert DynamicsErrors.InvalidScheduledDate(
                relativeExecutionEpoch,
                config.minEpochsBetweenUpdates,
                config.maxEpochsBetweenUpdates
            );
        }
        uint32 currentEpoch = uint32(ISnapshots(_snapshotsAddress()).getEpoch());
        uint32 executionEpoch = relativeExecutionEpoch + currentEpoch;
        return executionEpoch;
    }

    // Internal function to decode a dynamic value struct from a storage contract.
    // @param addr the address of the storage contract.
    // @return the decoded Dynamic value struct.
    function _decodeDynamicValues(
        address addr
    ) internal view returns (DynamicValues memory values) {
        uint256 ptr;
        uint256 retPtr;
        uint8[8] memory sizes = [8, 24, 32, 32, 32, 64, 64, 128];
        uint256 dynamicValuesTotalSize = 48;
        uint256 extCodeSize;
        assembly ("memory-safe") {
            ptr := mload(0x40)
            retPtr := values
            extCodeSize := extcodesize(addr)
            extcodecopy(addr, ptr, 0, extCodeSize)
        }
        if (extCodeSize == 0 || extCodeSize < dynamicValuesTotalSize) {
            revert DynamicsErrors.InvalidExtCodeSize(addr, extCodeSize);
        }

        for (uint8 i = 0; i < sizes.length; i++) {
            uint8 size = sizes[i];
            assembly ("memory-safe") {
                mstore(retPtr, shr(sub(256, size), mload(ptr)))
                ptr := add(ptr, div(size, 8))
                retPtr := add(retPtr, 0x20)
            }
        }
    }

    // Internal function to encode a dynamic value struct in a bytes array.
    // @param newValue the dynamic struct to be encoded.
    // @return the encoded Dynamic value struct.
    function _encodeDynamicValues(
        DynamicValues memory newValue
    ) internal pure returns (bytes memory) {
        bytes memory data = abi.encodePacked(
            newValue.encoderVersion,
            newValue.proposalTimeout,
            newValue.preVoteTimeout,
            newValue.preCommitTimeout,
            newValue.maxBlockSize,
            newValue.dataStoreFee,
            newValue.valueStoreFee,
            newValue.minScaledTransactionFee
        );
        return data;
    }

    // Internal function to compute the compacted version of the aliceNet node. The
    // compacted version basically the sum of the major, minor and patch versions
    // shifted to corresponding places to avoid collisions.
    // @param majorVersion major version of the aliceNet Node.
    // @param minorVersion minor version of the aliceNet Node.
    // @param patch patch version of the aliceNet Node.
    function _computeCompactedVersion(
        uint256 majorVersion,
        uint256 minorVersion,
        uint256 patch
    ) internal pure returns (uint256 fullVersion) {
        assembly ("memory-safe") {
            fullVersion := or(or(shl(64, majorVersion), shl(32, minorVersion)), patch)
        }
    }
}