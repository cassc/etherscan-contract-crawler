// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {AccessControlEnumerableStorage} from "./AccessControlEnumerableStorage.sol";
import {DEFAULT_ADMIN_ROLE} from "./Roles.sol";
import {AddressArrayLibUtils} from "../../utils/ArrayLibUtils.sol";

library LibAccessControlEnumerable {
  using AddressArrayLibUtils for address[];

  error Unauthorized(bytes32 role);
  error AlreadyHasRole(bytes32 role);
  error RoleNotSet(bytes32 role);
  error RenounceAccountNotMsgSender(address account);

  /**
   * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
   *
   * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
   * {RoleAdminChanged} not being emitted signaling this.
   *
   * _Available since v3.1._
   */
  event RoleAdminChanged(
    bytes32 indexed role,
    bytes32 indexed previousAdminRole,
    bytes32 indexed newAdminRole
  );

  /**
   * @dev Emitted when `account` is granted `role`.
   *
   * `sender` is the account that originated the contract call, an admin role
   * bearer except when using {AccessControl-_setupRole}.
   */
  event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

  /**
   * @dev Emitted when `account` is revoked `role`.
   *
   * `sender` is the account that originated the contract call:
   *   - if using `revokeRole`, it is the admin role bearer
   *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
   */
  event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

  bytes32 internal constant ACCESS_CONTROL_STORAGE_POSITION =
    keccak256("diamond.standard.accesscontrol.storage");

  function DS() internal pure returns (AccessControlEnumerableStorage storage ds) {
    bytes32 position = ACCESS_CONTROL_STORAGE_POSITION;
    assembly {
      ds.slot := position
    }
  }

  function hasRole(bytes32 role, address account) internal view returns (bool) {
    return DS().roles[role].members[account];
  }

  function checkRole(bytes32 role, address account) internal view {
    if (!hasRole(role, account)) revert Unauthorized(role);
  }

  function checkRole(bytes32 role) internal view {
    checkRole(role, msg.sender);
  }

  function getRoleAdmin(bytes32 role) internal view returns (bytes32) {
    return DS().roles[role].adminRole;
  }

  function grantRole(bytes32 role, address account) internal {
    if (!hasRole(role, account)) {
      DS().roles[role].members[account] = true;
      DS().roles[role].membersList.push(account);
      emit RoleGranted(role, account, msg.sender);
    } else revert AlreadyHasRole(role);
  }

  function revokeRole(bytes32 role, address account) internal {
    if (hasRole(role, account)) {
      DS().roles[role].members[account] = false;
      DS().roles[role].membersList.swapOut(account);
      emit RoleRevoked(role, account, msg.sender);
    } else revert RoleNotSet(role);
  }

  function setRoleAdmin(bytes32 role, bytes32 adminRole) internal {
    emit RoleAdminChanged(role, getRoleAdmin(role), adminRole);
    DS().roles[role].adminRole = adminRole;
  }

  function renounceRole(bytes32 role, address account) internal {
    if (account != msg.sender) revert RenounceAccountNotMsgSender(account);
    revokeRole(role, account);
  }

  function getRoleMember(bytes32 _role, uint256 _index) internal view returns (address) {
    AccessControlEnumerableStorage storage ds = DS();
    return ds.roles[_role].membersList[_index];
  }

  function getRoleMemberCount(bytes32 _role) internal view returns (uint256) {
    AccessControlEnumerableStorage storage ds = DS();
    return ds.roles[_role].membersList.length;
  }

  function getRoleMembers(bytes32 _role) internal view returns (address[] memory) {
    AccessControlEnumerableStorage storage ds = DS();
    return ds.roles[_role].membersList;
  }
}