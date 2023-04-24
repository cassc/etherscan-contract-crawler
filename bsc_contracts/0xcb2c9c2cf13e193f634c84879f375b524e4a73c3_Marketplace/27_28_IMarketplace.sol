// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.18;

interface IMarketplace {
    enum TokenType {
        ERC1155,
        ERC721
    }

    enum ListingType {
        Fixed,
        Auction
    }

    struct Offer {
        uint256 listingId;
        address offeror;
        uint256 quantity;
        address currency;
        uint256 pricePerToken;
        uint256 expTime;
    }

    struct ListingParams {
        address assetAddress;
        uint256 tokenId;
        uint256 startTime;
        uint256 period;
        uint256 quantity;
        address currency;
        uint256 reservePricePerToken;
        uint256 buyoutPricePerToken;
        ListingType listingType;
    }

    struct Listing {
        uint256 listingId;
        address owner;
        address assetAddress;
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

    event ListingAdded(
        uint256 indexed listingId,
        address indexed assetAddress,
        address indexed lister,
        Listing listing
    );

    event ListingUpdated(
        uint256 indexed listingId,
        address indexed listingCreator,
        Listing listing
    );

    event ListingRemoved(
        uint256 indexed listingId,
        address indexed listingCreator
    );

    event NewSale(
        uint256 indexed listingId,
        address indexed assetContract,
        address indexed lister,
        address buyer,
        uint256 quantity,
        uint256 price
    );

    event NewOffer(
        uint256 indexed listingId,
        address indexed offeror,
        ListingType indexed listingType,
        uint256 quantity,
        uint256 price,
        address currency
    );

    event AuctionClosed(
        uint256 indexed listingId,
        address indexed closer,
        bool indexed cancelled,
        address auctionCreator,
        address winningBidder
    );

    event PlatformFeeInfoUpdated(
        address indexed platformFeeWallet,
        uint256 platformFeeBps
    );

    event AuctionBufferUpdated(uint256 timeBuffer, uint256 bidBufferBps);

    function createListing(ListingParams memory _params) external;

    function updateListing(
        uint256 _listingId,
        uint256 _quantity,
        uint256 _reservePricePerToken,
        uint256 _buyoutPricePerToken,
        address _currency,
        uint256 _startTime,
        uint256 _period
    ) external;

    function cancelFixedListing(uint256 _listingId) external;

    function buy(
        uint256 _listingId,
        address _buyFor,
        uint256 _quantity,
        address _currency,
        uint256 _price
    ) external payable;

    function offer(
        uint256 _listingId,
        uint256 _quantity,
        address _currency,
        uint256 _pricePerToken,
        uint256 expTime
    ) external payable;

    function acceptOffer(
        uint256 _listingId,
        address _offeror,
        address _currency,
        uint256 _price
    ) external;

    function closeAuction(uint256 _listingId, address _closeFor) external;

    function getPlatformFeeInfo() external view returns (address, uint16);

    function setPlatformFeeInfo(
        address _platformFeeWallet,
        uint256 _platformFeeBps
    ) external;

    function getAllListings(
        uint256 _startId,
        uint256 _endId
    ) external view returns (Listing[] memory _allListings);

    function getAllValidListings(
        uint256 _startId,
        uint256 _endId
    ) external view returns (Listing[] memory _validListings);
}