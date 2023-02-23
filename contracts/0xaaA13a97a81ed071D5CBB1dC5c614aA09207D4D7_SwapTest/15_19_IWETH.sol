// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

interface IWETH {

    function approve(address guy, uint wad) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
    function withdraw(uint) external;
}