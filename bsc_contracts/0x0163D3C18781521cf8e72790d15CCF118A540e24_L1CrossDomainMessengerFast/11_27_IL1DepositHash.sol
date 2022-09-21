// SPDX-License-Identifier: MIT
pragma solidity >0.8.8;

interface IL1DepositHash {
    function priorDepositInfoHash() external returns (bytes32);

    function currentDepositInfoHash() external returns (bytes32);

    function lastHashUpdateBlock() external returns (uint256);
}