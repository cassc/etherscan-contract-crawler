// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IOperatorFilter {
    /// Tests whether `operator` is permitted to facilitate token transfers.
    function mayTransfer(address operator) external view returns (bool);
}