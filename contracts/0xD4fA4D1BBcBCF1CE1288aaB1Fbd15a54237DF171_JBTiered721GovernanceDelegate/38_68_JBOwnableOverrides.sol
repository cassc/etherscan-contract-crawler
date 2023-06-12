// SPDX-License-Identifier: MIT
// Juicebox variation on OpenZeppelin Ownable

pragma solidity ^0.8.0;

import { JBOwner } from "./struct/JBOwner.sol";
import { IJBOwnable } from "./interfaces/IJBOwnable.sol";

import { IJBOperatable } from '@jbx-protocol/juice-contracts-v3/contracts/interfaces/IJBOperatable.sol';
import { IJBOperatorStore } from "@jbx-protocol/juice-contracts-v3/contracts/abstract/JBOperatable.sol";
import { IJBProjects } from "@jbx-protocol/juice-contracts-v3/contracts/interfaces/IJBProjects.sol";
import { Context } from "@openzeppelin/contracts/utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions and can grant other users permission to those functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner or an approved address.
 *
 * Supports meta-transactions.
 */
abstract contract JBOwnableOverrides is Context, IJBOwnable, IJBOperatable {
    //*********************************************************************//
    // --------------------------- custom errors --------------------------//
    //*********************************************************************//

    error UNAUTHORIZED();
    error INVALID_NEW_OWNER(address ownerAddress, uint256 projectId);

    //*********************************************************************//
    // ---------------- public immutable stored properties --------------- //
    //*********************************************************************//

    /** 
        @notice 
        A contract storing operator assignments.
    */
    IJBOperatorStore public immutable operatorStore;

    /**
        @notice
        The IJBProjects to use to get the owner of a project
     */
    IJBProjects public immutable projects;

    //*********************************************************************//
    // --------------------- public stored properties -------------------- //
    //*********************************************************************//

    /**
       @notice
       the JBOwner information
     */
    JBOwner public override jbOwner;

    //*********************************************************************//
    // -------------------------- constructor ---------------------------- //
    //*********************************************************************//

    /**
      @param _projects the JBProjects to use to get the owner of the project
      @param _operatorStore the operatorStore to use for the permissions
     */
    constructor(
        IJBProjects _projects,
        IJBOperatorStore _operatorStore
    ) {
        operatorStore = _operatorStore;
        projects = _projects;

        _transferOwnership(msg.sender);
    }

    //*********************************************************************//
    // ---------------------------- modifiers ---------------------------- //
    //*********************************************************************//

    /** 
        @notice
        Only allows the speficied account or an operator of the account to proceed. 

        @param _account The account to check for.
        @param _domain The domain namespace to look for an operator within. 
        @param _permissionIndex The index of the permission to check for. 
    */
    modifier requirePermission(
        address _account,
        uint256 _domain,
        uint256 _permissionIndex
    ) {
        _requirePermission(_account, _domain, _permissionIndex);
        _;
    }

     /** 
        @notice
        Only allows callers that have received permission from the projectOwner for this project.

        @param _permissionIndex The index of the permission to check for. 
    */
    modifier requirePermissionFromOwner(
        uint256 _permissionIndex
    ) {
        JBOwner memory _ownerData = jbOwner;

        address _owner = _ownerData.projectId == 0 ?
         _ownerData.owner : projects.ownerOf(_ownerData.projectId);

        _requirePermission(_owner, _ownerData.projectId, _permissionIndex);
        _;
    }

    /** 
        @notice
        Only allows the speficied account, an operator of the account to proceed, or a truthy override flag. 

        @param _account The account to check for.
        @param _domain The domain namespace to look for an operator within. 
        @param _permissionIndex The index of the permission to check for. 
        @param _override A condition to force allowance for.
    */
    modifier requirePermissionAllowingOverride(
        address _account,
        uint256 _domain,
        uint256 _permissionIndex,
        bool _override
    ) {
        _requirePermissionAllowingOverride(_account, _domain, _permissionIndex, _override);
        _;
    }

    //*********************************************************************//
    // --------------------------- public methods ------------------------ //
    //*********************************************************************//

    /**
     @notice Returns the address of the current project owner.
    */
    function owner() public view virtual returns (address) {
        JBOwner memory _ownerData = jbOwner;

        if(_ownerData.projectId == 0)
            return _ownerData.owner;

        return projects.ownerOf(_ownerData.projectId);
    }

    /**
       @notice Leaves the contract without owner. It will not be possible to call
       `onlyOwner`/`_checkOwner` functions anymore. Can only be called by the current owner.
     
       NOTE: Renouncing ownership will leave the contract without an owner,
       thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual {
        _checkOwner();
        _transferOwnership(address(0), 0);
    }

    /**
       @notice Transfers ownership of the contract to a new account (`newOwner`).
       Can only be called by the current owner.
       @param _newOwner the static address that should receive ownership
     */
    function transferOwnership(address _newOwner) public virtual {
        _checkOwner();
        if(_newOwner == address(0))
            revert INVALID_NEW_OWNER(_newOwner, 0);
            
        _transferOwnership(_newOwner, 0);
    }

    /**
       @notice Transfer ownershipt of the contract to a (Juicebox) project
       @dev ProjectID is limited to a uint88
       @param _projectId the project that should receive ownership
     */
    function transferOwnershipToProject(uint256 _projectId) public virtual {
        _checkOwner();
        if(_projectId == 0 || _projectId > type(uint88).max)
            revert INVALID_NEW_OWNER(address(0), _projectId);

        _transferOwnership(address(0), uint88(_projectId));
    }

    /**
       @notice Sets the permission index that allows other callers to perform operations on behave of the project owner
       @param _permissionIndex the permissionIndex to use for 'onlyOwner' calls
     */
    function setPermissionIndex(uint8 _permissionIndex) public virtual {
        _checkOwner();
        _setPermissionIndex(_permissionIndex);
    }

    //*********************************************************************//
    // -------------------------- internal methods ----------------------- //
    //*********************************************************************//

    /**
       @dev Sets the permission index that allows other callers to perform operations on behave of the project owner
       Internal function without access restriction.

       @param _permissionIndex the permissionIndex to use for 'onlyOwner' calls
     */
    function _setPermissionIndex(uint8 _permissionIndex) internal virtual {
        jbOwner.permissionIndex = _permissionIndex;
        emit PermissionIndexChanged(_permissionIndex);
    }

    /**
       @dev helper to allow for drop-in replacement of OZ

       @param _newOwner the static address that should become the owner of this contract
     */
    function _transferOwnership(address _newOwner) internal virtual {
        _transferOwnership(_newOwner, 0);
    }

    /**
       @dev Transfers ownership of the contract to a new account (`_newOwner`) OR a project (`_projectID`).
       Internal function without access restriction.

       @param _newOwner the static owner address that should receive ownership
       @param _projectId the projectId this contract should follow ownership of
     */
    function _transferOwnership(address _newOwner, uint88 _projectId) internal virtual {
        // Can't both set a new owner and set a projectId to have ownership
        if (_projectId != 0 && _newOwner != address(0))
            revert INVALID_NEW_OWNER(_newOwner, _projectId); 
        // Load the owner data from storage
        JBOwner memory _ownerData = jbOwner;
        // Get an address representation of the old owner
        address _oldOwner = _ownerData.projectId == 0 ?
         _ownerData.owner : projects.ownerOf(_ownerData.projectId);
        // Update the storage to the new owner and reset the permissionIndex
        // this is to prevent clashing permissions for the new user/owner
        jbOwner = JBOwner({
            owner: _newOwner,
            projectId: _projectId,
            permissionIndex: 0
        });
        // Emit the ownership transferred event using an address representation of the new owner
        _emitTransferEvent(_oldOwner, _projectId == 0 ? _newOwner : projects.ownerOf(_projectId));
    }

    //*********************************************************************//
    // -------------------------- internal views ------------------------- //
    //*********************************************************************//

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        JBOwner memory _ownerData = jbOwner;

        address _owner = _ownerData.projectId == 0 ?
         _ownerData.owner : projects.ownerOf(_ownerData.projectId);
        
        _requirePermission(_owner, _ownerData.projectId, _ownerData.permissionIndex);
    }

    /** 
    @dev
    Require the message sender is either the account or has the specified permission.

    @param _account The account to allow.
    @param _domain The domain namespace within which the permission index will be checked.
    @param _permissionIndex The permission index that an operator must have within the specified domain to be allowed.
  */
    function _requirePermission(
        address _account,
        uint256 _domain,
        uint256 _permissionIndex
    ) internal view virtual {
        address _sender = _msgSender();
        if (
            _sender != _account &&
            !operatorStore.hasPermission(
                _sender,
                _account,
                _domain,
                _permissionIndex
            ) &&
            !operatorStore.hasPermission(_sender, _account, 0, _permissionIndex)
        ) revert UNAUTHORIZED();
    }

    /** 
    @dev
    Require the message sender is either the account, has the specified permission, or the override condition is true.

    @param _account The account to allow.
    @param _domain The domain namespace within which the permission index will be checked.
    @param _domain The permission index that an operator must have within the specified domain to be allowed.
    @param _override The override condition to allow.
  */
    function _requirePermissionAllowingOverride(
        address _account,
        uint256 _domain,
        uint256 _permissionIndex,
        bool _override
    ) internal view virtual {
        // short-circuit if the override is true
        if (_override) return;
        // Perform regular check otherwise
        _requirePermission(_account, _domain, _permissionIndex);
    }

    function _emitTransferEvent(address previousOwner, address newOwner) internal virtual;
}