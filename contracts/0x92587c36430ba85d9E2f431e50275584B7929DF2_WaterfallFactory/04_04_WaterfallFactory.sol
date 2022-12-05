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
/// https://github.com/0xSplits/splits-waterfall/blob/master/src/WaterfallModuleFactory.sol
interface IWaterfallModuleFactory {
    function createWaterfallModule(
        address token,
        address nonWaterfallRecipient,
        address[] calldata recipients,
        uint256[] calldata thresholds
    ) external returns (address wm);
}

/// @notice Deploy waterfall modules from 0xSplits that can be cataloged as
/// resources in the Metalabel protocol.
contract WaterfallFactory is ResourceFactory {
    // ---
    // Events
    // ---

    /// @notice A new split was deployed.
    event WaterfallCreated(
        address indexed waterfall,
        uint64 nodeId,
        address token,
        address nonWaterfallRecipient,
        address[] recipients,
        uint256[] thresholds,
        string metadata
    );

    // ---
    // Storage
    // ---

    /// @notice The 0xSplit factory contract.
    IWaterfallModuleFactory public immutable waterfallFactory;

    // ---
    // Constructor
    // ---

    constructor(
        INodeRegistry _nodeRegistry,
        IWaterfallModuleFactory _waterfallFactory
    ) ResourceFactory(_nodeRegistry) {
        waterfallFactory = _waterfallFactory;
    }

    // ---
    // Public funcionality
    // ---

    /// @notice Launch a new split
    function createWaterfall(
        address token,
        address nonWaterfallRecipient,
        address[] calldata recipients,
        uint256[] calldata thresholds,
        uint64 controlNodeId,
        string calldata metadata
    ) external returns (address waterfall) {
        // Ensure msg.sender is authorized to manage the control node.
        if (
            !nodeRegistry.isAuthorizedAddressForNode(controlNodeId, msg.sender)
        ) {
            revert NotAuthorized();
        }

        // Deploy and store the split.
        waterfall = waterfallFactory.createWaterfallModule(
            token,
            nonWaterfallRecipient,
            recipients,
            thresholds
        );
        controlNode[waterfall] = controlNodeId;
        emit WaterfallCreated(
            waterfall,
            controlNodeId,
            token,
            nonWaterfallRecipient,
            recipients,
            thresholds,
            metadata
        );
    }
}