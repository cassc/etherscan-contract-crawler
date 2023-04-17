// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.19;

import {ECCMath} from "../util/ECCMath.sol";

interface ISizeSealed {
    ////////////////////////////////////
    ///            ERRORS            ///
    ////////////////////////////////////

    error InvalidTimestamp();
    error InvalidCliffPercent();
    error InvalidBidAmount();
    error InvalidState();
    error InvalidReserve();
    error InvalidCalldata();
    error UnauthorizedCaller();
    error CommitmentMismatch();
    error InvalidProof();
    error InvalidPrivateKey();
    error UnexpectedBalanceChange();
    error InvalidSorting();
    error TokenDoesNotExist();
    error OverfilledAuction();
    error IncorrectBidIndices();

    /////////////////////////////////////////
    ///              ENUMS                ///
    /////////////////////////////////////////

    enum States {
        Created,
        AcceptingBids,
        RevealPeriod,
        Voided,
        Finalized
    }

    /////////////////////////////////////////
    ///              STRUCTS              ///
    /////////////////////////////////////////

    struct EncryptedBid {
        address sender;
        uint128 quoteAmount;
        uint128 initialIndex;
        uint128 filledBaseAmount;
        uint128 baseWithdrawn;
        bytes32 commitment;
        ECCMath.Point pubKey;
        bytes32 encryptedMessage;
    }

    /// @param startTimestamp When the auction opens for bidding
    /// @param endTimestamp When the auction closes for bidding
    /// @param vestingStartTimestamp When linear vesting starts
    /// @param vestingEndTimestamp When linear vesting is complete
    /// @param cliffPercent Normalized percentage of base tokens to unlock at vesting start
    struct Timings {
        uint32 startTimestamp;
        uint32 endTimestamp;
        uint32 vestingStartTimestamp;
        uint32 vestingEndTimestamp;
        uint128 cliffPercent;
    }

    struct AuctionData {
        address seller;
        bool finalized;
        uint128 clearingBase;
        uint128 clearingQuote;
        uint256 privKey;
    }

    /// @param baseToken The ERC20 to be sold by the seller
    /// @param quoteToken The ERC20 to be bid by the bidders
    /// @param reserveQuotePerBase Minimum price that bids will be filled at
    /// @param totalBaseAmount Max amount of `baseToken` to be auctioned
    /// @param minimumBidQuote Minimum quote amount a bid can buy
    /// @param pubKey On-chain storage of seller's ephemeral public key
    struct AuctionParameters {
        address baseToken;
        address quoteToken;
        uint256 reserveQuotePerBase;
        uint128 totalBaseAmount;
        uint128 minimumBidQuote;
        bytes32 merkleRoot;
        ECCMath.Point pubKey;
    }

    struct Auction {
        Timings timings;
        AuctionData data;
        AuctionParameters params;
        EncryptedBid[] bids;
    }

    ////////////////////////////////////
    ///            EVENTS            ///
    ////////////////////////////////////

    event AuctionCreated(
        uint256 auctionId, address seller, AuctionParameters params, Timings timings, bytes encryptedPrivKey
    );

    event AuctionCanceled(uint256 auctionId);

    event Bid(
        address sender,
        uint256 auctionId,
        uint256 bidIndex,
        uint128 quoteAmount,
        bytes32 commitment,
        ECCMath.Point pubKey,
        bytes32 encryptedMessage,
        bytes encryptedPrivateKey
    );

    event BidCanceled(uint256 auctionId, uint256 bidIndex);

    event BiddingStopped(uint256 auctionId);

    event RevealedKey(uint256 auctionId, uint256 privateKey);

    event AuctionFinalized(uint256 auctionId, uint256[] bidIndices, uint256 filledBase, uint256 filledQuote);

    event BidRefund(uint256 auctionId, uint256 bidIndex);

    event Withdrawal(uint256 auctionId, uint256 bidIndex, uint256 withdrawAmount, uint256 remainingAmount);
}