// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract Multicall {
    struct Call {
        address target;
        bytes callData;
        uint256 gas;
    }

    struct Result {
        bool success;
        bytes returnData;
    }

    function tryAggregate(
        bool requireSuccess,
        Call[] memory calls
    ) public payable returns (Result[] memory returnData) {
        returnData = new Result[](calls.length);
        for (uint256 i = 0; i < calls.length; i++) {
            (bool success, bytes memory ret) = calls[i].target.call{gas: calls[i].gas}(calls[i].callData);

            if (requireSuccess) {
                require(success, "Multicall aggregate: call failed");
            }

            returnData[i] = Result(success, ret);
        }
    }
}