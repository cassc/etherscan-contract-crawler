// SPDX-License-Identifier: GNU
pragma solidity 0.7.4;
pragma experimental ABIEncoderV2;

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}