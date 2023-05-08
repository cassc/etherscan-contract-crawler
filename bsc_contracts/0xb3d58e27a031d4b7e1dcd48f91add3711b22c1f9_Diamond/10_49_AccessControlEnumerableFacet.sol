// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {AccessControlFacet} from "./AccessControlFacet.sol";
import {IAccessControlEnumerable} from "./IAccessControlEnumerable.sol";
import {WithRoles} from "./WithRoles.sol";
import {DEFAULT_ADMIN_ROLE} from "./Roles.sol";
import {LibAccessControlEnumerable} from "./LibAccessControlEnumerable.sol";
import {AccessControlEnumerableStorage} from "./AccessControlEnumerableStorage.sol";

contract AccessControlEnumerableFacet is AccessControlFacet, IAccessControlEnumerable {
  function getRoleMember(bytes32 _role, uint256 _index) external view override returns (address) {
    return LibAccessControlEnumerable.getRoleMember(_role, _index);
  }

  function getRoleMemberCount(bytes32 _role) external view override returns (uint256) {
    return LibAccessControlEnumerable.getRoleMemberCount(_role);
  }

  function getRoleMembers(bytes32 _role) external view returns (address[] memory) {
    return LibAccessControlEnumerable.getRoleMembers(_role);
  }
}