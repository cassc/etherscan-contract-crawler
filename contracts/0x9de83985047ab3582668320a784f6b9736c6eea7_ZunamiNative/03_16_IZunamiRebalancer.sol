//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './IStrategy.sol';

interface IZunamiRebalancer {
    function rebalance() external;
}