//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

error Paused();
error SoldOut();
error SaleNotStarted();
error MintingTooMany();
error NotWhitelisted();
error Underpriced();
error MintedOut();
error MaxMints();
error ArraysDontMatch();
error ZeroSigner();
error InvalidSignature();
error StartTimeInPast();
error NotApprovedMinter();

error StatusLengthMustMatchNumNonStandardMintAmount();
error InvalidTier();
error OnlyCreatorPassCanBurn();
error NumNonStandardCannotExceedAmount();