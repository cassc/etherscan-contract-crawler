// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface IMaidsToken {
    function mint(address to, uint256 amount) external;
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
}