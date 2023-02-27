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

import {Clones} from "@openzeppelin/contracts/proxy/Clones.sol";
import {INodeRegistry} from "./interfaces/INodeRegistry.sol";
import {Memberships, ImmutableCollectionData} from "./Memberships.sol";
import {AccessControlData} from "./Resource.sol";

/// @notice Configuration data required when deploying a new collection.
struct CreateMembershipsConfig {
    string name;
    string symbol;
    string baseURI;
    address owner;
    uint64 controlNodeId;
    string metadata;
}

/// @notice A factory that deploys memberships contract.
contract MembershipsFactory {
    // ---
    // Errors
    // ---

    /// @notice An unauthorized address attempted to create a memberships
    /// contract.
    error NotAuthorized();

    // ---
    // Events
    // ---

    /// @notice A new memberships contract was deployed
    event MembershipsCreated(Memberships indexed memberships);

    // ---
    // Storage
    // ---

    /// @notice Reference to the memberships implementation that will be cloned.
    Memberships public immutable implementation;

    /// @notice Reference to the node registry of the protocol.
    INodeRegistry public immutable nodeRegistry;

    // ---
    // Constructor
    // ---

    constructor(INodeRegistry _nodeRegistry, Memberships _implementation) {
        implementation = _implementation;
        nodeRegistry = _nodeRegistry;
    }

    // ---
    // Public functionality
    // ---

    /// @notice Deploy a new memberships NFT contract.
    function createMemberships(CreateMembershipsConfig calldata config)
        external
        returns (Memberships memberships)
    {
        // msg.sender must be authorized to manage the control node of the new
        // memberships collection.
        if (
            !nodeRegistry.isAuthorizedAddressForNode(
                config.controlNodeId,
                msg.sender
            )
        ) {
            revert NotAuthorized();
        }

        memberships = Memberships(Clones.clone(address(implementation)));
        memberships.init(
            config.owner,
            AccessControlData({
                nodeRegistry: nodeRegistry,
                controlNodeId: config.controlNodeId
            }),
            config.metadata,
            ImmutableCollectionData({
                name: config.name,
                symbol: config.symbol,
                baseURI: config.baseURI
            })
        );
        emit MembershipsCreated(memberships);
    }
}