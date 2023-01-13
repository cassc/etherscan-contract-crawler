// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface IWrapped {
    function deposit() external payable;
    function withdraw(uint amount) external;
}