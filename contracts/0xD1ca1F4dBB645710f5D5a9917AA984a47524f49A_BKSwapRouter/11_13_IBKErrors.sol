//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

interface IBKErrors {
    error InvalidMsgSig();
    error InsufficientEtherSupplied();
    error FeatureNotExist();
    error FeatureInActive();
    error InvalidCaller();
    error InvalidSigner();
    error InvalidNonce(bytes32 signMsg);
    error InvalidZeroAddress();  
    error InvalidFeeRate(uint256 feeRate);
    error SwapEthBalanceNotEnough();
    error SwapTokenBalanceNotEnough();
    error SwapTokenApproveNotEnough();
    error SwapInsuffenceOutPut();
    error SwapTypeNotAvailable();
    error BurnToMuch();
    error IllegalCallTarget();
    error IllegalApproveTarget(); 
    error InvalidSwapAddress(address);
    error CallException(address);
}