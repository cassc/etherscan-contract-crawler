// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { DiamondReadableController } from "./readable/DiamondReadableController.sol";
import { DiamondWritableController } from "./writable/DiamondWritableController.sol";

abstract contract DiamondController is
    DiamondReadableController,
    DiamondWritableController
{}