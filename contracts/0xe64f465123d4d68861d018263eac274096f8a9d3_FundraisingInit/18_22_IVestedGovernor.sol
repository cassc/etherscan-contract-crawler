// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/**************************************

    security-contact:
    - [email protected]
    - [email protected]
    - [email protected]

**************************************/

import { IGovernorTimelock } from "../oz/interfaces/IGovernorTimelock.sol";

/**************************************

    VestedGovernor interface

 **************************************/

abstract contract IVestedGovernor is IGovernorTimelock {}