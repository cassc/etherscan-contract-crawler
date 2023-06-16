// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IContract {
    function transfer(address, uint256) external returns (bool);
    function owner() external returns (address);
}