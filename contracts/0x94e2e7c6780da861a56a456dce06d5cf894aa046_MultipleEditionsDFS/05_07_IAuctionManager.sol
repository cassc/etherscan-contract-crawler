// SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.10;

import { IMinimalForwarder } from "./IMinimalForwarder.sol";

/**
 * @title Interface for AuctionManager
 * @notice Defines behaviour encapsulated in AuctionManager
 * @author [email protected]
 */
interface IAuctionManager {
    /**
     * @notice The state an auction is in
     * @param NON_EXISTENT Default state of auction pre-creation
     * @param LIVE_ON_CHAIN State of auction after creation but before the auction ends or is cancelled
     * @param CANCELLED_ON_CHAIN State of auction after auction is cancelled
     * @param FULFILLED State of auction after winning bid has been dispersed and NFT has left escrow
     */
    enum AuctionState {
        NON_EXISTENT,
        LIVE_ON_CHAIN,
        CANCELLED_ON_CHAIN,
        FULFILLED
    }

    /**
     * @notice The data structure containing all fields on an English Auction that need to be on-chain
     * @param collection The collection hosting the auctioned NFT
     * @param currency The currency bids must be made in
     * @param owner The auction owner
     * @param paymentRecipient The recipient account of the winning bid
     * @param endTime When the auction will tentatively end. Is 0 if first bid hasn't been made
     * @param tokenId The ID of the NFT being auctioned
     * @param mintWhenReserveMet If true, new NFT will be minted when reserve crossing bid is made
     * @param state Auction state
     */
    struct EnglishAuction {
        address collection;
        address currency;
        address owner;
        address payable paymentRecipient;
        uint256 endTime;
        uint256 tokenId; // if nft already exists
        bool mintWhenReserveMet;
        AuctionState state;
    }

    /**
     * @notice Used for information about auctions on editions
     * @param used True if the auction is for an auction on an edition
     * @param editionId ID of the edition used for this auction
     */
    struct EditionAuction {
        bool used;
        uint256 editionId;
    }

    /**
     * @notice Data required for a bidder to make a bid. Claims are signed, hashed and validated, acting as bid keys
     * @param auctionId ID of auction
     * @param bidPrice Price that bidder is bidding
     * @param reservePrice Price that bidder must bid greater than. Only relevant for the first bid on an auction
     * @param maxClaimsPerAccount Max bids that an account can make on an auction. Unlimited if 0
     * @param claimExpiryTimestamp Time when claim expires
     * @param buffer Minimum time that must be left in an auction after a bid is made
     * @param minimumIncrementPerBidPctBPS Minimum % that a bid must be higher than the previous highest bid by,
     *                                     in basis points
     * @param claimer Account that can use the claim
     */
    struct Claim {
        bytes32 auctionId;
        uint256 bidPrice;
        uint256 reservePrice;
        uint256 maxClaimsPerAccount;
        uint256 claimExpiryTimestamp;
        uint256 buffer;
        uint256 minimumIncrementPerBidPctBPS;
        address payable claimer;
    }

    /**
     * @notice Structure hosting highest bidder info
     * @param bidder Bidder with current highest bid
     * @param preferredNFTRecipient The account that the current highest bidder wants the NFT to go to if they win.
     *                              Useful for non-transferable NFTs being auctioned.
     * @param amount Amount of current highest bid
     */
    struct HighestBidderData {
        address payable bidder;
        address preferredNFTRecipient;
        uint256 amount;
    }

    /**
     * @notice Emitted when an english auction is created
     * @param auctionId ID of auction
     * @param owner Auction owner
     * @param collection Collection that NFT being auctioned is on
     * @param tokenId ID of NFT being auctioned
     * @param currency The currency bids must be made in
     * @param paymentRecipient The recipient account of the winning bid
     * @param endTime Auction end time
     */
    event EnglishAuctionCreated(
        bytes32 indexed auctionId,
        address indexed owner,
        address indexed collection,
        uint256 tokenId,
        address currency,
        address paymentRecipient,
        uint256 endTime
    );

