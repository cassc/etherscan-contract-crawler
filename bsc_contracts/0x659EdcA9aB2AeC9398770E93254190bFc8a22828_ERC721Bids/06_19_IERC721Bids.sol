// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.8.0;
pragma abicoder v2;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "../royalty/ICollectionRoyaltyReader.sol";

interface IERC721Bids {
    struct EnterBidInput {
        address erc721Address;
        uint256 tokenId;
        uint256 value;
        uint256 expireTimestamp;
        address paymentToken;
    }

    struct WithdrawBidInput {
        address erc721Address;
        uint256 tokenId;
        address bidder;
    }

    struct AcceptBidInput {
        address erc721Address;
        uint256 tokenId;
        address bidder;
        uint256 value;
    }

    struct RemoveExpiredBidInput {
        address erc721Address;
        uint256 tokenId;
        address bidder;
    }

    struct Bid {
        uint256 tokenId;
        uint256 value;
        address bidder;
        uint256 expireTimestamp;
        address paymentToken;
    }

    struct TokenBids {
        EnumerableSet.AddressSet bidders;
        mapping(address => Bid) bids;
    }

    struct ERC721Bids {
        EnumerableSet.UintSet tokenIds;
        mapping(uint256 => TokenBids) bids;
    }

    struct FundReceiver {
        address account;
        uint256 amount;
        address paymentToken;
    }

    enum Status {
        NOT_EXIST, // 0: bid doesn't exist
        ACTIVE, // 1: bid is active and valid
        TRADE_NOT_OPEN, // 2: trade not open
        EXPIRED, // 3: bid has expired
        ALREADY_TOKEN_OWNER, // 4: bidder is token owner
        INVALID_PAYMENT_TOKEN, // 5: payment token is not allowed
        INSUFFICIENT_BALANCE, // 6: insufficient payment token balance
        INSUFFICIENT_ALLOWANCE // 7: insufficient payment token allowance
    }

    struct BidStatus {
        uint256 tokenId;
        uint256 value;
        address bidder;
        uint256 expireTimestamp;
        address paymentToken;
        Status status;
    }

    event TokenBidEntered(
        address indexed erc721Address,
        address indexed bidder,
        uint256 tokenId,
        Bid bid,
        address sender
    );
    event TokenBidWithdrawn(
        address indexed erc721Address,
        address indexed bidder,
        uint256 tokenId,
        Bid bid,
        address sender
    );
    event TokenBidAccepted(
        address indexed erc721Address,
        address indexed seller,
        uint256 tokenId,
        Bid bid,
        uint256 serviceFee,
        ICollectionRoyaltyReader.RoyaltyAmount[] royaltyInfo,
        address sender
    );

    event EnterBidFailed(
        address indexed erc721Address,
        uint256 tokenId,
        string message,
        address sender
    );
    event WithdrawBidFailed(
        address indexed erc721Address,
        uint256 tokenId,
        string message,
        address sender
    );
    event AcceptBidFailed(
        address indexed erc721Address,
        uint256 tokenId,
        string message,
        address sender
    );

    event MarketSettingsContractUpdated(
        address previousMarketSettingsContract,
        address newMarketSettingsContract
    );

    /**
     * @dev enter bid for token
     * @param erc721Address collection address
     * @param tokenId token ID to bid on
     * @param value bid price
     * @param expireTimestamp bid expire time
     * @param paymentToken erc20 token for payment
     * @param bidder address of bidder
     * Note:
     * paymentToken: When using address 0 as payment token,
     * it refers to wrapped coin of the chain, e.g. WBNB, WFTM, etc.
     * bidder: bidder is a required field because
     * sender can be a delegated operator, therefore bidder
     * address needs to be included
     */
    function enterBidForToken(
        address erc721Address,
        uint256 tokenId,
        uint256 value,
        uint256 expireTimestamp,
        address paymentToken,
        address bidder
    ) external;

    /**
     * @dev batch enter bids
     * @param newBids details of new bid
     * @param bidder address of bidder
     * Note:
     * Refer to enterBidForToken comments for input params def
     */
    function enterBidForTokens(EnterBidInput[] calldata newBids, address bidder)
        external;

    /**
     * @dev withdraw bid for token
     * @param erc721Address collection address
     * @param tokenId token ID of the bid
     * @param bidder address of bidder
     */
    function withdrawBidForToken(
        address erc721Address,
        uint256 tokenId,
        address bidder
    ) external;

    /**
     * @dev batch withdraw bids
     * @param bids details of bid to withdraw
     * Note:
     * Refer to withdrawBidForToken comments for input params def
     */
    function withdrawBidForTokens(WithdrawBidInput[] calldata bids) external;

    /**
     * @dev accept bid for token
     * @param erc721Address collection address
     * @param tokenId token ID to accept bid of
     * @param value bid price
     * @param bidder address of bidder
     * Note:
     * value is required to avoid bidder frontrun
     */
    function acceptBidForToken(
        address erc721Address,
        uint256 tokenId,
        address bidder,
        uint256 value
    ) external;

    /**
     * @dev batch accept bids
     * @param bids details of bid to accept
     * Note:
     * Refer to acceptBidForToken comments for input params def
     */
    function acceptBidForTokens(AcceptBidInput[] calldata bids) external;

    /**
     * @dev Remove expired bids
     * @param bids list bids to remove
     * anyone can removed expired bids
     */
    function removeExpiredBids(RemoveExpiredBidInput[] calldata bids) external;

    /**
     * @dev get bid details of a bid
     * @param erc721Address collection address
     * @param tokenId token ID to read
     * @param bidder address of bidder
     */
    function getBidderTokenBid(
        address erc721Address,
        uint256 tokenId,
        address bidder
    ) external view returns (BidStatus memory);

    /**
     * @dev get bids details of a token
     * @param erc721Address collection address
     * @param tokenId token ID to read
     */
    function getTokenBids(address erc721Address, uint256 tokenId)
        external
        view
        returns (BidStatus[] memory bids);

    /**
     * @dev get highest bid of a token
     * @param erc721Address collection address
     * @param tokenId token ID to read
     */
    function getTokenHighestBid(address erc721Address, uint256 tokenId)
        external
        view
        returns (BidStatus memory highestBid);

    /**
     * @dev get number of token with bids of a collection
     * @param erc721Address collection address
     */
    function numTokenWithBidsOfCollection(address erc721Address)
        external
        view
        returns (uint256);

    /**
     * @dev get batch of highest bids of a collection
     * @param erc721Address collection address
     * @param from index of token to read
     * @param size amount of tokens to read
     */
    function getHighestBidsOfCollection(
        address erc721Address,
        uint256 from,
        uint256 size
    ) external view returns (BidStatus[] memory highestBids);

    /**
     * @dev get batch of bids from a bidder of a collection
     * @param erc721Address collection address
     * @param bidder address of bidder
     * @param from index of token to read
     * @param size amount of tokens to read
     */
    function getBidderBidsOfCollection(
        address erc721Address,
        address bidder,
        uint256 from,
        uint256 size
    ) external view returns (BidStatus[] memory bidderBids);
}