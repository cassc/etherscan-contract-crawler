// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

library Errors {
    error CallerIsAnotherContract();
    error NonexistentToken();
    error PresaleIsActive();
    error MintAmountOver();
    error PresaleIsNotActive();
    error InvalidMerkleProof();
    error OverMintLimit();
    error MintAmountCannotBeZero();
    error MaxSupplyOver();
    error NotEnoughFunds();
    error CallerIsNotTeam();
    error NowPaused();
    error FailedWithdraw();
}