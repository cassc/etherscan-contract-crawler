// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {OperatorFilterer} from "./OperatorFilterer.sol";

abstract contract DefaultOperatorFilterer is OperatorFilterer {
    address constant DEFAULT_SUBSCRIPTION = address(0x9dC5EE2D52d014f8b81D662FA8f4CA525F27cD6b);

    constructor() OperatorFilterer(DEFAULT_SUBSCRIPTION, true) {}
}