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
import {Collection, ImmutableCollectionData} from "./Collection.sol";
import {AccessControlData} from "./Resource.sol";

/// @notice Configuration data required when deploying a new collection.
struct CreateCollectionConfig {
    string name;
    string symbol;
    string contractURI;
    address owner;
    uint64 controlNodeId;
    string metadata;
}

/// @notice A factory that deploys record collections.
contract CollectionFactory {
    // ---
    // Errors
    // ---

    /// @notice An unauthorized address attempted to create a collection.
    error NotAuthorized();

    // ---
    // Events
    // ---

    /// @notice A new collection was deployed
    event CollectionCreated(address indexed collection);

    // ---
    // Storage
    // ---

    /// @notice Reference to the collection implementation that will be cloned.
    Collection public immutable implementation;

    /// @notice Reference to the node registry of the protocol.
    INodeRegistry public immutable nodeRegistry;

    // ---
    // Constructor
    // ---

    constructor(INodeRegistry _nodeRegistry, Collection _implementation) {
        implementation = _implementation;
        nodeRegistry = _nodeRegistry;
    }

    // ---
    // Public functionality
    // ---

    /// @notice Deploy a new collection.
    function createCollection(CreateCollectionConfig calldata config)
        external
        returns (Collection collection)
    {
        // msg.sender must be authorized to manage the control node of the new
        // collection
        if (
            !nodeRegistry.isAuthorizedAddressForNode(
                config.controlNodeId,
                msg.sender
            )
        ) {
            revert NotAuthorized();
        }

        collection = Collection(Clones.clone(address(implementation)));
        collection.init(
            config.owner,
            AccessControlData({
                nodeRegistry: nodeRegistry,
                controlNodeId: config.controlNodeId
            }),
            config.metadata,
            ImmutableCollectionData({
                name: config.name,
                symbol: config.symbol,
                contractURI: config.contractURI
            })
        );
        emit CollectionCreated(address(collection));
    }
}