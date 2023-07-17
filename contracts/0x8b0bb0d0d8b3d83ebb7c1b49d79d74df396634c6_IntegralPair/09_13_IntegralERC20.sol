// SPDX-License-Identifier: GPL-3.0-or-later
// Deployed with donations via Gitcoin GR9

pragma solidity 0.7.5;

import 'AbstractERC20.sol';

contract IntegralERC20 is AbstractERC20 {
    string public constant override name = 'Integral LP';
    string public constant override symbol = 'ITGR-LP';
    uint8 public constant override decimals = 18;

    constructor() {
        _init(name);
    }

    /**
     * @dev This function should be called on the forked chain to prevent
     * replay attacks
     */
    function updateDomainSeparator() external {
        _init(name);
    }
}