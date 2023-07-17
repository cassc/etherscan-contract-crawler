// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

interface ILiquidate {
    function liquidate(address account) external;
}

interface ILiquidateArray {
    function liquidateArray(address account, uint256[] memory pids) external;
}