// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

error InvalidPaymentSplitterSettings();
error InvalidCaller();
error InvalidAirdropParams();
error InvalidMaxSupply();
error InvalidSaleMode();
error MintDisabled();
error MintInactive(
  uint256 currentTimestamp,
  uint256 startTimestamp,
  uint256 endTimestamp
);
error MintQuantityCannotBeZero();
error ExceedMaxSupply();
error InvalidPayment();
error ExceedPreMintSupply();
error ExceedPresaleAllocation();
error InvalidPresaleStage();
error NotInAllowlist();
error ExceedMaxPerTx();
error ExceedMaxPerWallet();
error SignatureAlreadyUsed();
error InvalidSignature();
error FeatureUnavailable();
error Revealed();
error RefundFailed();