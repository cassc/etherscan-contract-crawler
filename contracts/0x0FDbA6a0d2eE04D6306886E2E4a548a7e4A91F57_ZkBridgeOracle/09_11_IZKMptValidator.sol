// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IZKMptValidator {
    struct Receipt {
        bytes32 receiptHash;
        bytes32 logsHash;
    }

    function validateMPT(bytes calldata _proof) external view returns (Receipt memory receipt);
}