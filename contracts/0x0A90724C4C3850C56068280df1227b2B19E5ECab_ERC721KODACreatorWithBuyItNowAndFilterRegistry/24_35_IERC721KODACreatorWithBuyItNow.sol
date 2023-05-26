pragma solidity 0.8.17;

// SPDX-License-Identifier: MIT

/// @author KnownOrigin Labs - https://knownorigin.io/
interface IERC721KODACreatorWithBuyItNow {
    error AlreadyListed();
    error EditionNotListed();
    error EditionSalesDisabled();
    error InvalidEdition();
    error InvalidFeesTotal();
    error InvalidListing();
    error InvalidPrice();
    error TooEarly();
    error TooLate();
    error TransferFailed();
    error InvalidToken();

    event BuyNowDeListed(uint256 indexed _editionId);

    event BuyNowPriceChanged(uint256 indexed _editionId, uint256 _price);

    event BuyNowPurchased(
        uint256 indexed _tokenId,
        address _buyer,
        address _currentOwner,
        uint256 _price
    );

    event BuyNowTokenDeListed(uint256 indexed _tokenId);

    event BuyNowTokenPriceChanged(uint256 indexed _tokenId, uint256 _price);

    event BuyNowTokenPurchased(
        uint256 indexed _tokenId,
        address _caller,
        address _recipient,
        address _currentOwner,
        uint256 _price
    );

    event ListedEditionForBuyNow(
        uint256 indexed _editionId,
        uint96 _price,
        uint128 _startDate
    );

    event ListedTokenForBuyNow(
        address indexed _seller,
        uint256 indexed _tokenId,
        uint96 _price,
        uint128 _startDate,
        uint128 _endDate
    );

    struct EditionListing {
        uint128 price;
        uint128 startDate;
        uint128 endDate;
    }

    struct TokenListing {
        address seller;
        uint128 price;
    }

    /// @dev allows the purchase of the next available token for sale from an edition listing
    function buyEditionToken(
        uint256 _editionId,
        address _recipient
    ) external payable;

    /// @dev allows the owner of a token to create a secondary buy it now listing
    function createTokenBuyItNowListing(
        uint256 _tokenId,
        uint96 _listingPrice,
        uint128 _startDate,
        uint128 _endDate
    ) external;

    /// @dev allows the owner of a token to remove a listing for the token
    function deleteTokenBuyItNowListing(uint256 _tokenId) external;

    /// @dev allows the owner of a token to update the price
    function updateTokenBuyItNowListingPrice(
        uint256 _tokenId,
        uint96 _listingPrice
    ) external;

    /// @dev allows the purchase of a token listed for sale
    function buyToken(uint256 _tokenId, address _recipient) external payable;

    /// @dev Get a token listing just from token ID and not worrying about current Owner
    function getTokenListing(
        uint256 _tokenId
    ) external view returns (TokenListing memory);

    /// @dev allows the contract owner to create a listing to enable sales of tokens from an edition
    function createEditionBuyItNowListing(
        uint256 _editionId,
        uint96 _listingPrice,
        uint128 _startDate,
        uint128 _endDate
    ) external;

    /// @dev allows the contract owner to remove an edition listing
    function deleteEditionBuyItNowListing(uint256 _editionId) external;

    /// @dev allows the contract owner to create a pre-minted edition and immediately list it for buy it now sales
    function mintAndListEditionForBuyNow(
        uint32 _editionSize,
        uint96 _listingPrice,
        uint128 _startDate,
        uint128 _endDate,
        string calldata _uri
    ) external returns (uint256);

    /// @dev allows the contract owner to create an open edition and immediately list it for buy it now sales
    function setupAndListOpenEdition(
        string calldata _uri,
        uint96 _listingPrice,
        uint128 _startDate,
        uint128 _endDate,
        uint32 _customMintLimit
    ) external returns (uint256 _editionId);

    /// @dev allows the contract owner to create an open edition and immediately list it for buy it now sales
    function setupAndListOpenEditionAsCollaboration(
        string calldata _uri,
        uint96 _listingPrice,
        uint128 _startDate,
        uint128 _endDate,
        uint32 _customMintLimit,
        address _collabFundsHandler
    ) external returns (uint256 _editionId);

    /// @dev allows the contract owner to update the price of edition tokens listed for sale
    function updateEditionBuyItNowListingPrice(
        uint256 _editionId,
        uint96 _listingPrice
    ) external;
}