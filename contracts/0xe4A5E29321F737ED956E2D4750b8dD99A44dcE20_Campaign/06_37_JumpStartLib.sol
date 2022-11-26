// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

library JumpStartLib {
    struct MintNftTicket {
        string tokenUri;
        string tokenName;
        string tokenSymbol;
        uint256 quantity;
        bool redeemed;
    }

    struct MintNft {
        string tokenUri;
        string contractUri;
        string tokenName;
        string tokenSymbol;
        string nftUID;
        uint256 quantity;
        uint256 mintPrice;
        bool enableWhitelist; // enable whitelist for individual nfts
        bool redeemable; // has tickets attached
        uint256 ticketsPerMint; // how many tickets per mint
        uint256 mintPerAddress; // how many mints per address
        uint256 mintPerTransaction; // how many mints per transaction
        uint256 priceDiscount; // price discount
        uint256 priceDiscountEndDate; // price discount end date
        MintNftTicket ticket;
    }
}