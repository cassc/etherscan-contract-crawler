// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {Pausable} from "./abstract/Pausable.sol";
import {AllowList} from "./abstract/AllowList.sol";
import {IProjects} from "./interfaces/IProjects.sol";
import {IPausable} from "./interfaces/IPausable.sol";

/// @title Projects - Tracks projects and their owners
/// @notice A storage contract that tracks project IDs and owner accounts.
contract Projects is IProjects, AllowList, Pausable {
    string public constant NAME = "Projects";
    string public constant VERSION = "0.0.1";

    mapping(uint32 => address) public owners;
    mapping(uint32 => address) public pendingOwners;

    uint32 internal _nextProjectId;

    constructor(address _controller) AllowList(_controller) {}

    /// @inheritdoc IProjects
    function create(address owner) external override onlyAllowed whenNotPaused returns (uint32 id) {
        emit CreateProject(id = ++_nextProjectId);
        owners[id] = owner;
    }

    /// @inheritdoc IProjects
    function transferOwnership(uint32 projectId, address newOwner) external override onlyAllowed whenNotPaused {
        pendingOwners[projectId] = newOwner;
        emit TransferOwnership(projectId, owners[projectId], newOwner);
    }

    /// @inheritdoc IProjects
    function acceptOwnership(uint32 projectId) external override onlyAllowed whenNotPaused {
        address oldOwner = owners[projectId];
        address newOwner = pendingOwnerOf(projectId);
        owners[projectId] = newOwner;
        delete pendingOwners[projectId];
        emit AcceptOwnership(projectId, oldOwner, newOwner);
    }

    /// @inheritdoc IProjects
    function ownerOf(uint32 projectId) external view override returns (address owner) {
        owner = owners[projectId];
        if (owner == address(0)) {
            revert NotFound();
        }
    }

    /// @inheritdoc IProjects
    function pendingOwnerOf(uint32 projectId) public view override returns (address pendingOwner) {
        pendingOwner = pendingOwners[projectId];
        if (pendingOwner == address(0)) {
            revert NotFound();
        }
    }

    /// @inheritdoc IProjects
    function exists(uint32 projectId) external view override returns (bool) {
        return owners[projectId] != address(0);
    }

    /// @inheritdoc IPausable
    function pause() external override onlyController {
        _pause();
    }

    /// @inheritdoc IPausable
    function unpause() external override onlyController {
        _unpause();
    }
}