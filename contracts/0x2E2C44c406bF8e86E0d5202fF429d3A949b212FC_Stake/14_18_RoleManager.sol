// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.7.5;

/**
 * @title RoleManager
 * @notice Generic role manager to manage slashing and cooldown admin in StakedAaveV3.
 *         It implements a claim admin role pattern to safely migrate between different admin addresses
 * @author Aave
 **/
contract RoleManager {
  mapping(uint256 => address) private _admins;
  mapping(uint256 => address) private _pendingAdmins;

  event PendingAdminChanged(address indexed newPendingAdmin, uint256 role);
  event RoleClaimed(address indexed newAdming, uint256 role);

  modifier onlyRoleAdmin(uint256 role) {
    require(_admins[role] == msg.sender, 'CALLER_NOT_ROLE_ADMIN');
    _;
  }

  modifier onlyPendingRoleAdmin(uint256 role) {
    require(_pendingAdmins[role] == msg.sender, 'CALLER_NOT_PENDING_ROLE_ADMIN');
    _;
  }

  /**
   * @dev returns the admin associated with the specific role
   * @param role the role associated with the admin being returned
   **/
  function getAdmin(uint256 role) public view returns (address) {
    return _admins[role];
  }

  /**
   * @dev returns the pending admin associated with the specific role
   * @param role the role associated with the pending admin being returned
   **/
  function getPendingAdmin(uint256 role) public view returns (address) {
    return _pendingAdmins[role];
  }

  /**
   * @dev sets the pending admin for a specific role
   * @param role the role associated with the new pending admin being set
   * @param newPendingAdmin the address of the new pending admin
   **/
  function setPendingAdmin(uint256 role, address newPendingAdmin) public onlyRoleAdmin(role) {
    _pendingAdmins[role] = newPendingAdmin;
    emit PendingAdminChanged(newPendingAdmin, role);
  }

  /**
   * @dev allows the caller to become a specific role admin
   * @param role the role associated with the admin claiming the new role
   **/
  function claimRoleAdmin(uint256 role) external onlyPendingRoleAdmin(role) {
    _admins[role] = msg.sender;
    emit RoleClaimed(msg.sender, role);
  }

  function _initAdmins(uint256[] memory roles, address[] memory admins) internal {
    require(roles.length == admins.length, 'INCONSISTENT_INITIALIZATION');

    for (uint256 i = 0; i < roles.length; i++) {
      require(
        _admins[roles[i]] == address(0) && admins[i] != address(0),
        'ADMIN_CANNOT_BE_INITIALIZED'
      );
      _admins[roles[i]] = admins[i];
      emit RoleClaimed(admins[i], roles[i]);
    }
  }
}