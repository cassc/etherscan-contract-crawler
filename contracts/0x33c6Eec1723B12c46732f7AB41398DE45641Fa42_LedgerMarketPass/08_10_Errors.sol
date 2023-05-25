// SPDX-License-Identifier: MIT

pragma solidity >=0.8.4;

library Errors {
    /* LedgerNFT.sol */
    error MintNotAvailable();
    error InsufficientFunds();
    error SupplyLimitReached();
    error ContractCantMint();
    error InvalidSignature();
    error AccountAlreadyMintedMax();
    error TokenDoesNotExist();
    error NotOwner();

    error NothingToWithdraw();
    error WithdrawFailed();
    error InvalidMintPrice();
    error MintPriceAlreadyUpdated();
    error InvalidBaseContractURL();
    error InvalidBaseURI();

    /* ReentrancyGuard.sol */
    error ContractLocked();

    /* Signable.sol */
    error NewSignerCantBeZero();

}