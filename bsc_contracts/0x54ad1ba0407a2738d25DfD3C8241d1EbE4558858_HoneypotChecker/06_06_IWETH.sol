// SPDX-License-Identifier: MIT
pragma solidity >=0.4.0;

interface IWETH {
    function deposit() external payable;

    function transfer(address to, uint256 value) external returns (bool);
}