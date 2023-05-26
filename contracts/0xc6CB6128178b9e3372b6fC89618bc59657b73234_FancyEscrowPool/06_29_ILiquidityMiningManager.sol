// SPDX-License-Identifier: MIT
// Forked from Merit Circle
pragma solidity 0.8.7;

import "./IBasePool.sol";

interface ILiquidityMiningManager {
    function getPoolAdded(address pool) external view returns(bool);
}