// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.6.0 <=0.8.9;

import "./BurnableToken.sol";

contract LPToken is BurnableToken {
    constructor(uint8 _decimals) {
        _initialize("Swingby BTC LP Token", "sbBTC", _decimals, 0, true);
    }
}