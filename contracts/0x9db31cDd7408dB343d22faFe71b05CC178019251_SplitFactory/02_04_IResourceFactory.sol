// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {INodeRegistry} from "./INodeRegistry.sol";

/// @notice Factory that launches on-chain resources, keyed by an address, that
/// are intended to be cataloged within the Metalabel universe.
interface IResourceFactory {
    /// @notice Broadcast an arbitrary message associated with the resource.
    event ResourceBroadcast(
        address indexed resource,
        string topic,
        string message
    );

    /// @notice Return the node registry contract address.
    function nodeRegistry() external view returns (INodeRegistry);

    /// @notice Return the control node ID for a given resource.
    function controlNode(address resource)
        external
        view
        returns (uint64 nodeId);

    /// @notice Return any stored broadcasts for a given resource and topic.
    function messageStorage(address resource, string calldata topic)
        external
        view
        returns (string memory message);

    /// @notice Emit an on-chain message for a given resource. msg.sender must
    /// be authorized to manage the resource's control node.
    function broadcast(
        address resource,
        string calldata topic,
        string calldata message
    ) external;

    /// @notice Emit an on-chain message and write to contract storage for a
    /// given resource. msg.sender must be authorized to manage the resource's
    /// control node.
    function broadcastAndStore(
        address resource,
        string calldata topic,
        string calldata message
    ) external;
}