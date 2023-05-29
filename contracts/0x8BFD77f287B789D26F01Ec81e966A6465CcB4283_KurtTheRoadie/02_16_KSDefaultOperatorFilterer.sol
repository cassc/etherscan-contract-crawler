// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {KSOperatorFilterer} from "./KSOperatorFilterer.sol";

abstract contract KSDefaultOperatorFilterer is KSOperatorFilterer {
    address constant DEFAULT_SUBSCRIPTION = address(0x3cc6CddA760b79bAfa08dF41ECFA224f810dCeB6);

    constructor() KSOperatorFilterer(DEFAULT_SUBSCRIPTION, true) {}
}