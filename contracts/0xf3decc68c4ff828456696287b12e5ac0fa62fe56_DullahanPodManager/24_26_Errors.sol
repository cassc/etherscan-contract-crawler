pragma solidity 0.8.16;
//SPDX-License-Identifier: MIT

library Errors {

    // Common Errors
    error AddressZero();
    error NullAmount();
    error IncorrectRewardToken();
    error SameAddress();
    error InequalArraySizes();
    error EmptyArray();
    error EmptyParameters();
    error NotInitialized();
    error AlreadyInitialized();
    error CannotInitialize();
    error InvalidParameter();
    error CannotRecoverToken();
    error NullWithdraw();
    error AlreadyListedManager();
    error NotListedManager();

    // Access Control Erros
    error CallerNotAdmin();
    error CannotBeAdmin();
    error CallerNotPendingAdmin();
    error CallerNotAllowed();

    // ERC20 Errors
    error ERC20_ApproveAddressZero();
    error ERC20_AllowanceUnderflow();
    error ERC20_AmountOverAllowance();
    error ERC20_AddressZero();
    error ERC20_SelfTransfer();
    error ERC20_NullAmount();
    error ERC20_AmountExceedBalance();

    // Maths Errors
    error NumberExceed96Bits();
    error NumberExceed128Bits();
    error NumberExceed248Bits();

    // Vault Errors
    error ManagerAlreadyListed();
    error ManagerNotListed();
    error NotEnoughAvailableFunds();
    error WithdrawBuffer();
    error ReserveTooLow();
    error CallerNotAllowedManager();
    error NotUndebtedManager();
    error AmountExceedsDebt();

    // Vaults Rewards Errors
    error NullScaledAmount();
    error AlreadyListedDepositor();
    error NotListedDepositor();
    error ClaimNotAllowed();

    // Pods Errors
    error NotPodOwner();
    error NotPodManager();
    error FailPodStateUpdate();
    error MintAmountUnderMinimum();
    error RepayFailed();

    // Pods Manager Errors
    error CallerNotValidPod();
    error CollateralBlocked();
    error MintingAllowanceFailed();
    error FreeingStkAaveFailed();
    error CollateralAlreadyListed();
    error CollateralNotListed();
    error CollateralNotAllowed();
    error PodInvalid();
    error FailStateUpdate();
    error PodNotLiquidable();

    // Registry Errors
    error VaultAlreadySet();

    // Zap Errors
    error InvalidSourceToken();
    error DepositFailed();

    // Wrapper Errors
    error NullConvertedAmount();

}