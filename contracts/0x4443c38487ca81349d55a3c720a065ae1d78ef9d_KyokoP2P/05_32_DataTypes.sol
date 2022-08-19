// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

library DataTypes {
    struct COLLATERAL {
        uint256 apy;
        uint256 price;
        uint256 period;
        uint256 buffering;
        address erc20Token;
        string description;
    }

    struct OFFER {
        uint256 apy;
        uint256 price;
        uint256 period;
        uint256 buffering;
        address erc20Token;
        bool accept;
        bool cancel;
        uint256 offerId; //final sold offerId
        uint256 lTokenId; //lTokenId, the token's id given to the lender
        address user; //the person who given this offer
        uint256 fee;// The fee when the user adds an offer
    }

    struct NFT {
        address holder;
        address lender;
        uint256 nftId; // nft tokenId
        address nftAdr; // nft address
        uint256 depositId; // depositId
        uint256 lTokenId; // ltoken id
        uint256 borrowTimestamp; // borrow timestamp
        uint256 emergencyTimestamp; // emergency timestamp
        uint256 repayAmount; // repayAmount
        //bit 0: borrow
        //bit 1: repay
        //bit 2: withdraw
        //bit 3: liquidate
        uint8 marks;
        COLLATERAL collateral;
    }
}