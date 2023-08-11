//SPDX-License-Identifier: CC-BY-NC-ND-4.0
pragma solidity ^0.8.18;

/// @notice ITermRepoServicerErrors defines all errors emitted by the Term Repo Servicer.
interface ITermRepoServicerErrors {
    error AfterMaturity();
    error AfterRepurchaseWindow();
    error AlreadyTermContractPaired();
    error CallerNotBorrower();
    error EncumberedCollateralRemaining();
    error InsufficientgetBorrowerRepurchaseObligation();
    error InsufficientCollateral();
    error InsufficientTermRepoTokenBalance();
    error InvalidParameters(string message);
    error LockedBalanceInsufficient();
    error NoMintOpenExposureAccess();
    error NotMaturedYet();
    error RedemptionPeriodNotOpen();
    error RepurchaseAmountTooHigh();
    error ZeroBorrowerRepurchaseObligation();
    error ZeroTermRepoTokenBalance();
}