// SPDX-License-Identifier: GPL-3.0
// Docgen-SOLC: 0.8.15

pragma solidity ^0.8.15;

import { IOwned } from "../IOwned.sol";

interface ICloneRegistry is IOwned {
  function cloneExists(address clone) external view returns (bool);

  function addClone(
    bytes32 templateCategory,
    bytes32 templateId,
    address clone
  ) external;
}