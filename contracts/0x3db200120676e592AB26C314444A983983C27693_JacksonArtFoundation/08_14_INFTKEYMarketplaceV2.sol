// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity =0.8.9;
pragma abicoder v2;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

interface INFTKEYMarketplaceV2 {
    struct Listing {
        uint256 tokenId;
        uint256 value;
        address seller;
        uint256 expireTimestamp;
    }

    struct Bid {
        uint256 tokenId;
        uint256 value;
        address bidder;
        uint256 expireTimestamp;
    }

    struct TokenBids {
        EnumerableSet.AddressSet bidders;
        mapping(address => Bid) bids;
    }

    struct ERC721Market {
        EnumerableSet.UintSet tokenIdWithListing;
        mapping(uint256 => Listing) listings;
        EnumerableSet.UintSet tokenIdWithBid;
        mapping(uint256 => TokenBids) bids;
    }

    event TokenListed(
        address indexed erc721Address,
        uint256 indexed tokenId,
        Listing listing,
        uint256 price,
        address seller,
         uint256 timestamp,
          uint256 isAuction
    );
    event TokenDelisted(
        address indexed erc721Address,
        uint256 indexed tokenId,
        Listing listing,
        address seller
    );
    event Priceupdate (
        address indexed erc721Address,
        uint256 indexed tokenId,
        uint256 Price,
        address seller,
        uint256 timestamp
    );
    event TokenBidEntered(
        address indexed erc721Address,
        uint256 indexed tokenId,
        Bid bid,
        uint256 newbid,
        uint256 timestamp
    );
    event TokenBidWithdrawn(
        address indexed erc721Address,
        uint256 indexed tokenId,
        Bid bid
       
    );
  event TokenBought(
        address indexed erc721Address,
        uint256 indexed tokenId,
        address indexed buyer,
        Listing listing,
        uint256 serviceFee,
        uint256 royaltyFee,
        address seller,
        uint256 price
    );
    event TokenBidAccepted(
        address indexed erc721Address,
        uint256 indexed tokenId,
        address indexed seller,
        Bid bid,
        uint256 serviceFee,
        uint256 royaltyFee,
        address buyer,
        uint256 price
    );

    /**
     * @dev List token for sale
     * @param tokenId erc721 token Id
     * @param value min price to sell the token
     * @param expireTimestamp when would this listing expire
     */
    function listToken(
        address erc721Address,
        uint256 tokenId,
        uint256 value,
        uint256 expireTimestamp,
        uint256 isauction
    ) external;

    /**
     * @dev Delist token for sale
     * @param tokenId erc721 token Id
     */
    function delistToken(address erc721Address, uint256 tokenId) external;

        /**
     * @dev Delist token for sale
     * @param tokenId erc721 token Id
     */
    //  function Changeprice(address erc721Address, uint256 tokenId) external;
    /**
     * @dev Buy token
     * @param tokenId erc721 token Id
     */
    function buyToken(address erc721Address, uint256 tokenId) external payable;

    /**
     * @dev Enter bid for token
     * @param tokenId erc721 token Id
     * @param value price in payment token
     * @param expireTimestamp when would this bid expire
     */
    function enterBidForToken(
        address erc721Address,
        uint256 tokenId,
        uint256 value,
        uint256 expireTimestamp
    ) external;

    /**
     * @dev Withdraw bid for token
     * @param tokenId erc721 token Id
     */
    function withdrawBidForToken(address erc721Address, uint256 tokenId)
        external;

    /**
     * @dev Accept a bid of token from a bidder
     * @param tokenId erc721 token Id
     * @param bidder bidder address
     * @param value value of a bid to avoid frontrun attack
     */
    function acceptBidForToken(
        address erc721Address,
        uint256 tokenId,
        address bidder,
        uint256 value
    ) external;

    /**
     * @dev Show if listing and bid are enabled
     */
    function isTradingEnabled() external view returns (bool);

    /**
     * @dev get current listing of a token
     * @param tokenId erc721 token Id
     * @return current valid listing or empty listing struct
     */
    function getTokenListing(address erc721Address, uint256 tokenId)
        external
        view
        returns (Listing memory);

    /**
     * @dev get count of listings
     */
    function numTokenListings(address erc721Address)
        external
        view
        returns (uint256);

    /**
     * @dev get current valid listings by size
     * @param from index to start
     * @param size size to query
     * @return current valid listings
     * This to help batch query when list gets big
     */
    function getTokenListings(
        address erc721Address,
        uint256 from,
        uint256 size
    ) external view returns (Listing[] memory);

    /**
     * @dev get bidder's bid on a token
     * @param tokenId erc721 token Id
     * @param bidder address of a bidder
     * @return Valid bid or empty bid
     */
    function getBidderTokenBid(
        address erc721Address,
        uint256 tokenId,
        address bidder
    ) external view returns (Bid memory);

    /**
     * @dev get all valid bids of a token
     * @param tokenId erc721 token Id
     * @return Valid bids of a token
     */
    function getTokenBids(address erc721Address, uint256 tokenId)
        external
        view
        returns (Bid[] memory);

    /**
     * @dev get count of tokens with bid(s)
     */
    function numTokenWithBids(address erc721Address)
        external
        view
        returns (uint256);

    /**
     * @dev get highest bid of a token
     * @param tokenId erc721 token Id
     * @return Valid highest bid or empty bid
     */
    function getTokenHighestBid(address erc721Address, uint256 tokenId)
        external
        view
        returns (Bid memory);

    /**
     * @dev get current highest bids
     * @param from index to start
     * @param size size to query
     * @return current highest bids
     * This to help batch query when list gets big
     */
    function getTokenHighestBids(
        address erc721Address,
        uint256 from,
        uint256 size
    ) external view returns (Bid[] memory);

    /**
     * @dev get all bids of a bidder address
     * @return All valid bids of a bidder
     */
    function getBidderBids(
        address erc721Address,
        address bidder,
        uint256 from,
        uint256 size
    ) external view returns (Bid[] memory);

    /**
     * @dev Surface minimum listing and bid time range
     */
    function actionTimeOutRangeMin() external view returns (uint256);

    /**
     * @dev Surface maximum listing and bid time range
     */
    function actionTimeOutRangeMax() external view returns (uint256);

    /**
     * @dev Payment token address
     */
    function paymentToken() external view returns (address);

    /**
     * @dev Service fee
     * @return fee fraction based on 1000
     */
    function serviceFee() external view returns (uint8);
}