// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

/**
 * @title Errors (Library)
 * @author Zeeshan Jan
 */

library Errors {
    // RatKingSociety
    error RatKingAlreadyMinted();
    error MaximumPublicSupplyLimitReached();
    error MaximumGiftSupplyLimitReached();
    
    // Free Content NFTs
    error RatKingHasAlreadyMintedFreeNFT();
    error AlreadyMintedFreeNFT();
    error NotYourRatKing();
    error NoFreeContentNFTOwned();
}