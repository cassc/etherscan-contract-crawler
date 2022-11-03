// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IMultichain {
    function anySwapOutUnderlying(
        address token,
        address to,
        uint256 amount,
        uint256 toChainID
    ) external;

    function anySwapOutNative(
        address token,
        address to,
        uint toChainID
    ) external payable;
}