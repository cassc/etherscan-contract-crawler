// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import {AccessControlEnumerable} from '../../../@openzeppelin/contracts/access/AccessControlEnumerable.sol';

/**
 * @dev Extension of {AccessControlEnumerable} that offer support for maintainer role.
 */
contract StandardAccessControlEnumerable is AccessControlEnumerable {
  struct Roles {
    address admin;
    address maintainer;
  }

  bytes32 public constant MAINTAINER_ROLE = keccak256('Maintainer');

  modifier onlyMaintainer() {
    require(
      hasRole(MAINTAINER_ROLE, msg.sender),
      'Sender must be the maintainer'
    );
    _;
  }

  function _setAdmin(address _account) internal {
    _setRoleAdmin(DEFAULT_ADMIN_ROLE, DEFAULT_ADMIN_ROLE);
    _setupRole(DEFAULT_ADMIN_ROLE, _account);
  }

  function _setMaintainer(address _account) internal {
    _setRoleAdmin(MAINTAINER_ROLE, DEFAULT_ADMIN_ROLE);
    _setupRole(MAINTAINER_ROLE, _account);
  }
}