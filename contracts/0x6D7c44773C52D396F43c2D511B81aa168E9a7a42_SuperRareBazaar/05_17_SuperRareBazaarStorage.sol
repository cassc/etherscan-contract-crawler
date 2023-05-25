// SPDX-License-Identifier: MIT
pragma solidity 0.7.3;

import "../../marketplace/IMarketplaceSettings.sol";
import "../../royalty/creator/IERC721CreatorRoyalty.sol";
import "../../payments/IPayments.sol";
import "../../registry/spaces/ISpaceOperatorRegistry.sol";
import "../../registry/token/IApprovedTokenRegistry.sol";
import "../../royalty/creator/IRoyaltyEngine.sol";

/// @author koloz
/// @title SuperRareBazaar Storage Contract
/// @dev STORAGE CAN ONLY BE APPENDED NOT INSERTED OR MODIFIED
contract SuperRareBazaarStorage {
    /////////////////////////////////////////////////////////////////////////
    // Constants
    /////////////////////////////////////////////////////////////////////////

    // Auction Types
    bytes32 public constant COLDIE_AUCTION = "COLDIE_AUCTION";
    bytes32 public constant SCHEDULED_AUCTION = "SCHEDULED_AUCTION";
    bytes32 public constant NO_AUCTION = bytes32(0);

    /////////////////////////////////////////////////////////////////////////
    // Structs
    /////////////////////////////////////////////////////////////////////////

    // The Offer truct for a given token:
    // buyer - address of person making the offer
    // currencyAddress - address of the erc20 token used for an offer
    //                   or the zero address for eth
    // amount - offer in wei/full erc20 value
    // marketplaceFee - the amount that is taken by the network on offer acceptance.
    struct Offer {
        address payable buyer;
        uint256 amount;
        uint256 timestamp;
        uint8 marketplaceFee;
        bool convertible;
    }

    // The Sale Price struct for a given token:
    // seller - address of the person selling the token
    // currencyAddress - address of the erc20 token used for an offer
    //                   or the zero address for eth
    // amount - offer in wei/full erc20 value
    struct SalePrice {
        address payable seller;
        address currencyAddress;
        uint256 amount;
        address payable[] splitRecipients;
        uint8[] splitRatios;
    }

    // Structure of an Auction:
    // auctionCreator - creator of the auction
    // creationBlock - time that the auction was created/configured
    // startingBlock - time that the auction starts on
    // lengthOfAuction - how long the auction is
    // currencyAddress - address of the erc20 token used for an offer
    //                   or the zero address for eth
    // minimumBid - min amount a bidder can bid at the start of an auction.
    // auctionType - type of auction, represented as the formatted bytes 32 string
    struct Auction {
        address payable auctionCreator;
        uint256 creationBlock;
        uint256 startingTime;
        uint256 lengthOfAuction;
        address currencyAddress;
        uint256 minimumBid;
        bytes32 auctionType;
        address payable[] splitRecipients;
        uint8[] splitRatios;
    }

    struct Bid {
        address payable bidder;
        address currencyAddress;
        uint256 amount;
        uint8 marketplaceFee;
    }

    /////////////////////////////////////////////////////////////////////////
    // Events
    /////////////////////////////////////////////////////////////////////////
    event Sold(
        address indexed _originContract,
        address indexed _buyer,
        address indexed _seller,
        address _currencyAddress,
        uint256 _amount,
        uint256 _tokenId
    );

    event SetSalePrice(
        address indexed _originContract,
        address indexed _currencyAddress,
        address _target,
        uint256 _amount,
        uint256 _tokenId,
        address payable[] _splitRecipients,
        uint8[] _splitRatios
    );

    event OfferPlaced(
        address indexed _originContract,
        address indexed _bidder,
        address indexed _currencyAddress,
        uint256 _amount,
        uint256 _tokenId,
        bool _convertible
    );

    event AcceptOffer(
        address indexed _originContract,
        address indexed _bidder,
        address indexed _seller,
        address _currencyAddress,
        uint256 _amount,
        uint256 _tokenId,
        address payable[] _splitAddresses,
        uint8[] _splitRatios
    );

    event CancelOffer(
        address indexed _originContract,
        address indexed _bidder,
        address indexed _currencyAddress,
        uint256 _amount,
        uint256 _tokenId
    );

    event NewAuction(
        address indexed _contractAddress,
        uint256 indexed _tokenId,
        address indexed _auctionCreator,
        address _currencyAddress,
        uint256 _startingTime,
        uint256 _minimumBid,
        uint256 _lengthOfAuction
    );

    event CancelAuction(
        address indexed _contractAddress,
        uint256 indexed _tokenId,
        address indexed _auctionCreator
    );

    event AuctionBid(
        address indexed _contractAddress,
        address indexed _bidder,
        uint256 indexed _tokenId,
        address _currencyAddress,
        uint256 _amount,
        bool _startedAuction,
        uint256 _newAuctionLength,
        address _previousBidder
    );

    event AuctionSettled(
        address indexed _contractAddress,
        address indexed _bidder,
        address _seller,
        uint256 indexed _tokenId,
        address _currencyAddress,
        uint256 _amount
    );

    /////////////////////////////////////////////////////////////////////////
    // State Variables
    /////////////////////////////////////////////////////////////////////////

    // Current marketplace settings implementation to be used
    IMarketplaceSettings public marketplaceSettings;

    // Current creator royalty implementation to be used
    IERC721CreatorRoyalty public royaltyRegistry;

    // Address of the global royalty engine being used.
    IRoyaltyEngineV1 public royaltyEngine;

    // Current SuperRareMarketplace implementation to be used
    address public superRareMarketplace;

    // Current SuperRareAuctionHouse implementation to be used
    address public superRareAuctionHouse;

    // Current SpaceOperatorRegistry implementation to be used.
    ISpaceOperatorRegistry public spaceOperatorRegistry;

    // Current ApprovedTokenRegistry implementation being used for currencies.
    IApprovedTokenRegistry public approvedTokenRegistry;

    // Current payments contract to use
    IPayments public payments;

    // Address to be used for staking registry.
    address public stakingRegistry;

    // Address of the network beneficiary
    address public networkBeneficiary;

    // A minimum increase in bid amount when out bidding someone.
    uint8 public minimumBidIncreasePercentage; // 10 = 10%

    // Maximum length that an auction can be.
    uint256 public maxAuctionLength;

    // Extension length for an auction
    uint256 public auctionLengthExtension;

    // Offer cancellation delay
    uint256 public offerCancelationDelay;

    // Mapping from contract to mapping of tokenId to mapping of target to sale price.
    mapping(address => mapping(uint256 => mapping(address => SalePrice)))
        public tokenSalePrices;

    // Mapping from contract to mapping of tokenId to mapping of currency address to Current Offer.
    mapping(address => mapping(uint256 => mapping(address => Offer)))
        public tokenCurrentOffers;

    // Mapping from contract to mapping of tokenId to Auction.
    mapping(address => mapping(uint256 => Auction)) public tokenAuctions;

    // Mapping from contract to mapping of tokenId to Bid.
    mapping(address => mapping(uint256 => Bid)) public auctionBids;

    uint256[50] private __gap;
    /// ALL NEW STORAGE MUST COME AFTER THIS
}