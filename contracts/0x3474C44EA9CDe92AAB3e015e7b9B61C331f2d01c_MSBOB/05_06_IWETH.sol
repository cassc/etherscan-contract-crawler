// SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.17;

interface IWETH {
    function deposit() external payable;

    function withdraw(uint256) external;
}