    /**
     * @notice Emitted when a valid bid is made on an auction
     * @param auctionId ID of auction
     * @param bidder Bidder with new highest bid
     * @param firstBid True if this is the first bid, ie. first bid greater than reserve price
     * @param collection Collection that NFT being auctioned is on
     * @param tokenId ID of NFT being auctioned
     * @param value Value of bid
     * @param timeLengthened True if this bid extended the end time of the auction (by being bid >= endTime - buffer)
     * @param preferredNFTRecipient The account that the current highest bidder wants the NFT to go to if they win.
     *                              Useful for non-transferable NFTs being auctioned.
     * @param endTime The current end time of the auction
     */
    event Bid(
        bytes32 indexed auctionId,
        address indexed bidder,
        bool indexed firstBid,
        address collection,
        uint256 tokenId,
        uint256 value,
        bool timeLengthened,
        address preferredNFTRecipient,
        uint256 endTime
    );

    /**
     * @notice Emitted when an auction's end time is extended
     * @param auctionId ID of auction
     * @param tokenId ID of NFT being auctioned
     * @param collection Collection that NFT being auctioned is on
     * @param buffer Minimum time that must be left in an auction after a bid is made
     * @param newEndTime New end time of auction
     */
    event TimeLengthened(
        bytes32 indexed auctionId,
        uint256 indexed tokenId,
        address indexed collection,
        uint256 buffer,
        uint256 newEndTime
    );

    /**
     * @notice Emitted when an auction is won, and its terms are fulfilled
     * @param auctionId ID of auction
     * @param tokenId ID of NFT being auctioned
     * @param collection Collection that NFT being auctioned is on
     * @param owner Auction owner
     * @param winner Winning bidder
     * @param paymentRecipient The recipient account of the winning bid
     * @param nftRecipient The account receiving the auctioned NFT
     * @param currency The currency bids were made in
     * @param amount Winning bid value
     * @param paymentRecipientPctBPS The percentage of the winning bid going to the paymentRecipient, in basis points
     */
    event AuctionWon(
        bytes32 indexed auctionId,
        uint256 indexed tokenId,
        address indexed collection,
        address owner,
        address winner,
        address paymentRecipient,
        address nftRecipient,
        address currency,
        uint256 amount,
        uint256 paymentRecipientPctBPS
    );

    /**
     * @notice Emitted when an auction is cancelled on-chain (before any valid bids have been made).
     * @param auctionId ID of auction
     * @param owner Auction owner
     * @param collection Collection that NFT was being auctioned on
     * @param tokenId ID of NFT that was being auctioned
     */
    event AuctionCanceledOnChain(
        bytes32 indexed auctionId,
        address indexed owner,
        address indexed collection,
        uint256 tokenId
    );

    /**
     * @notice Emitted when the payment recipient of an auction is updated
     * @param auctionId ID of auction
     * @param owner Auction owner
     * @param newPaymentRecipient New payment recipient of auction
     */
    event PaymentRecipientUpdated(
        bytes32 indexed auctionId,
        address indexed owner,
        address indexed newPaymentRecipient
    );

    /**
     * @notice Emitted when the preferred NFT recipient of an auctionbid  is updated
     * @param auctionId ID of auction
     * @param owner Auction owner
     * @param newPreferredNFTRecipient New preferred nft recipient of auction
     */
    event PreferredNFTRecipientUpdated(
        bytes32 indexed auctionId,
        address indexed owner,
        address indexed newPreferredNFTRecipient
    );

    /**
     * @notice Emitted when the end time of an auction is updated
     * @param auctionId ID of auction
     * @param owner Auction owner
     * @param newEndTime New end time
     */
    event EndTimeUpdated(bytes32 indexed auctionId, address indexed owner, uint256 indexed newEndTime);

    /**
     * @notice Emitted when the platform is updated
     * @param newPlatform New platform
     */
    event PlatformUpdated(address newPlatform);

    /**
     * @notice Create an auction that mints the NFT being auctioned into escrow (mints the next NFT on the collection)
     * @param auctionId ID of auction
     * @param auction The auction details
     */
    function createAuctionForNewToken(bytes32 auctionId, EnglishAuction memory auction) external;

