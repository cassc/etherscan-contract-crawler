// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.7.4;

interface IPoolSwapCallback {
    function safeAutoTransferFrom(address token, address from, address to, uint value) external;
}