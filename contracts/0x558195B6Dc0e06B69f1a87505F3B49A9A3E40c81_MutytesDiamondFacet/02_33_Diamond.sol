// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IDiamond } from "./IDiamond.sol";
import { DiamondController } from "./DiamondController.sol";
import { DiamondReadable } from "./readable/DiamondReadable.sol";
import { DiamondWritable } from "./writable/DiamondWritable.sol";

/**
 * @title Diamond read and write operations implementation
 */
contract Diamond is IDiamond, DiamondReadable, DiamondWritable, DiamondController {}