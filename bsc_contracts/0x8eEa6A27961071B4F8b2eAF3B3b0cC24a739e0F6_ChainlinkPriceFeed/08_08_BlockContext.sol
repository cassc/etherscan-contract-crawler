// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

// wrap block.xxx functions for testing
// only support timestamp and number so far
abstract contract BlockContext {
    function _blockTimestamp() internal view virtual returns (uint256) {
        return block.timestamp;
    }

    function _blockNumber() internal view virtual returns (uint256) {
        return block.number;
    }
}