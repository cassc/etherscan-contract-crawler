// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;
pragma abicoder v2;

interface IStargateEthVault {
    function balanceOf(address) external returns (uint256);
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
    function approve(address guy, uint wad) external returns (bool);
    function transferFrom(address src, address dst, uint wad) external returns (bool);
}