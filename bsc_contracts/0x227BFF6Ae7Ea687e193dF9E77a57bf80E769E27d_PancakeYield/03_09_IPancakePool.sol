// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

interface IPancakePool {
    function deposit(uint256 _amount) external;
    function withdraw(uint256 _amount) external;
}