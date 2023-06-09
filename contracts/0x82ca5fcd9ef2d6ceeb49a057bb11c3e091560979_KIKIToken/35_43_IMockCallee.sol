// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

interface IMockCallee {
    function gibxCall(address sender, uint amount0, uint amount1, bytes calldata data) external;
}