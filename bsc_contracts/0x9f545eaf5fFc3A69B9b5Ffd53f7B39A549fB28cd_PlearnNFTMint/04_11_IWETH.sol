// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.12;

interface IWETH {
    function deposit() external payable;

    function transfer(address to, uint256 value) external returns (bool);

    function withdraw(uint256) external;

    function approve(address guy, uint wad) external returns (bool);
}