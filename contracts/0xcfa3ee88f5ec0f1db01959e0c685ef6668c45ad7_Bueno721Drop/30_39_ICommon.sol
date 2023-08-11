// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

error InvalidPrice();
error SoldOut();
error ExceedMaxPerWallet();
error InvalidProof();
error InvalidMintFunction();
error InvalidAirdrop();
error BurningNotAllowed();

struct PaymentSplitterSettings {
    address[] payees;
    uint256[] shares;
}

struct RoyaltySettings {
    address royaltyAddress;
    uint96 royaltyAmount;
}