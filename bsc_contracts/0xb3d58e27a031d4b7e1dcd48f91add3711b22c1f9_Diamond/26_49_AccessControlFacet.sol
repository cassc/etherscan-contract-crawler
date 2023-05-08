// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IAccessControl} from "./IAccessControl.sol";
import {IAccessControlEnumerable} from "./IAccessControlEnumerable.sol";
import {WithRoles} from "./WithRoles.sol";
import {LibAccessControl} from "./LibAccessControl.sol";
import {AccessControlStorage} from "./AccessControlStorage.sol";
import {DEFAULT_ADMIN_ROLE} from "./Roles.sol";

contract AccessControlFacet is IAccessControl, WithRoles {
  function hasRole(bytes32 _role, address _account) external view override returns (bool) {
    AccessControlStorage storage ds = LibAccessControl.DS();
    return ds.roles[_role].members[_account];
  }

  function getRoleAdmin(bytes32 _role) external view override returns (bytes32) {
    AccessControlStorage storage ds = LibAccessControl.DS();
    return ds.roles[_role].adminRole;
  }

  function grantRole(
    bytes32 _role,
    address _account
  ) external override onlyRole(LibAccessControl.getRoleAdmin(_role)) {
    LibAccessControl.grantRole(_role, _account);
  }

  function revokeRole(
    bytes32 _role,
    address _account
  ) external override onlyRole(LibAccessControl.getRoleAdmin(_role)) {
    LibAccessControl.revokeRole(_role, _account);
  }

  function renounceRole(bytes32 _role, address _account) external override {
    LibAccessControl.renounceRole(_role, _account);
  }
}