// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

import "erc721a/contracts/ERC721A.sol";

interface IClokies is IERC721A {
    error InvalidEtherAmount();
    error InvalidNewPrice();
    error InvalidSaleState();
    error NonEOA();
    error InvalidTokenCap();
    error InvalidSignature();
    error SupplyExceeded();
    error TokenClaimed();
    error WalletLimitExceeded();
    error WithdrawFailedArtist();
    error WithdrawFailedDev();
    error WithdrawFailedFounder();
    error WithdrawFailedVault();
}