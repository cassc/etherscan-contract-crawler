// SPDX-License-Identifier: LGPL-3.0-only
// Copyright 2023 Proof Holdings Inc.

import {EnumerableSet} from "openzeppelin-contracts/utils/structs/EnumerableSet.sol";
import {IGenArt721CoreContractV3_Base} from "artblocks-contracts/interfaces/0.8.x/IGenArt721CoreContractV3_Base.sol";
import {IGenArt721CoreContractV3_Mintable} from "./IGenArt721CoreContractV3_Mintable.sol";

pragma solidity >=0.8.17;

contract MinterMultiplexer is IGenArt721CoreContractV3_Mintable {
    using EnumerableSet for EnumerableSet.AddressSet;

    // =================================================================================================================
    //                          Errors
    // =================================================================================================================

    /**
     * @notice Thrown when a minter is not approved for a given project.
     */
    error MinterNotApprovedForProject(uint256 projectId, address minter);

    /**
     * @notice Thrown when a caller is not allowed by the AdminACL to call a given function on this contract .
     */
    error ActionNotAllowedByAdminACL(address operator, bytes4 selector);

    /**
     * @notice Thrown when a project does not exist.
     */
    error NonexistentProject(uint256 projectId);

    // =================================================================================================================
    //                          Constants
    // =================================================================================================================

    /**
     * @notice The artblocks IV3 core contract contract.
     */
    IGenArt721CoreContractV3_Base internal immutable _genArtCoreContract;

    // =================================================================================================================
    //                          Storage
    // =================================================================================================================

    /**
     * @notice A mapping of project IDs to the minters approved for each project.
     */
    mapping(uint256 => EnumerableSet.AddressSet) internal _mintersByProject;

    /**
     * @notice A set of minters that are allowed to mint for any project if no minters are explicitly set.
     */
    EnumerableSet.AddressSet internal _fallbackMinters;

    constructor(IGenArt721CoreContractV3_Base genart721) {
        _genArtCoreContract = genart721;
    }

    // =================================================================================================================
    //                          Steering
    // =================================================================================================================

    /**
     * @notice Adds a minter for a given project.
     */
    function addMinterForProject(uint256 projectId, address minter)
        external
        onlyExistingProjects(projectId)
        onlyAllowedByAdminACL(this.addMinterForProject.selector)
    {
        _mintersByProject[projectId].add(minter);
    }

    /**
     * @notice Removes an approved minter for a given project.
     */
    function removeMinterForProject(uint256 projectId, address minter)
        external
        onlyAllowedByAdminACL(this.removeMinterForProject.selector)
    {
        _mintersByProject[projectId].remove(minter);
    }

    /**
     * @notice Returns all minters approved for a given project.
     */
    function mintersForProject(uint256 projectId)
        external
        view
        onlyExistingProjects(projectId)
        returns (address[] memory)
    {
        return _mintersByProject[projectId].values();
    }

    /**
     * @notice Adds a fallback minter.
     */
    function addFallbackMinter(address minter) external onlyAllowedByAdminACL(this.addFallbackMinter.selector) {
        _fallbackMinters.add(minter);
    }

    /**
     * @notice Removes an approved fallback minter.
     */
    function removeFallbackMinter(address minter) external onlyAllowedByAdminACL(this.removeFallbackMinter.selector) {
        _fallbackMinters.remove(minter);
    }

    /**
     * @notice Returns all fallback minters.
     */
    function fallbackMinters() external view returns (address[] memory) {
        return _fallbackMinters.values();
    }

    // =================================================================================================================
    //                          Minting
    // =================================================================================================================

    /**
     * @notice Forwards the minting call to the artblocks entry contract if the caller is approved for the given
     * project.
     */
    function mint_Ecf(address to, uint256 projectId, address sender) external returns (uint256 _tokenId) {
        if (!_isMinterForProject(projectId, msg.sender)) {
            revert MinterNotApprovedForProject(projectId, msg.sender);
        }

        return _genArtCoreContract.mint_Ecf(to, projectId, sender);
    }

    // =================================================================================================================
    //                          Internal
    // =================================================================================================================

    /**
     * @notice Returns true if the given minter is approved for the given project.
     */
    function _isMinterForProject(uint256 projectId, address minter) internal view virtual returns (bool) {
        EnumerableSet.AddressSet storage minters = _mintersByProject[projectId];

        if (minters.contains(minter)) {
            return true;
        }

        if (minters.length() == 0) {
            return _fallbackMinters.contains(minter);
        }

        return false;
    }

    /**
     * @notice Ensures that the caller is approved by the AdminACL to call the given function.
     */
    modifier onlyAllowedByAdminACL(bytes4 _selector) {
        if (!_genArtCoreContract.adminACLAllowed(msg.sender, address(this), _selector)) {
            revert ActionNotAllowedByAdminACL(msg.sender, _selector);
        }
        _;
    }

    /**
     * @notice Ensures that a given project exists.
     */
    modifier onlyExistingProjects(uint256 projectId) {
        if (projectId >= _genArtCoreContract.nextProjectId()) {
            revert NonexistentProject(projectId);
        }
        _;
    }
}