// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface IHoney {
    function spendEcoSystemBalance(address user, uint128 amount, uint256[] memory flowersWithBees, bytes memory data) external;
    function approve(address spender, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
}