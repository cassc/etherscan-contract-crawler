// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {ICreators} from "./interfaces/ICreators.sol";
import {IMetadata} from "./interfaces/IMetadata.sol";
import {IProjects} from "./interfaces/IProjects.sol";
import {IRaises} from "./interfaces/IRaises.sol";
import {IMetadataResolver} from "./interfaces/IMetadataResolver.sol";
import {ICreatorAuth} from "./interfaces/ICreatorAuth.sol";
import {IControllable} from "./interfaces/IControllable.sol";
import {Controllable} from "./abstract/Controllable.sol";
import {RaiseToken} from "./libraries/RaiseToken.sol";
import {RaiseParams} from "./structs/Raise.sol";
import {TierParams} from "./structs/Tier.sol";

/// @title Creators - Creator interface
/// @notice Creators interact with this contract to create projects, configure
/// mints, and manage token metadata.
contract Creators is ICreators, Controllable {
    using RaiseToken for uint256;

    string public constant NAME = "Creators";
    string public constant VERSION = "0.0.1";

    address public creatorAuth;
    address public metadata;
    address public projects;
    address public raises;

    modifier onlyCreator() {
        if (ICreatorAuth(creatorAuth).denied(msg.sender)) {
            revert Forbidden();
        }
        _;
    }

    modifier onlyProjectOwner(uint32 projectId) {
        if (msg.sender != IProjects(projects).ownerOf(projectId)) {
            revert Forbidden();
        }
        _;
    }

    modifier onlyPendingOwner(uint32 projectId) {
        if (msg.sender != IProjects(projects).pendingOwnerOf(projectId)) {
            revert Forbidden();
        }
        _;
    }

    constructor(address _controller) Controllable(_controller) {}

    /// @inheritdoc ICreators
    function createProject() external override onlyCreator returns (uint32) {
        return IProjects(projects).create(msg.sender);
    }

    /// @inheritdoc ICreators
    function transferOwnership(uint32 projectId, address newOwner)
        external
        override
        onlyCreator
        onlyProjectOwner(projectId)
    {
        if (ICreatorAuth(creatorAuth).denied(newOwner)) revert Forbidden();
        return IProjects(projects).transferOwnership(projectId, newOwner);
    }

    /// @inheritdoc ICreators
    function acceptOwnership(uint32 projectId) external override onlyCreator onlyPendingOwner(projectId) {
        return IProjects(projects).acceptOwnership(projectId);
    }

    /// @inheritdoc ICreators
    function createRaise(uint32 projectId, RaiseParams memory params, TierParams[] memory tiers)
        external
        override
        onlyCreator
        onlyProjectOwner(projectId)
        returns (uint32)
    {
        return IRaises(raises).create(projectId, params, tiers);
    }

    /// @inheritdoc ICreators
    function updateRaise(uint32 projectId, uint32 raiseId, RaiseParams memory params, TierParams[] memory tiers)
        external
        override
        onlyCreator
        onlyProjectOwner(projectId)
    {
        IRaises(raises).update(projectId, raiseId, params, tiers);
    }

    /// @inheritdoc ICreators
    function cancelRaise(uint32 projectId, uint32 raiseId) external override onlyCreator onlyProjectOwner(projectId) {
        IRaises(raises).cancel(projectId, raiseId);
    }

    /// @inheritdoc ICreators
    function closeRaise(uint32 projectId, uint32 raiseId) external override onlyCreator onlyProjectOwner(projectId) {
        IRaises(raises).close(projectId, raiseId);
    }

    /// @inheritdoc ICreators
    function withdrawRaiseFunds(uint32 projectId, uint32 raiseId, address receiver)
        external
        override
        onlyCreator
        onlyProjectOwner(projectId)
    {
        IRaises(raises).withdraw(projectId, raiseId, receiver);
    }

    /// @inheritdoc ICreators
    function setCustomURI(uint256 tokenId, string memory customURI)
        external
        override
        onlyCreator
        onlyProjectOwner(tokenId.projectId())
    {
        IMetadata(metadata).setCustomURI(tokenId, customURI);
    }

    /// @inheritdoc ICreators
    function setCustomResolver(uint256 tokenId, IMetadataResolver customResolver)
        external
        override
        onlyCreator
        onlyProjectOwner(tokenId.projectId())
    {
        IMetadata(metadata).setCustomResolver(tokenId, customResolver);
    }

    /// @inheritdoc IControllable
    function setDependency(bytes32 _name, address _contract)
        external
        override (Controllable, IControllable)
        onlyController
    {
        if (_contract == address(0)) revert ZeroAddress();
        else if (_name == "creatorAuth") _setCreatorAuth(_contract);
        else if (_name == "metadata") _setMetadata(_contract);
        else if (_name == "projects") _setProjects(_contract);
        else if (_name == "raises") _setRaises(_contract);
        else revert InvalidDependency(_name);
    }

    function _setCreatorAuth(address _creatorAuth) internal {
        emit SetCreatorAuth(creatorAuth, _creatorAuth);
        creatorAuth = _creatorAuth;
    }

    function _setMetadata(address _metadata) internal {
        emit SetMetadata(metadata, _metadata);
        metadata = _metadata;
    }

    function _setProjects(address _projects) internal {
        emit SetProjects(projects, _projects);
        projects = _projects;
    }

    function _setRaises(address _raises) internal {
        emit SetRaises(raises, _raises);
        raises = _raises;
    }
}