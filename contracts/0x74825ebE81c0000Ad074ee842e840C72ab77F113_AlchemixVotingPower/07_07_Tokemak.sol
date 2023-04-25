//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

interface ITokemakPool {
    function balanceOf(address account) external view returns (uint256);
    function approve(address spender, uint256 amount) external;
    function deposit(uint256 amount) external;
}