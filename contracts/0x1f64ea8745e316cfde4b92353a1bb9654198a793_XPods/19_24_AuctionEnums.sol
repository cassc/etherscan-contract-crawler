// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

/* 
Stages of the auction

None - initial stage, before bidding is allowed
Active - bids are allowed, the auction is active
Closed - bids are closed, the price needs to be set
Claims - bidders can claim their winnings and receive any refunds
Reveals - claims and refunds are still active, additionally
               owners of pods are now able to reveal their pod
 */
enum AuctionStage {
    None,
    Active,
    Closed,
    Claims,
    Reveals
}