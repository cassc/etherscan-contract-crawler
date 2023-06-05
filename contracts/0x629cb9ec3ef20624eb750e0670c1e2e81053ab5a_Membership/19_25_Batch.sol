// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

/// @notice Batch calling mechanism on the implementing contract
/// @dev inspired by BoringBatchable and Multicall3
abstract contract Batch {
    struct Result {
        bool success;
        bytes returnData;
    }

    function batch(bool atomic, bytes[] calldata calls) public payable returns (Result[] memory results) {
        uint256 len = calls.length;
        results = new Result[](len);
        for (uint256 i = 0; i < len; i++) {
            Result memory result = results[i];
            (result.success, result.returnData) = address(this).delegatecall(calls[i]);
            require(result.success || !atomic, "BATCH_FAIL");
        }
    }
}