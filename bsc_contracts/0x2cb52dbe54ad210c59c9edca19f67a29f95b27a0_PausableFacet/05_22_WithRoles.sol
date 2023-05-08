// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {LibAccessControl} from "./LibAccessControl.sol";

contract WithRoles {
  modifier onlyRole(bytes32 role) {
    LibAccessControl.checkRole(role);
    _;
  }
}