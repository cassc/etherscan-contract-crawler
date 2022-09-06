// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

interface IPYESwapCallee {
    function pyeSwapCall(address sender, uint amount0, uint amount1, bytes calldata data) external;
}