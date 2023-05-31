// SPDX-License-Identifier: GPL-3.0-or-later
// Deployed with donations via Gitcoin GR9

pragma solidity 0.7.6;

import './libraries/AbstractERC20.sol';

contract TwapLPToken is AbstractERC20 {
    constructor() {
        name = 'Twap LP';
        symbol = 'TWAP-LP';
        decimals = 18;
    }
}