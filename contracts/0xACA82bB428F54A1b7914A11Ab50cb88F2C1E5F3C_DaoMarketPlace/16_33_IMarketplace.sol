// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;



interface IMarketplace {
    /// @notice Type of the tokens that can be listed for sale.
    enum TokenType {
        ERC1155,
        ERC721
    }

    /**
     *  @notice The two types of listings.
     *          `Direct`: NFTs listed for sale at a fixed price.
     *          `Auction`: NFTs listed for sale in an auction.
     */
    enum ListingType {
        Direct,
        Auction
    }

    /**
     *  @notice The information related to either (1) an offer on a direct listing, or (2) a bid in an auction.
     *
     *  @dev The type of the listing at ID `lisingId` determins how the `Offer` is interpreted.
     *      If the listing is of type `Direct`, the `Offer` is interpreted as an offer to a direct listing.
     *      If the listing is of type `Auction`, the `Offer` is interpreted as a bid in an auction.
     *
     *  @param listingId      The uid of the listing the offer is made to.
     *  @param offeror        The account making the offer.
     *  @param quantityWanted The quantity of tokens from the listing wanted by the offeror.
     *                        This is the entire listing quantity if the listing is an auction.
     *  @param currency       The currency in which the offer is made.
     *  @param pricePerToken  The price per token offered to the lister.
     *  @param expirationTimestamp The timestamp after which a seller cannot accept this offer.
     */
    struct Offer {
        uint256 listingId;
        address offeror;
        uint256 quantityWanted;
        address currency;
        uint256 pricePerToken;
        uint256 expirationTimestamp;
    }

    /**
     *  @dev For use in `createListing` as a parameter type.
     *
     *  @param assetContract         The contract address of the NFT to list for sale.

     *  @param tokenId               The tokenId on `assetContract` of the NFT to list for sale.

     *  @param startTime             The unix timestamp after which the listing is active. For direct listings:
     *                               'active' means NFTs can be bought from the listing. For auctions,
     *                               'active' means bids can be made in the auction.
     *
     *  @param secondsUntilEndTime   No. of seconds after `startTime`, after which the listing is inactive.
     *                               For direct listings: 'inactive' means NFTs cannot be bought from the listing.
     *                               For auctions: 'inactive' means bids can no longer be made in the auction.
     *
     *  @param quantityToList        The quantity of NFT of ID `tokenId` on the given `assetContract` to list. For
     *                               ERC 721 tokens to list for sale, the contract strictly defaults this to `1`,
     *                               Regardless of the value of `quantityToList` passed.
     *
     *  @param currencyToAccept      For direct listings: the currency in which a buyer must pay the listing's fixed price
     *                               to buy the NFT(s). For auctions: the currency in which the bidders must make bids.
     *
     *  @param reservePricePerToken  For direct listings: this value is ignored. For auctions: the minimum bid amount of
     *                               the auction is `reservePricePerToken * quantityToList`
     *
     *  @param buyoutPricePerToken   For direct listings: interpreted as 'price per token' listed. For auctions: if
     *                               `buyoutPricePerToken` is greater than 0, and a bidder's bid is at least as great as
     *                               `buyoutPricePerToken * quantityToList`, the bidder wins the auction, and the auction
     *                               is closed.
     *
     *  @param listingType           The type of listing to create - a direct listing or an auction.
    **/
    struct ListingParameters {
        address assetContract;
        uint256 tokenId;
        address tokenHash;
        uint256 startTime;
        uint256 secondsUntilEndTime;
        uint256 quantityToList;
        address currencyToAccept;
        uint256 reservePricePerToken;
        uint256 buyoutPricePerToken;
        ListingType listingType;
    }

    /**
     *  @notice The information related to a listing; either (1) a direct listing, or (2) an auction listing.
     *
     *  @dev For direct listings:
     *          (1) `reservePricePerToken` is ignored.
     *          (2) `buyoutPricePerToken` is simply interpreted as 'price per token'.
     *
     *  @param listingId             The uid for the listing.
     *
     *  @param tokenOwner            The owner of the tokens listed for sale.  
     *
     *  @param assetContract         The contract address of the NFT to list for sale.

     *  @param tokenId               The tokenId on `assetContract` of the NFT to list for sale.

     *  @param startTime             The unix timestamp after which the listing is active. For direct listings:
     *                               'active' means NFTs can be bought from the listing. For auctions,
     *                               'active' means bids can be made in the auction.
     *
     *  @param endTime               The timestamp after which the listing is inactive.
     *                               For direct listings: 'inactive' means NFTs cannot be bought from the listing.
     *                               For auctions: 'inactive' means bids can no longer be made in the auction.
     *
     *  @param quantity              The quantity of NFT of ID `tokenId` on the given `assetContract` listed. For
     *                               ERC 721 tokens to list for sale, the contract strictly defaults this to `1`,
     *                               Regardless of the value of `quantityToList` passed.
     *
     *  @param currency              For direct listings: the currency in which a buyer must pay the listing's fixed price
     *                               to buy the NFT(s). For auctions: the currency in which the bidders must make bids.
     *
     *  @param reservePricePerToken  For direct listings: this value is ignored. For auctions: the minimum bid amount of
     *                               the auction is `reservePricePerToken * quantityToList`
     *
     *  @param buyoutPricePerToken   For direct listings: interpreted as 'price per token' listed. For auctions: if
     *                               `buyoutPricePerToken` is greater than 0, and a bidder's bid is at least as great as
     *                               `buyoutPricePerToken * quantityToList`, the bidder wins the auction, and the auction
     *                               is closed.
     *
     *  @param tokenType             The type of the token(s) listed for for sale -- ERC721 or ERC1155 
     *
     * @param listingType            The type of listing to create - a direct listing or an auction.
    **/
    struct Listing {
        uint256 listingId;
        address tokenHash;
        address tokenOwner;
        address assetContract;
        uint256 tokenId;
        uint256 startTime;
        uint256 endTime;
        uint256 quantity;
        address currency;
        uint256 reservePricePerToken;
        uint256 buyoutPricePerToken;
        TokenType tokenType;
        ListingType listingType;
    }

