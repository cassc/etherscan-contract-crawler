// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {INodeRegistry} from "./INodeRegistry.sol";

/// @notice An on-chain resource that is intended to be cataloged within the
/// Metalabel universe
interface IResource {
    /// @notice Broadcast an arbitrary message.
    event Broadcast(string topic, string message);

    /// @notice Return the node registry contract address.
    function nodeRegistry() external view returns (INodeRegistry);

    /// @notice Return the control node ID for this resource.
    function controlNode() external view returns (uint64 nodeId);

    /// @notice Return any stored broadcasts for a given topic.
    function messageStorage(string calldata topic)
        external
        view
        returns (string memory message);

    /// @notice Emit an on-chain message. msg.sender must be authorized to
    /// manage this resource's control node
    function broadcast(string calldata topic, string calldata message) external;

    /// @notice Emit an on-chain message and write to contract storage.
    /// msg.sender must be authorized to manage the resource's control node
    function broadcastAndStore(string calldata topic, string calldata message)
        external;
}