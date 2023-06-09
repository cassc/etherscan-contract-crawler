// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

abstract contract PeripheryValidation {
    modifier checkDeadline(uint256 deadline) {
        require(block.timestamp <= deadline, "Transaction too old");
        _;
    }
}