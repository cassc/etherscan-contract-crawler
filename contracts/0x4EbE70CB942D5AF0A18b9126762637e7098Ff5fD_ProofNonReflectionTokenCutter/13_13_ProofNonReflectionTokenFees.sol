// SPDX-License-Identifier: None
pragma solidity ^0.8.17;

library ProofNonReflectionTokenFees {
    struct allFees {
        uint256 mainFee;
        uint256 mainFeeOnSell;
        uint256 lpFee;
        uint256 lpFeeOnSell;
        uint256 devFee;
        uint256 devFeeOnSell;
    }
}