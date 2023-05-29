// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface ITokunPass {
    error NonEOA();
    error InvalidSaleState();
    error InvalidEtherAmount();
    error AlreadyMinted();
    error SupplyExceeded();
    error InvalidSignature();
    error AccountMismatch();
}