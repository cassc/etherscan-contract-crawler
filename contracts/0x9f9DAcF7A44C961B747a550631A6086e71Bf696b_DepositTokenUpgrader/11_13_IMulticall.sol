// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

interface IMulticall {
    struct Call {
        address target;
        bytes callData;
    }

    function aggregate(Call[] calldata calls) external returns (uint256 blockNumber, bytes[] memory returnData);
}