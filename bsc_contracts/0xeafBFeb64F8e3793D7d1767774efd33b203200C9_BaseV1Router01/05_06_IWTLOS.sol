// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

interface IWTLOS {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
    function balanceOf(address) external returns (uint);
}