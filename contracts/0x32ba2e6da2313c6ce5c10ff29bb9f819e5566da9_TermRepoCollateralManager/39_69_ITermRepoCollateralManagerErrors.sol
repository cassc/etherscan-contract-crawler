//SPDX-License-Identifier: CC-BY-NC-ND-4.0
pragma solidity ^0.8.18;

/// @notice ITermRepoCollateralManagerErrors defines all errors emitted by Term Repo Collateral Manager.
interface ITermRepoCollateralManagerErrors {
    error AlreadyTermContractPaired();
    error BorrowerNotInShortfall();
    error CallerNotBorrower();
    error CollateralBelowMaintenanceRatios(address borrower, address token);
    error CollateralDepositClosed();
    error CollateralTokenNotAllowed(address token);
    error CollateralWithdrawalClosed();
    error DefaultsClosed();
    error InvalidParameters(string message);
    error InsufficientCollateralForLiquidationRepayment(
        address collateralToken
    );
    error InsufficientCollateralForRedemption();
    error ExceedsNetExposureCapOnLiquidation();
    error LiquidationsPaused();
    error RepaymentAmountLargerThanAllowed();
    error SelfLiquidationNotPermitted();
    error ShortfallLiquidationsClosed();
    error TermRepurchaseWindowOpen();
    error TotalRepaymentGreaterThangetBorrowerRepurchaseObligation();
    error UnlockAmountGreaterThanCollateralBalance();
    error ZeroAddressContractPaired();
    error ZeroBorrowerRepurchaseObligation();
    error ZeroCollateralBalance();
    error ZeroLiquidationNotPermitted();
}