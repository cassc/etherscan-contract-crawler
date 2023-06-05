// SPDX-License-Identifier: GPL-3.0
// Docgen-SOLC: 0.8.15

pragma solidity ^0.8.15;

import { IOwned } from "../IOwned.sol";

interface IAdminProxy is IOwned {
  function execute(address target, bytes memory callData) external returns (bool, bytes memory);
}