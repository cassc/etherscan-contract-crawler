// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

interface BAPMethaneInterface {
    function claim(address, uint256) external;

    function pay(uint256, uint256) external;
}