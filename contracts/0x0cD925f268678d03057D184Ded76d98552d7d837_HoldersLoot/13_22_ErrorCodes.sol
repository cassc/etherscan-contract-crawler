// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

library ErrorCodes {
    // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    // *                    ERROR MESSAGES
    // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    // Mint Errors
    error SoldOut();
    error SignatureVerify();
    error ContractPaused();
    error WhitelistActive();
    error RequestedIncorrectAmount();
    error PublicSaleInactive();
    error NotInDailyStore();
    error InsufficientFunds(uint256 Expected, uint256 Actual);
    error MaxAmountMinted(uint256 Expected, uint256 Actual);
    error NetworkMissmatch();
    error ClaimMintDisabled();
    error IncorrectContractSignature();
    error DailyStoreInactive();

    // General Errors
    error ArrayMissmatch();

    // Adding Loot Item Errors
    error LootItem_CostError();
    error LootItem_SupplyError();
    error LootItem_MaxMintError();
    error LootItem_ItemDoesntExist();
}