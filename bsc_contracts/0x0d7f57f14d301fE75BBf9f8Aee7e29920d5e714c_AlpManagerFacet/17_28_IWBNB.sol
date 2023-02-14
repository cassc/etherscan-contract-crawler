// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IWBNB {
    function deposit() external payable;

    function withdraw(uint) external;
}