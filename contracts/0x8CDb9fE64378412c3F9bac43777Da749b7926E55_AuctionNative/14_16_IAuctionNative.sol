// SPDX-License-Identifier: MIT
pragma solidity =0.8.14;

import "./base/ISignableStructsAuction.sol";

/**
 * @title Interface to Escrow Contract for Payments in Auction & BuyNow modes, in Native Cryptocurrencies.
 * @author Freeverse.io, www.freeverse.io
 * @dev The contract that implements this interface adds an entry point for Bid processes in Auctions,
 * which are defined and documented in the AuctionBase contract.
 * - in the 'bid' method, the buyer is the msg.sender (the buyer therefore signs the TX),
 *   and the Operator's EIP712-signature of the BidInput struct is provided as input to the call.
 *
 *  When a bidder is outbid by a different user, he/she is automatically refunded to this contract's
 *  local balance. Accepting a new bid and transferring funds to the previous bidder in the same TX would
 *  not be a safe operation, since the external address could contain malicious implementations
 *  on arrival of new funds.
*/

interface IAuctionNative is ISignableStructsAuction {
    /**
     * @notice Processes an arriving bid, and either starts a new Auction process,
     *   or updates an existing one.
     * @dev Executed by the bidder, who relays the operator's signature.
     *  The bidder must provide, at least, the minimal required funds via msg.value,
     *  where the minimal amount takes into account any possibly available local funds,
     *  and the case where the same bidder raises his/her previous max bid,
     *  in which case only the difference between bids is required.
     *  If all requirements are fulfilled, it stores the data relevant for the next steps
     *  of the auction, and it locks the funds in this contract.
     *  If this is the first bid of an auction, it moves its state to AUCTIONING,
     *  whereas if it arrives on an on-going auction, it remains in AUCTIONING.
     * @param bidInput The struct containing all required bid data
     * @param operatorSignature The signature of 'bidInput' by the operator
     * @param sellerSignature the signature of the seller agreeing to list the asset
     */
    function bid(
        BidInput calldata bidInput,
        bytes calldata operatorSignature,
        bytes calldata sellerSignature
    ) external payable;
}