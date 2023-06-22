// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract TokenInterface {
    function balanceOf(address owner) external view returns (uint256 balance) {}
}