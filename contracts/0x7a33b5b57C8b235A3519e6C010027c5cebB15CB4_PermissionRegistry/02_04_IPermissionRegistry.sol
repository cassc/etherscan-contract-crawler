// SPDX-License-Identifier: GPL-3.0
// Docgen-SOLC: 0.8.15

pragma solidity ^0.8.15;

import { IOwned } from "../IOwned.sol";

struct Permission {
  bool endorsed;
  bool rejected;
}

interface IPermissionRegistry is IOwned {
  function setPermissions(address[] calldata targets, Permission[] calldata newPermissions) external;

  function endorsed(address target) external view returns (bool);

  function rejected(address target) external view returns (bool);
}