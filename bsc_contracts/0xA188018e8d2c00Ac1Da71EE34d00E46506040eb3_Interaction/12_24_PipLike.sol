// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface PipLike {
    function peek() external view returns (bytes32, bool);
}