// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

interface IWETH {
    function deposit() external payable;
    function approve(address spender, uint256 value) external returns (bool);
    function transfer(address to, uint256 value) external returns (bool);
}