    struct ExsistListing {
        uint256 listingId;
        uint256 buyoutPricePerToken;
        uint256 reservePricePerToken;
        bool isExist;
        uint256 startTime;
        uint256 endTime;
        ListingType listingType;
    }

    /// @dev Emitted when a new listing is created.
    event ListingAdded(
        uint256 indexed listingId,
        address indexed tokenHash,
        address indexed assetContract,
        address lister,
        Listing listing
    );

    /// @dev Emitted when the parameters of a listing are updated.
    event ListingUpdated(uint256 indexed listingId,address indexed tokenHash, address indexed listingCreator);

    /// @dev Emitted when a listing is cancelled.
    event ListingRemoved(uint256 indexed listingId,address indexed tokenHash, address indexed listingCreator);

    /**
     * @dev Emitted when a buyer buys from a direct listing, or a lister accepts some
     *      buyer's offer to their direct listing.
     */
    event NewSale(
        uint256 indexed listingId,
        address indexed tokenHash,
        address indexed assetContract,
        address lister,
        address buyer,
        uint256 quantityBought,
        uint256 totalPricePaid
    );

    /// @dev Emitted when (1) a new offer is made to a direct listing, or (2) when a new bid is made in an auction.
    event NewOffer(
        uint256 indexed listingId,
        address indexed tokenHash,
        address indexed offeror,
        ListingType listingType,
        uint256 quantityWanted,
        uint256 totalOfferAmount,
        address currency
    );

    /// @dev Emitted when an auction is closed.
    event AuctionClosed(
        uint256 indexed listingId,
        address indexed tokenHash,
        address indexed closer,
        bool cancelled,
        address auctionCreator,
        address winningBidder
    );

    
    
    /**
     *  @notice Lets a token owner list tokens (ERC 721 or ERC 1155) for sale in a direct listing, or an auction.
     *
     *  @dev NFTs to list for sale in an auction are escrowed in Marketplace. For direct listings, the contract
     *       only checks whether the listing's creator owns and has approved Marketplace to transfer the NFTs to list.
     *
     *  @param _params The parameters that govern the listing to be created.
     */
    // function createListing(ListingParameters memory _params) external;

    /**
     *  @notice Lets a listing's creator edit the listing's parameters. A direct listing can be edited whenever.
     *          An auction listing cannot be edited after the auction has started.
     *
     *  @param _listingId            The uid of the lisitng to edit.
     *
     *  @param _reservePricePerToken For direct listings: this value is ignored. For auctions: the minimum bid amount of
     *                               the auction is `reservePricePerToken * quantityToList`
     *
     *  @param _buyoutPricePerToken  For direct listings: interpreted as 'price per token' listed. For auctions: if
     *                               `buyoutPricePerToken` is greater than 0, and a bidder's bid is at least as great as
     *                               `buyoutPricePerToken * quantityToList`, the bidder wins the auction, and the auction
     *                               is closed.
     */
    function updateListing(
        uint256 _listingId,
        uint256 _reservePricePerToken,
        uint256 _buyoutPricePerToken,
        uint256 endSeconds
    ) external;

    /**
     *  @notice Lets a direct listing creator cancel their listing.
     *
     *  @param _listingId The unique Id of the lisitng to cancel.
     */
    function cancelDirectListing(uint256 _listingId) external;

    /**
     *  @notice Lets someone buy a given quantity of tokens from a direct listing by paying the fixed price.
     *
     *  @param _listingId The uid of the direct lisitng to buy from.
     *
     *  @dev A sale will fail to execute if either:
     *          (1) buyer does not own or has not approved Marketplace to transfer the appropriate
     *              amount of currency (or hasn't sent the appropriate amount of native tokens)
     *
     *          (2) the lister does not own or has removed Markeplace's
     *              approval to transfer the tokens listed for sale.
     */
    function buy(
        uint256 _listingId
    ) external payable;

    /**
     *  @notice Lets someone make an offer to a direct listing, or bid in an auction.
     *
     *  @dev Each (address, listing ID) pair maps to a single unique offer. So e.g. if a buyer makes
     *       makes two offers to the same direct listing, the last offer is counted as the buyer's
     *       offer to that listing.
     *
     *  @param _listingId        The unique ID of the lisitng to make an offer/bid to.
     */
    function offer(
        uint256 _listingId
    ) external payable;

    /**
     * @notice Lets a listing's creator accept an offer to their direct listing.
     * @param _listingId The unique ID of the listing for which to accept the offer.
     * @param _totalPrice The total price of the offer that is to be accepted.
     */
     /*
    function acceptOffer(
        uint256 _listingId,
        uint256 _totalPrice
    ) external;*/

    /**
     *  @notice Lets any account close an auction on behalf of either the (1) auction's creator, or (2) winning bidder.
     *              For (1): The auction creator is sent the the winning bid amount.
     *              For (2): The winning bidder is sent the auctioned NFTs.
     *
     *  @param _listingId The uid of the listing (the auction to close).
     *  @param _closeFor For whom the auction is being closed - the auction creator or winning bidder.
     */
    function closeAuction(uint256 _listingId, address _closeFor) external;
}