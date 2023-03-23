// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IMptVerifier {
    struct Receipt {
        bytes32 receiptHash;
        uint256 state;
        bytes logs;
    }

    function validateMPT(bytes memory proof) external view returns (Receipt memory receipt);
}