// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

interface IStrategyContract {
    function releaseToken(uint256 amount, address token) external;
}