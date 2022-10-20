// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface ISwapper {
    function onSwapReceived(bytes calldata data) external;
}