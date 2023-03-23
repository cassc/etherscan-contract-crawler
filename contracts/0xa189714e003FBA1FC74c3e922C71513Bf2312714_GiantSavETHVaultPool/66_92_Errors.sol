// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

interface Errors {
    // common
    error EmptyArray();
    error InconsistentArrayLength();
    error InvalidAmount();
    error InvalidBalance();
    error InvalidCaller();
    
    // GiantMevAndFeesPool
    error InvalidStakingFundsVault();
    error NoDerivativesMinted();
    error OutsideRange();
    error TokenMismatch();

    // GiantSavETHVaultPool
    error InvalidSavETHVault();
    error FeesAndMevPoolCannotMatch();
    error DETHNotReadyForWithdraw();
    error InvalidWithdrawlBatch();
    error NoCommonInterest();
    error ETHStakedOrDerivativesMinted();
}