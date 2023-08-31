// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

interface IClowderCallee {
    function clowderCall(bytes calldata data) external;
}