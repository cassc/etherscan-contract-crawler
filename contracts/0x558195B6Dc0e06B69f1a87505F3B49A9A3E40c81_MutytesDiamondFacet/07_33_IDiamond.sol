// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IDiamondReadable } from "./readable/IDiamondReadable.sol";
import { IDiamondWritable } from "./writable/IDiamondWritable.sol";

/**
 * @title Diamond read and write operations interface
 */
interface IDiamond is IDiamondReadable, IDiamondWritable {}