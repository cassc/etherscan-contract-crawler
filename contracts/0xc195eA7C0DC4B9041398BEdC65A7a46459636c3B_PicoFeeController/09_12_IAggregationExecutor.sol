// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

interface IAggregationExecutor {
    /**
     * @notice Make calls on `msgSender` with specified data
     * @param msgSender Address of 'caller'
     * @param data Encoded Bytes data specified with call
     */

    function callBytes(address msgSender, bytes calldata data) external payable; // 0x2636f7f8
}