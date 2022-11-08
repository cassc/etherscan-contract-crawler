// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

interface IWNative {
    function deposit() external payable;

    function withdraw(uint256) external;
}