    /**
     * @notice Create an auction that mints an edition being auctioned into escrow (mints the next NFT on the edition)
     * @param auctionId ID of auction
     * @param auction The auction details
     */
    function createAuctionForNewEdition(
        bytes32 auctionId,
        IAuctionManager.EnglishAuction memory auction,
        uint256 editionId
    ) external;

    /**
     * @notice Create an auction for an existing NFT
     * @param auctionId ID of auction
     * @param auction The auction details
     */
    function createAuctionForExistingToken(bytes32 auctionId, EnglishAuction memory auction) external;

    /**
     * @notice Create an auction for an existing NFT, with atomic transfer approval meta-tx packets
     * @param auctionId ID of auction
     * @param auction The auction details
     * @param req The request containing the call to transfer the auctioned NFT into escrow
     * @param requestSignature The signed request
     */
    function createAuctionForExistingTokenWithMetaTxPacket(
        bytes32 auctionId,
        IAuctionManager.EnglishAuction memory auction,
        IMinimalForwarder.ForwardRequest calldata req,
        bytes calldata requestSignature
    ) external;

    /**
     * @notice Update the payment recipient for an auction
     * @param auctionId ID of auction being updated
     * @param newPaymentRecipient New payment recipient on the auction
     */
    function updatePaymentRecipient(bytes32 auctionId, address payable newPaymentRecipient) external;

    /**
     * @notice Update the preferred nft recipient of a bid
     * @param auctionId ID of auction being updated
     * @param newPreferredNFTRecipient New nft recipient on the auction bid
     */
    function updatePreferredNFTRecipient(bytes32 auctionId, address newPreferredNFTRecipient) external;

    /**
     * @notice Makes a bid on an auction
     * @param claim Claim needed to make the bid
     * @param claimSignature Claim signature to be unwrapped and validated
     * @param preferredNftRecipient Bidder's preferred recipient of NFT if they win auction
     */
    function bid(
        IAuctionManager.Claim calldata claim,
        bytes calldata claimSignature,
        address preferredNftRecipient
    ) external payable;

    /**
     * @notice Fulfill auction and disperse winning bid / auctioned NFT.
     * @dev Anyone can call this function
     * @param auctionId ID of auction to fulfill
     */
    function fulfillAuction(bytes32 auctionId) external;

    /**
     * @notice "Cancels" an auction on-chain, if a valid bid hasn't been made yet. Transfers NFT back to auction owner
     * @param auctionId ID of auction being "cancelled"
     */
    function cancelAuctionOnChain(bytes32 auctionId) external;

    /**
     * @notice Updates the platform account receiving a portion of winning bids
     * @param newPlatform New account to receive portion
     */
    function updatePlatform(address payable newPlatform) external;

    /**
     * @notice Updates the platform cut
     * @param newCutBPS New account to receive portion
     */
    function updatePlatformCut(uint256 newCutBPS) external;

    /**
     * @notice Update an auction's end time before first valid bid is made on auction
     * @param auctionId Auction ID
     * @param newEndTime New end time
     */
    function updateEndTime(bytes32 auctionId, uint256 newEndTime) external;

    /**
     * @notice Verifies the validity of a claim, simulating call to bid()
     * @param claim Claim needed to make the bid
     * @param claimSignature Claim signature to be unwrapped and validated
     * @param expectedMsgSender Expected msg.sender when bid() is called, that is being simulated
     */
    function verifyClaim(
        Claim calldata claim,
        bytes calldata claimSignature,
        address expectedMsgSender
    ) external view returns (bool);

    /**
     * @notice Get all data about an auction except for number of bids made per user
     * @param auctionId ID of auction
     */
    function getFullAuctionData(bytes32 auctionId)
        external
        view
        returns (
            EnglishAuction memory,
            HighestBidderData memory,
            EditionAuction memory
        );

    /**
     * @notice Get all data about a set of auctions except for number of bids made per user
     * @param auctionIds IDs of auctions
     */
    function getFullAuctionsData(bytes32[] calldata auctionIds)
        external
        view
        returns (
            EnglishAuction[] memory,
            HighestBidderData[] memory,
            EditionAuction[] memory
        );
}