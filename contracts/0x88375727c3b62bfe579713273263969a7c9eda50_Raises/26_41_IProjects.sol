// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {IAnnotated} from "./IAnnotated.sol";
import {ICommonErrors} from "./ICommonErrors.sol";
import {IPausable} from "./IPausable.sol";
import {IAllowList} from "./IAllowList.sol";

interface IProjects is IAllowList, IPausable, IAnnotated {
    event CreateProject(uint32 id);
    event TransferOwnership(uint32 indexed projectId, address indexed owner, address indexed newOwner);
    event AcceptOwnership(uint32 indexed projectId, address indexed owner, address indexed newOwner);

    /// @notice Create a new project owned by the given `owner`.
    /// @param owner address of project owner.
    /// @return uint32 Project ID.
    function create(address owner) external returns (uint32);

    /// @notice Start transfer of `projectId` to `newOwner`. The new owner must
    /// accept the transfer in order to assume ownership of the project.
    /// @param projectId uint32 project ID.
    /// @param newOwner address of proposed new owner.
    function transferOwnership(uint32 projectId, address newOwner) external;

    /// @notice Transfer ownership of `projectId` to `pendingOwner`.
    /// @param projectId uint32 project ID.
    function acceptOwnership(uint32 projectId) external;

    /// @notice Get owner of project by ID.
    /// @param projectId uint32 project ID.
    /// @return address of project owner.
    function ownerOf(uint32 projectId) external view returns (address);

    /// @notice Get pending owner of project by ID.
    /// @param projectId uint32 project ID.
    /// @return address of pending project owner.
    function pendingOwnerOf(uint32 projectId) external view returns (address);

    /// @notice Check whether project exists by ID.
    /// @param projectId uint32 project ID.
    /// @return True if project exists, false if project does not exist.
    function exists(uint32 projectId) external view returns (bool);
}