// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {OperatorFiltererUpgradeable} from "./OperatorFiltererUpgradeable.sol";

abstract contract DefaultOperatorFiltererUpgradeable is
    OperatorFiltererUpgradeable
{
    function __DefaultOperatorFilterer_init(address s)
        internal
        onlyInitializing
    {
        OperatorFiltererUpgradeable.__OperatorFilterer_init(s, true);
    }
}