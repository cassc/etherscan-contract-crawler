//SPDX-License-Identifier: UXUY
pragma solidity ^0.8.11;

interface IAnySwap {
    function anySwapOutUnderlying(address token, address to, uint amount, uint toChainID) external;

    function anySwapOutNative(address token, address to, uint toChainID) external payable;

    function anySwapOut(address token, address to, uint amount, uint toChainID) external;
}