// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

interface IWrapper {
    function deposit() external payable;
    function withdraw(uint256 amount) external;
}