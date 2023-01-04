// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {IControllable} from "./IControllable.sol";
import {IAnnotated} from "./IAnnotated.sol";
import {IMetadataResolver} from "./IMetadataResolver.sol";
import {RaiseParams} from "../structs/Raise.sol";
import {TierParams} from "../structs/Tier.sol";

interface ICreators is IControllable, IAnnotated {
    event SetCreatorAuth(address oldCreatorAuth, address newCreatorAuth);
    event SetMetadata(address oldMetadata, address newMetadata);
    event SetRaises(address oldRaises, address newRaises);
    event SetProjects(address oldProjects, address newProjects);

    /// @notice Create a new project. May only be called by approved creators.
    /// @return Created project ID.
    function createProject() external returns (uint32);

    /// @notice Transfer project ownership to new owner. The proposed owner must
    /// call `acceptOwnership` to complete the transfer. May only be called by
    /// current project owner.
    /// @param projectId uint32 project ID.
    /// @param newOwner address of proposed new owner.
    function transferOwnership(uint32 projectId, address newOwner) external;

    /// @notice Accept a proposed ownership transfer. May only be called by the
    /// proposed project owner address.
    /// @param projectId uint32 project ID.
    function acceptOwnership(uint32 projectId) external;

    /// @notice Create a new raise by project ID. May only be called by
    /// approved creators.
    /// @param projectId uint32 project ID.
    /// @param params RaiseParams raise configuration parameters struct.
    /// @param tiers TierParams[] array of tier configuration parameters structs.
    /// @return Created raise ID.
    function createRaise(uint32 projectId, RaiseParams memory params, TierParams[] memory tiers)
        external
        returns (uint32);

    /// @notice Update an existing raise by project ID and raise ID. May only be
    /// called by approved creators. May only be called while the raise's state is
    /// Active and phase is Scheduled.
    /// @param projectId uint32 project ID.
    /// @param raiseId uint32 raise ID.
    /// @param params RaiseParams raise configuration parameters struct.
    /// @param tiers TierParams[] array of tier configuration parameters structs.
    function updateRaise(uint32 projectId, uint32 raiseId, RaiseParams memory params, TierParams[] memory tiers)
        external;

    /// @notice Cancel a raise. May only be called by project owner. May only be
    /// called while raise state is Active. Sets state to Cancelled.
    /// @param projectId uint32 project ID.
    /// @param raiseId uint32 raise ID.
    function cancelRaise(uint32 projectId, uint32 raiseId) external;

    /// @notice Close a raise. May only be called by project owner. May only be
    /// called if raise state is Active and raise goal is met. Sets state to Funded.
    /// @param projectId uint32 project ID.
    /// @param raiseId uint32 raise ID.
    function closeRaise(uint32 projectId, uint32 raiseId) external;

    /// @notice Withdraw raise funds to given `receiver` address. May only be called
    /// by project owner. May only be called if raise state is Funded.
    /// @param projectId uint32 project ID.
    /// @param raiseId uint32 raise ID.
    /// @param receiver address send funds to this address.
    function withdrawRaiseFunds(uint32 projectId, uint32 raiseId, address receiver) external;

    /// @notice Set a custom metadata URI for the given token ID. May only be
    /// called by project owner
    /// @param tokenId uint256 token ID.
    /// @param customURI string metadata URI.
    function setCustomURI(uint256 tokenId, string memory customURI) external;

    /// @notice Set a custom metadata resolver contract for the given token ID.
    /// May only be called by project owner.
    /// @param tokenId uint256 token ID.
    /// @param customResolver IMetadataResolver address of a contract
    /// implementing IMetadataResolver interface.
    function setCustomResolver(uint256 tokenId, IMetadataResolver customResolver) external;
}