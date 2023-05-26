// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

interface IBeepBoop {
    function spendBeepBoop(address user, uint256 amount) external;

    function depositBeepBoopFor(address user, uint256 amount) external;

    function depositBeepBoop(uint256 amount) external;
}