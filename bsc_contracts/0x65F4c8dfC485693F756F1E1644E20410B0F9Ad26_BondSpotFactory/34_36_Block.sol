// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

abstract contract Block {
    function _blockTimestamp() internal view virtual returns (uint64) {
        return uint64(block.timestamp);
    }

    function _blockNumber() internal view virtual returns (uint64) {
        return uint64(block.number);
    }
}