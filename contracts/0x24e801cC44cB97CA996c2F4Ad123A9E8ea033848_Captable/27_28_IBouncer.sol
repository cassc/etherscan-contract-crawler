// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IBouncer {
    function isTransferAllowed(address from, address to, uint256 classId, uint256 amount)
        external
        view
        returns (bool);
}