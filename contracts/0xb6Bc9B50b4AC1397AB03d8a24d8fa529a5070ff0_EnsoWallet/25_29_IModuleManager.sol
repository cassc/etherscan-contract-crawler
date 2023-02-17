// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

interface IModuleManager {
    enum Operation {Call, DelegateCall}

    function execTransactionFromModule(
        address to,
        uint256 value,
        bytes memory data,
        Operation operation
    ) external returns (bool success);

    function execTransactionFromModuleReturnData(
        address to,
        uint256 value,
        bytes memory data,
        Operation operation
    ) external returns (bool success, bytes memory returnData);
}