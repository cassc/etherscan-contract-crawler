// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import { MockRestrictedTickerRegistry } from "./MockRestrictedTickerRegistry.sol";

contract MockBrandCentral {

    MockRestrictedTickerRegistry public claimAuction;

    constructor() {
        claimAuction = new MockRestrictedTickerRegistry();
    }
}