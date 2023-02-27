// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/*

███╗   ███╗███████╗████████╗ █████╗ ██╗      █████╗ ██████╗ ███████╗██╗
████╗ ████║██╔════╝╚══██╔══╝██╔══██╗██║     ██╔══██╗██╔══██╗██╔════╝██║
██╔████╔██║█████╗     ██║   ███████║██║     ███████║██████╔╝█████╗  ██║
██║╚██╔╝██║██╔══╝     ██║   ██╔══██║██║     ██╔══██║██╔══██╗██╔══╝  ██║
██║ ╚═╝ ██║███████╗   ██║   ██║  ██║███████╗██║  ██║██████╔╝███████╗███████╗
╚═╝     ╚═╝╚══════╝   ╚═╝   ╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝╚═════╝ ╚══════╝╚══════╝


Deployed by Metalabel with 💖 as a permanent application on the Ethereum blockchain.

Metalabel is a growing universe of tools, knowledge, and resources for
metalabels and cultural collectives.

Our purpose is to establish the metalabel as key infrastructure for creative
collectives and to inspire a new culture of creative collaboration and mutual
support.

OUR SQUAD

Anna Bulbrook (Curator)
Austin Robey (Community)
Brandon Valosek (Engineer)
Ilya Yudanov (Designer)
Lauren Dorman (Engineer)
Rob Kalin (Board)
Yancey Strickler (Director)

https://metalabel.xyz

*/

import {IResourceFactory} from "./interfaces/IResourceFactory.sol";
import {INodeRegistry} from "./interfaces/INodeRegistry.sol";

/// @notice Minimal abstract implementation of a resource factory that deploys
/// on-chain resources that can be cataloged on the Metalabel protocol.
abstract contract ResourceFactory is IResourceFactory {
    // ---
    // Errors
    // ---

    /// @notice Unauthorized msg.sender attempted to interact with this
    /// collection
    error NotAuthorized();

    // ---
    // Storage
    // ---

    /// @inheritdoc IResourceFactory
    INodeRegistry public immutable nodeRegistry;

    /// @inheritdoc IResourceFactory
    mapping(address => uint64) public controlNode;

    // ---
    // Constructor
    // ---

    constructor(INodeRegistry _nodeRegistry) {
        nodeRegistry = _nodeRegistry;
    }

    // ---
    // Modifiers
    // ---

    /// @dev Make a function only callable by a msg.sender that is authorized to
    /// manage the control node of this resource
    modifier onlyAuthorized(address resource) {
        if (
            !nodeRegistry.isAuthorizedAddressForNode(
                controlNode[resource],
                msg.sender
            )
        ) {
            revert NotAuthorized();
        }
        _;
    }

    // ---
    // Permissioned functionality
    // ---

    /// @inheritdoc IResourceFactory
    function broadcast(
        address resource,
        string calldata topic,
        string calldata message
    ) external onlyAuthorized(resource) {
        emit ResourceBroadcast(resource, topic, message);
    }
}