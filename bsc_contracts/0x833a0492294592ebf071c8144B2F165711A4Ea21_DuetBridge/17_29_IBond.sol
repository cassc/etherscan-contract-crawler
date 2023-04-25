// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IBond {
    function redeem(address[] memory epochs, uint256[] memory amounts, address to) external;
}