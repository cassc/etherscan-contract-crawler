// SPDX-License-Identifier: MIT
pragma solidity =0.8.14;

/**
 * @title Interface for Structs required in MetaTXs using EIP712.
 * @author Freeverse.io, www.freeverse.io
 * @dev This contract defines the structure BidInput, required for auction processes.
 *  This structure requires a separate implementation of its EIP712-verifying function.
 */

interface ISignableStructsAuction {

    /**
    * @notice The main struct that characterizes a bid
    * @dev Used as input to the bid/relayedBid methods to either start
    * @dev an auction or increment a previous existing bid;
    * @dev it needs to be signed following EIP712
    */
    struct BidInput {
        // the unique Id that identifies a payment process,
        // common to both Auctions and BuyNows,
        // obtained from hashing params related to the listing, 
        // including a sufficiently large source of entropy.
        bytes32 paymentId;

        // the time at which the auction ends if
        // no bids arrive during the final minutes;
        // this value is stored on arrival of the first bid,
        // and possibly incremented on arrival of late bids
        uint256 endsAt;

        // the bid amount, an integer expressed in the
        // lowest unit of the currency.
        uint256 bidAmount;

        // the fee that will be charged by the feeOperator,
        // expressed as percentage Basis Points (bps), applied to amount.
        // e.g. feeBPS = 500 implements a 5% fee.
        uint256 feeBPS;

        // the id of the universe that the asset belongs to.
        uint256 universeId;

        // the deadline for the payment to arrive to this
        // contract, otherwise it will be rejected.
        uint256 deadline;

        // the bidder, providing the required funds, who shall receive
        // the asset in case of winning the auction.       
        address bidder;

        // the seller of the asset, who shall receive the funds
        // (subtracting fees) on successful completion of the auction.
        address seller;
    }
}