// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

abstract contract IBYOVape {
    function balanceOf(address owner, uint256 index) external virtual view returns (uint256 balance);
}