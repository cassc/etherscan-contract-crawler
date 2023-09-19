// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "erc721a/contracts/IERC721A.sol";

interface IDusktopia is IERC721A {
    error NonEOA();
    error InvalidSaleState();
    error MaxSupplyExceeded();
    error DuskSupplyExceeded();
    error InvalidEtherAmount();
    error InvalidTokenAmount();
    error OverTokenTxnLimit();
    error InvalidSignature();
    error AlreadyMinted();
    error WithdrawMismatch();
    error InvalidSupply();
    error AlreadyClaimed();
    error GovSupplyExceeded();
    error PublicSupplyExceeded();
    error OverWalletLimit();
}