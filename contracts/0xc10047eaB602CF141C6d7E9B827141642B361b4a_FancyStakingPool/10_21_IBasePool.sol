// SPDX-License-Identifier: MIT
// Forked from Merit Circle
pragma solidity 0.8.7;
interface IBasePool {
    function distributeRewards(uint256 _amount) external;
    function setSFNCClaiming(bool _sFNCEnabled) external;
}