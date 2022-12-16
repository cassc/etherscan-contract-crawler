// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import {Bytes32} from "./../../utils/libraries/Bytes32.sol";
import {ProxyInitialization} from "./../../proxy/libraries/ProxyInitialization.sol";

library CheckpointsStorage {
    using Bytes32 for bytes32;
    using CheckpointsStorage for CheckpointsStorage.Layout;

    struct Layout {
        // checkpointId => timestamp
        mapping(bytes32 => uint256) checkpoints;
    }

    bytes32 internal constant LAYOUT_STORAGE_SLOT = bytes32(uint256(keccak256("animoca.core.lifecycle.Checkpoints.storage")) - 1);

    event CheckpointSet(bytes32 checkpointId, uint256 timestamp);

    /// @notice Sets the checkpoint.
    /// @dev Reverts if the checkpoint is already set.
    /// @dev Emits a {CheckpointSet} event if the timestamp is set to a non-zero value.
    /// @param checkpointId The checkpoint identifier.
    /// @param timestamp The checkpoint timestamp.
    function setCheckpoint(Layout storage s, bytes32 checkpointId, uint256 timestamp) internal {
        if (s.checkpoints[checkpointId] != 0) {
            revert(string(abi.encodePacked("Checkpoints: checkpoint '", checkpointId.toASCIIString(), "' already set")));
        }
        if (timestamp != 0) {
            s.checkpoints[checkpointId] = timestamp;
            emit CheckpointSet(checkpointId, timestamp);
        }
    }

    /// @notice Sets a batch of checkpoints.
    /// @dev Reverts if one of the checkpoints is already set.
    /// @dev Emits a {CheckpointSet} event for each timestamp set to a non-zero value.
    /// @param checkpointIds The checkpoint identifiers.
    /// @param timestamps The checkpoint timestamps.
    function batchSetCheckpoint(Layout storage s, bytes32[] calldata checkpointIds, uint256[] calldata timestamps) internal {
        uint256 length = checkpointIds.length;
        require(length == timestamps.length, "Checkpoints: wrong array length");
        unchecked {
            for (uint256 i; i != length; ++i) {
                s.setCheckpoint(checkpointIds[i], timestamps[i]);
            }
        }
    }

    /// @notice Sets the checkpoint to the current block timestamp.
    /// @dev Reverts if the checkpoint is set and the current block timestamp has already reached it.
    /// @dev Emits a {CheckpointSet} event.
    /// @param checkpointId The checkpoint identifier.
    function triggerCheckpoint(Layout storage s, bytes32 checkpointId) internal {
        s.enforceCheckpointNotReached(checkpointId);
        s.checkpoints[checkpointId] = block.timestamp;
        emit CheckpointSet(checkpointId, block.timestamp);
    }

    /// @notice Gets the checkpoint timestamp.
    /// @param checkpointId The checkpoint identifier.
    /// @return timestamp The timestamp associated to the checkpoint. A zero value indicates that the checkpoint is not set.
    function checkpoint(Layout storage s, bytes32 checkpointId) internal view returns (uint256 timestamp) {
        return s.checkpoints[checkpointId];
    }

    /// @notice Retrieves whether the checkpoint has been reached already.
    /// @param checkpointId The checkpoint identifier.
    /// @return reached True if the checkpoint has been set and the current block timestamp has already reached it, false otherwise.
    function checkpointReached(Layout storage s, bytes32 checkpointId) internal view returns (bool) {
        uint256 checkpoint_ = s.checkpoints[checkpointId];
        return checkpoint_ != 0 && block.timestamp >= checkpoint_;
    }

    /// @notice Ensures that the checkpoint has been reached already.
    /// @dev Reverts if the checkpoint is not set or if the current block timestamp has not reached it yet.
    /// @param checkpointId The checkpoint identifier.
    function enforceCheckpointReached(Layout storage s, bytes32 checkpointId) internal view {
        if (!s.checkpointReached(checkpointId)) {
            revert(string(abi.encodePacked("Checkpoints: checkpoint '", checkpointId.toASCIIString(), "' not reached yet")));
        }
    }

    /// @notice Ensures that the checkpoint has not been reached yet.
    /// @dev Reverts if checkpoint is set and the current block timestamp has already reached it.
    /// @param checkpointId The checkpoint identifier.
    function enforceCheckpointNotReached(Layout storage s, bytes32 checkpointId) internal view {
        if (s.checkpointReached(checkpointId)) {
            revert(string(abi.encodePacked("Checkpoints: checkpoint '", checkpointId.toASCIIString(), "' already reached")));
        }
    }

    function layout() internal pure returns (Layout storage s) {
        bytes32 position = LAYOUT_STORAGE_SLOT;
        assembly {
            s.slot := position
        }
    }
}