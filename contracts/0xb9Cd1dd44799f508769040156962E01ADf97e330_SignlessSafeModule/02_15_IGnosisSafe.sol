// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

interface IGnosisSafe {
    enum Operation {
        Call,
        DelegateCall
    }

    function execTransactionFromModule(
        address to,
        uint256 value,
        bytes calldata data,
        Operation operation
    ) external returns (bool success);

    function isOwner(address owner) external view returns (bool);
}