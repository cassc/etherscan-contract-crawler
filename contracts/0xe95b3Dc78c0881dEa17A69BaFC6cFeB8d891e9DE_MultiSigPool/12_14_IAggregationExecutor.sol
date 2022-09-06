// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
interface IAggregationExecutor {
    function callBytes(bytes calldata data) external payable;
}