// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

abstract contract Deadline {
    modifier checkDeadline(uint256 deadline) {
        require(block.timestamp <= deadline, "Transaction too old");
        _;
    }
}