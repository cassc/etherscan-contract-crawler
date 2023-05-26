// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

interface ISwapCallee {
    function swapCall(address sender, uint amount0, uint amount1, bytes calldata data) external;
}