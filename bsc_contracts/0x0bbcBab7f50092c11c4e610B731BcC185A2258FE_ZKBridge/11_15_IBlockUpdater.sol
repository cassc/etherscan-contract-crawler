// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IBlockUpdater {
    function checkBlock(bytes32 blockHash, bytes32 receiptsRoot) external view returns (bool);
}