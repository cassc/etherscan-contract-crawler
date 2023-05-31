// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

library PetsErrorCodes {
    // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    // *                    ERROR MESSAGES
    // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    // Mint Errors
    error SoldOut();
    error InsufficientFunds(uint256 Expected, uint256 Actual);
    error MaxAmountMinted(uint256 Expected, uint256 Actual);
    error ArrayMissmatch();
    error PublicMintNotActive();
}