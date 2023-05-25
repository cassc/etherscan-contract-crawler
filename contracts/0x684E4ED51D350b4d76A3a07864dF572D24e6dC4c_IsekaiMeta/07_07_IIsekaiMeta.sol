// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import "IERC721A.sol";

interface IIsekaiMeta is IERC721A {
    error NonEOA();
    error InvalidSaleState();
    error InvalidSignature();
    error SupplyExceeded();
    error TokenCapExceeded();
    error TokenLimitExceeded();
    error InvalidEtherAmount();
    error TokenClaimed();
    error WithdrawFailed();
    error WalletLimitExceeded();
    error ArrayLengthMismatch();
    error InvalidTokenCap();
}