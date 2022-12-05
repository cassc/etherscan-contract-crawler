// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

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

import {INodeRegistry} from "./interfaces/INodeRegistry.sol";
import {ResourceFactory} from "./ResourceFactory.sol";

/// @dev Minimal needed interface from 0xSplits
/// https://github.com/0xSplits/splits-contracts/blob/main/contracts/interfaces/ISplitMain.sol
interface ISplitMain {
    function createSplit(
        address[] calldata accounts,
        uint32[] calldata percentAllocations,
        uint32 distributorFee,
        address controller
    ) external returns (address);
}

/// @notice Deploy splits from 0xSplits that can be cataloged as resources in the
/// Metalabel protocol.
contract SplitFactory is ResourceFactory {
    // ---
    // Events
    // ---

    /// @notice A new split was deployed.
    event SplitCreated(
        address indexed split,
        uint64 nodeId,
        address[] accounts,
        uint32[] percentAllocations,
        string metadata
    );

    // ---
    // Storage
    // ---

    /// @notice The 0xSplit factory contract.
    ISplitMain public immutable splits;

    // ---
    // Constructor
    // ---

    constructor(INodeRegistry _nodeRegistry, ISplitMain _splits)
        ResourceFactory(_nodeRegistry)
    {
        splits = _splits;
    }

    // ---
    // Public funcionality
    // ---

    /// @notice Launch a new split
    function createSplit(
        address[] calldata accounts,
        uint32[] calldata percentAllocations,
        uint32 distributorFee,
        uint64 controlNodeId,
        string calldata metadata
    ) external returns (address split) {
        // Ensure msg.sender is authorized to manage the control node.
        if (
            !nodeRegistry.isAuthorizedAddressForNode(controlNodeId, msg.sender)
        ) {
            revert NotAuthorized();
        }

        // Deploy and store the split.
        split = splits.createSplit(
            accounts,
            percentAllocations,
            distributorFee,
            address(0)
        );
        controlNode[split] = controlNodeId;
        emit SplitCreated(
            split,
            controlNodeId,
            accounts,
            percentAllocations,
            metadata
        );
    }
}