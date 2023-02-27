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

import {IResource} from "./interfaces/IResource.sol";
import {INodeRegistry} from "./interfaces/INodeRegistry.sol";

/// @notice Data stored for handling access control resolution.
struct AccessControlData {
    INodeRegistry nodeRegistry;
    uint64 controlNodeId;
    // 4 bytes remaining
}

/// @notice A resource that can be cataloged on the Metalabel protocol.
contract Resource is IResource {
    // ---
    // Errors
    // ---

    /// @notice Unauthorized msg.sender attempted to interact with this resource
    error NotAuthorized();

    // ---
    // Storage
    // ---

    /// @notice Access control data for this resource.
    AccessControlData public accessControl;

    // ---
    // Modifiers
    // ---

    /// @dev Make a function only callable by a msg.sender that is authorized to
    /// manage the control node of this resource
    modifier onlyAuthorized() {
        if (
            !accessControl.nodeRegistry.isAuthorizedAddressForNode(
                accessControl.controlNodeId,
                msg.sender
            )
        ) {
            revert NotAuthorized();
        }
        _;
    }

    // ---
    // Admin functionality
    // ---

    /// @inheritdoc IResource
    function broadcast(string calldata topic, string calldata message)
        external
        onlyAuthorized
    {
        emit Broadcast(topic, message);
    }

    // ---
    // Resource views
    // ---

    /// @inheritdoc IResource
    function nodeRegistry() external view virtual returns (INodeRegistry) {
        return accessControl.nodeRegistry;
    }

    /// @inheritdoc IResource
    function controlNode() external view virtual returns (uint64 nodeId) {
        return accessControl.controlNodeId;
    }

    /// @inheritdoc IResource
    function isAuthorized(address subject)
        public
        view
        virtual
        returns (bool authorized)
    {
        authorized = accessControl.nodeRegistry.isAuthorizedAddressForNode(
            accessControl.controlNodeId,
            subject
        );
    }
}