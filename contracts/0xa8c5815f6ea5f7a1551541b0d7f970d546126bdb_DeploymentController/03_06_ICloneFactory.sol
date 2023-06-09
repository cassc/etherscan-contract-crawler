// SPDX-License-Identifier: GPL-3.0
// Docgen-SOLC: 0.8.15

pragma solidity ^0.8.15;

import { IOwned } from "../IOwned.sol";
import { Template } from "./ITemplateRegistry.sol";

interface ICloneFactory is IOwned {
  function deploy(Template memory template, bytes memory data) external returns (address);
}