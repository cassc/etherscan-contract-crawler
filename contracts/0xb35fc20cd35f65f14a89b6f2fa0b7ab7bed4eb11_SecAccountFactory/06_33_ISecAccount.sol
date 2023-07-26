// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.12;

interface ISecAccount {
    function registerSuccess() external;
    function updateOwner(address newOwner) external;
    function owner() external returns (address);
}