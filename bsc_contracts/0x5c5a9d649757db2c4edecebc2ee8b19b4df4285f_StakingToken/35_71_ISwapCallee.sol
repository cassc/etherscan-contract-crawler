// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.5.0;

interface ISwapCallee {
    function swapCall(address sender, uint amount0, uint amount1, bytes calldata data) external;
}