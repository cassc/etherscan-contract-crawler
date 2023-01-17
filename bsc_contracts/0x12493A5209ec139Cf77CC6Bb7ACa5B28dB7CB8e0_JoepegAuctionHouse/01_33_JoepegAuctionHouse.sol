// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {SafeCast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import {PausableUpgradeable} from "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import {ERC165Upgradeable} from "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165Upgradeable.sol";
import {IERC20, SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC721Receiver} from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

import "./Errors.sol";
import {ICurrencyManager} from "./interfaces/ICurrencyManager.sol";
import {IProtocolFeeManager} from "./interfaces/IProtocolFeeManager.sol";
import {IRoyaltyFeeManager} from "./interfaces/IRoyaltyFeeManager.sol";
import {IWAVAX} from "./interfaces/IWAVAX.sol";
import {RoyaltyFeeTypes} from "./libraries/RoyaltyFeeTypes.sol";
import {SafePausableUpgradeable} from "./utils/SafePausableUpgradeable.sol";

/**
 * @title JoepegAuctionHouse
 * @notice An auction house that supports running English and Dutch auctions on ERC721 tokens
 */
contract JoepegAuctionHouse is
    Initializable,
    SafePausableUpgradeable,
    ReentrancyGuardUpgradeable,
    IERC721Receiver
{
    using SafeCast for uint256;
    using SafeERC20 for IERC20;

    using RoyaltyFeeTypes for RoyaltyFeeTypes.FeeAmountPart;

    struct DutchAuction {
        address creator;
        uint96 startTime;
        address currency;
        uint96 endTime;
        uint256 nonce;
        uint256 startPrice;
        uint256 endPrice;
        uint256 dropInterval;
        uint256 minPercentageToAsk;
    }

    struct EnglishAuction {
        address creator;
        address currency;
        uint96 startTime;
        address lastBidder;
        uint96 endTime;
        uint256 nonce;
        uint256 lastBidPrice;
        uint256 startPrice;
        uint256 minPercentageToAsk;
    }

    uint256 public constant PERCENTAGE_PRECISION = 10000;

    address public immutable WAVAX;

    ICurrencyManager public currencyManager;
    IProtocolFeeManager public protocolFeeManager;
    IRoyaltyFeeManager public royaltyFeeManager;

    address public protocolFeeRecipient;

    /// @notice Stores latest auction nonce per user
    /// @dev (user address => latest nonce)
    mapping(address => uint256) public userLatestAuctionNonce;

    /// @notice Stores Dutch Auction data for NFTs
    /// @dev (collection address => token id => dutch auction)
    mapping(address => mapping(uint256 => DutchAuction)) public dutchAuctions;

    /// @notice Stores English Auction data for NFTs
    /// @dev (collection address => token id => english auction)
    mapping(address => mapping(uint256 => EnglishAuction))
        public englishAuctions;

    /// @notice Required minimum percent increase from last bid in order to
    /// place a new bid on an English Auction
    uint256 public englishAuctionMinBidIncrementPct;

    /// @notice Represents both:
    /// - Number of seconds before an English Auction ends where any new
    ///   bid will extend the auction's end time
    /// - Number of seconds to extend an English Auction's end time by
    uint96 public englishAuctionRefreshTime;

    event DutchAuctionStart(
        address indexed creator,
        address currency,
        address indexed collection,
        uint256 indexed tokenId,
        uint256 nonce,
        uint256 startPrice,
        uint256 endPrice,
        uint96 startTime,
        uint96 endTime,
        uint256 dropInterval,
        uint256 minPercentageToAsk
    );
    event DutchAuctionSettle(
        address indexed creator,
        address buyer,
        address currency,
        address indexed collection,
        uint256 indexed tokenId,
        uint256 nonce,
        uint256 price
    );
    event DutchAuctionCancel(
        address indexed caller,
        address creator,
        address indexed collection,
        uint256 indexed tokenId,
        uint256 nonce
    );

    event EnglishAuctionStart(
        address indexed creator,
        address currency,
        address indexed collection,
        uint256 indexed tokenId,
        uint256 nonce,
        uint256 startPrice,
        uint96 startTime,
        uint96 endTime,
        uint256 minPercentageToAsk
    );
    event EnglishAuctionPlaceBid(
        address indexed creator,
        address bidder,
        address currency,
        address indexed collection,
        uint256 indexed tokenId,
        uint256 nonce,
        uint256 bidAmount,
        uint96 endTimeExtension
    );
    event EnglishAuctionSettle(
        address indexed creator,
        address buyer,
        address currency,
        address indexed collection,
        uint256 indexed tokenId,
        uint256 nonce,
        uint256 price
    );
    event EnglishAuctionCancel(
        address indexed caller,
        address creator,
        address indexed collection,
        uint256 indexed tokenId,
        uint256 nonce
    );

    event CurrencyManagerSet(
        address indexed oldCurrencyManager,
        address indexed newCurrencyManager
    );
    event EnglishAuctionMinBidIncrementPctSet(
        uint256 indexed oldEnglishAuctionMinBidIncrementPct,
        uint256 indexed newEnglishAuctionMinBidIncrementPct
    );
    event EnglishAuctionRefreshTimeSet(
        uint96 indexed oldEnglishAuctionRefreshTime,
        uint96 indexed newEnglishAuctionRefreshTime
    );
    event ProtocolFeeManagerSet(
        address indexed oldProtocolFeeManager,
        address indexed newProtocolFeeManager
    );
    event ProtocolFeeRecipientSet(
        address indexed oldProtocolFeeRecipient,
        address indexed newProtocolFeeRecipient
    );
    event RoyaltyFeeManagerSet(
        address indexed oldRoyaltyFeeManager,
        address indexed newRoyaltyFeeManager
    );

    event RoyaltyPayment(
        address indexed collection,
        uint256 indexed tokenId,
        address indexed royaltyRecipient,
        address currency,
        uint256 amount
    );

    modifier isSupportedCurrency(IERC20 _currency) {
        if (!currencyManager.isCurrencyWhitelisted(address(_currency))) {
            revert JoepegAuctionHouse__UnsupportedCurrency();
        } else {
            _;
        }
    }

    modifier isValidStartTime(uint256 _startTime) {
        if (_startTime < block.timestamp) {
            revert JoepegAuctionHouse__InvalidStartTime();
        } else {
            _;
        }
    }

    modifier isValidMinPercentageToAsk(uint256 _minPercentageToAsk) {
        if (
            _minPercentageToAsk == 0 ||
            _minPercentageToAsk > PERCENTAGE_PRECISION
        ) {
            revert JoepegAuctionHouse__InvalidMinPercentageToAsk();
        } else {
            _;
        }
    }

    ///  @notice Constructor
    ///  @param _wavax address of WAVAX
    constructor(address _wavax) {
        WAVAX = _wavax;
    }

    ///  @notice Initializer
    ///  @param _englishAuctionMinBidIncrementPct minimum bid increment percentage for English Auctions
    ///  @param _englishAuctionRefreshTime refresh time for English auctions
    ///  @param _currencyManager currency manager address
    ///  @param _protocolFeeManager protocol fee manager address
    ///  @param _royaltyFeeManager royalty fee manager address
    ///  @param _protocolFeeRecipient protocol fee recipient
    function initialize(
        uint256 _englishAuctionMinBidIncrementPct,
        uint96 _englishAuctionRefreshTime,
        address _currencyManager,
        address _protocolFeeManager,
        address _royaltyFeeManager,
        address _protocolFeeRecipient
    ) public initializer {
        __SafePausable_init();
        __ReentrancyGuard_init();

        _updateEnglishAuctionMinBidIncrementPct(
            _englishAuctionMinBidIncrementPct
        );
        _updateEnglishAuctionRefreshTime(_englishAuctionRefreshTime);
        _updateCurrencyManager(_currencyManager);
        _updateProtocolFeeManager(_protocolFeeManager);
        _updateRoyaltyFeeManager(_royaltyFeeManager);
        _updateProtocolFeeRecipient(_protocolFeeRecipient);
    }

    /// @notice Required implementation for IERC721Receiver
    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure returns (bytes4) {
        return this.onERC721Received.selector;
    }

    /// @notice Starts an English Auction for an ERC721 token
    /// @dev Note this requires the auction house to hold the ERC721 token in escrow
    /// @param _collection address of ERC721 token
    /// @param _tokenId token id of ERC721 token
    /// @param _currency address of currency to sell ERC721 token for
    /// @param _duration number of seconds for English Auction to run
    /// @param _startPrice minimum starting bid price
    /// @param _minPercentageToAsk minimum percentage of the gross amount that goes to ask
    function startEnglishAuction(
        IERC721 _collection,
        uint256 _tokenId,
        IERC20 _currency,
        uint96 _duration,
        uint256 _startPrice,
        uint256 _minPercentageToAsk
    )
        external
        whenNotPaused
        isSupportedCurrency(_currency)
        isValidMinPercentageToAsk(_minPercentageToAsk)
        nonReentrant
    {
        _addEnglishAuction(
            _collection,
            _tokenId,
            _currency,
            block.timestamp.toUint96(),
            _duration,
            _startPrice,
            _minPercentageToAsk
        );
    }

    /// @notice Schedules an English Auction for an ERC721 token
    /// @dev Note this requires the auction house to hold the ERC721 token in escrow
    /// @param _collection address of ERC721 token
    /// @param _tokenId token id of ERC721 token
    /// @param _currency address of currency to sell ERC721 token for
    /// @param _startTime time to start the auction
    /// @param _duration number of seconds for English Auction to run
    /// @param _startPrice minimum starting bid price
    /// @param _minPercentageToAsk minimum percentage of the gross amount that goes to ask
    function scheduleEnglishAuction(
        IERC721 _collection,
        uint256 _tokenId,
        IERC20 _currency,
        uint96 _startTime,
        uint96 _duration,
        uint256 _startPrice,
        uint256 _minPercentageToAsk
    )
        external
        whenNotPaused
        isSupportedCurrency(_currency)
        isValidStartTime(_startTime)
        isValidMinPercentageToAsk(_minPercentageToAsk)
        nonReentrant
    {
        _addEnglishAuction(
            _collection,
            _tokenId,
            _currency,
            _startTime,
            _duration,
            _startPrice,
            _minPercentageToAsk
        );
    }

    function _addEnglishAuction(
        IERC721 _collection,
        uint256 _tokenId,
        IERC20 _currency,
        uint96 _startTime,
        uint96 _duration,
        uint256 _startPrice,
        uint256 _minPercentageToAsk
    ) internal {
        if (_duration == 0) {
            revert JoepegAuctionHouse__InvalidDuration();
        }
        address collectionAddress = address(_collection);
        if (
            englishAuctions[collectionAddress][_tokenId].creator != address(0)
        ) {
            revert JoepegAuctionHouse__AuctionAlreadyExists();
        }

        uint256 nonce = userLatestAuctionNonce[msg.sender];
        EnglishAuction memory auction = EnglishAuction({
            creator: msg.sender,
            nonce: nonce,
            currency: address(_currency),
            lastBidder: address(0),
            lastBidPrice: 0,
            startTime: _startTime,
            endTime: _startTime + _duration,
            startPrice: _startPrice,
            minPercentageToAsk: _minPercentageToAsk
        });
        englishAuctions[collectionAddress][_tokenId] = auction;
        userLatestAuctionNonce[msg.sender] = nonce + 1;

        // Hold ERC721 token in escrow
        _collection.safeTransferFrom(msg.sender, address(this), _tokenId);

        emit EnglishAuctionStart(
            auction.creator,
            auction.currency,
            collectionAddress,
            _tokenId,
            auction.nonce,
            auction.startPrice,
            _startTime,
            auction.endTime,
            auction.minPercentageToAsk
        );
    }

    /// @notice Place bid on a running English Auction
    /// @param _collection address of ERC721 token
    /// @param _tokenId token id of ERC721 token
    /// @param _amount amount of currency to bid
    function placeEnglishAuctionBid(
        IERC721 _collection,
        uint256 _tokenId,
        uint256 _amount
    ) external whenNotPaused nonReentrant {
        EnglishAuction memory auction = englishAuctions[address(_collection)][
            _tokenId
        ];
        address currency = auction.currency;
        if (currency == address(0)) {
            revert JoepegAuctionHouse__NoAuctionExists();
        }

        IERC20(currency).safeTransferFrom(msg.sender, address(this), _amount);
        _placeEnglishAuctionBid(_collection, _tokenId, _amount, auction);
    }

    /// @notice Place bid on a running English Auction using AVAX and/or WAVAX
    /// @param _collection address of ERC721 token
    /// @param _tokenId token id of ERC721 token
    /// @param _wavaxAmount amount of WAVAX to bid
    function placeEnglishAuctionBidWithAVAXAndWAVAX(
        IERC721 _collection,
        uint256 _tokenId,
        uint256 _wavaxAmount
    ) external payable whenNotPaused nonReentrant {
        EnglishAuction memory auction = englishAuctions[address(_collection)][
            _tokenId
        ];
        address currency = auction.currency;
        if (currency != WAVAX) {
            revert JoepegAuctionHouse__CurrencyMismatch();
        }

        if (msg.value > 0) {
            // Wrap AVAX into WAVAX
            IWAVAX(WAVAX).deposit{value: msg.value}();
        }
        if (_wavaxAmount > 0) {
            IERC20(WAVAX).safeTransferFrom(
                msg.sender,
                address(this),
                _wavaxAmount
            );
        }
        _placeEnglishAuctionBid(
            _collection,
            _tokenId,
            msg.value + _wavaxAmount,
            auction
        );
    }

    /// @notice Settles an English Auction
    /// @dev Note:
    /// - Can be called by creator at any time (including before the auction's end time to accept the
    ///   current latest bid)
    /// - Can be called by anyone after the auction ends
    /// - Transfers funds and fees appropriately to seller, royalty receiver, and protocol fee recipient
    /// - Transfers ERC721 token to last highest bidder
    /// @param _collection address of ERC721 token
    /// @param _tokenId token id of ERC721 token
    function settleEnglishAuction(IERC721 _collection, uint256 _tokenId)
        external
        whenNotPaused
        nonReentrant
    {
        address collectionAddress = address(_collection);
        EnglishAuction memory auction = englishAuctions[collectionAddress][
            _tokenId
        ];
        if (auction.creator == address(0)) {
            revert JoepegAuctionHouse__NoAuctionExists();
        }
        if (auction.lastBidPrice == 0) {
            revert JoepegAuctionHouse__EnglishAuctionCannotSettleWithoutBid();
        }
        if (block.timestamp < auction.startTime) {
            revert JoepegAuctionHouse__EnglishAuctionCannotSettleUnstartedAuction();
        }
        if (
            msg.sender != auction.creator && block.timestamp < auction.endTime
        ) {
            revert JoepegAuctionHouse__EnglishAuctionOnlyCreatorCanSettleBeforeEndTime();
        }

        delete englishAuctions[collectionAddress][_tokenId];

        // Settle auction using latest bid
        _transferFeesAndFunds(
            collectionAddress,
            _tokenId,
            IERC20(auction.currency),
            address(this),
            auction.creator,
            auction.lastBidPrice,
            auction.minPercentageToAsk
        );

        _collection.safeTransferFrom(
            address(this),
            auction.lastBidder,
            _tokenId
        );

        emit EnglishAuctionSettle(
            auction.creator,
            auction.lastBidder,
            auction.currency,
            collectionAddress,
            _tokenId,
            auction.nonce,
            auction.lastBidPrice
        );
    }

    /// @notice Cancels an English Auction
    /// @dev Note:
    /// - Can only be called by auction creator
    /// - Can only be cancelled if no bids have been placed
    /// @param _collection address of ERC721 token
    /// @param _tokenId token id of ERC721 token
    function cancelEnglishAuction(IERC721 _collection, uint256 _tokenId)
        external
        whenNotPaused
        nonReentrant
    {
        address collectionAddress = address(_collection);
        EnglishAuction memory auction = englishAuctions[collectionAddress][
            _tokenId
        ];
        if (msg.sender != auction.creator) {
            revert JoepegAuctionHouse__OnlyAuctionCreatorCanCancel();
        }
        if (auction.lastBidder != address(0)) {
            revert JoepegAuctionHouse__EnglishAuctionCannotCancelWithExistingBid();
        }

        delete englishAuctions[collectionAddress][_tokenId];

        _collection.safeTransferFrom(address(this), auction.creator, _tokenId);

        emit EnglishAuctionCancel(
            msg.sender,
            auction.creator,
            collectionAddress,
            _tokenId,
            auction.nonce
        );
    }

    /// @notice Only owner function to cancel an English Auction in case of emergencies
    /// @param _collection address of ERC721 token
    /// @param _tokenId token id of ERC721 token
    function emergencyCancelEnglishAuction(
        IERC721 _collection,
        uint256 _tokenId
    ) external nonReentrant onlyOwner {
        address collectionAddress = address(_collection);
        EnglishAuction memory auction = englishAuctions[collectionAddress][
            _tokenId
        ];
        if (auction.creator == address(0)) {
            revert JoepegAuctionHouse__NoAuctionExists();
        }

        address lastBidder = auction.lastBidder;
        uint256 lastBidPrice = auction.lastBidPrice;

        delete englishAuctions[collectionAddress][_tokenId];

        _collection.safeTransferFrom(address(this), auction.creator, _tokenId);

        if (lastBidPrice > 0) {
            IERC20(auction.currency).safeTransfer(lastBidder, lastBidPrice);
        }

        emit EnglishAuctionCancel(
            msg.sender,
            auction.creator,
            collectionAddress,
            _tokenId,
            auction.nonce
        );
    }

    /// @notice Starts a Dutch Auction for an ERC721 token
    /// @dev Note:
    /// - Requires the auction house to hold the ERC721 token in escrow
    /// - Drops in price every `dutchAuctionDropInterval` seconds in equal
    ///   amounts
    /// @param _collection address of ERC721 token
    /// @param _tokenId token id of ERC721 token
    /// @param _currency address of currency to sell ERC721 token for
    /// @param _duration number of seconds for Dutch Auction to run
    /// @param _dropInterval number of seconds between each drop in price
    /// @param _startPrice starting sell price
    /// @param _endPrice ending sell price
    /// @param _minPercentageToAsk minimum percentage of the gross amount that goes to ask
    function startDutchAuction(
        IERC721 _collection,
        uint256 _tokenId,
        IERC20 _currency,
        uint96 _duration,
        uint256 _dropInterval,
        uint256 _startPrice,
        uint256 _endPrice,
        uint256 _minPercentageToAsk
    )
        external
        whenNotPaused
        isSupportedCurrency(_currency)
        isValidMinPercentageToAsk(_minPercentageToAsk)
        nonReentrant
    {
        _addDutchAuction(
            _collection,
            _tokenId,
            _currency,
            block.timestamp.toUint96(),
            _duration,
            _dropInterval,
            _startPrice,
            _endPrice,
            _minPercentageToAsk
        );
    }

    /// @notice Schedules a Dutch Auction for an ERC721 token
    /// @dev Note:
    /// - Requires the auction house to hold the ERC721 token in escrow
    /// - Drops in price every `dutchAuctionDropInterval` seconds in equal
    ///   amounts
    /// @param _collection address of ERC721 token
    /// @param _tokenId token id of ERC721 token
    /// @param _currency address of currency to sell ERC721 token for
    /// @param _startTime time to start the auction
    /// @param _duration number of seconds for Dutch Auction to run
    /// @param _dropInterval number of seconds between each drop in price
    /// @param _startPrice starting sell price
    /// @param _endPrice ending sell price
    /// @param _minPercentageToAsk minimum percentage of the gross amount that goes to ask
    function scheduleDutchAuction(
        IERC721 _collection,
        uint256 _tokenId,
        IERC20 _currency,
        uint96 _startTime,
        uint96 _duration,
        uint256 _dropInterval,
        uint256 _startPrice,
        uint256 _endPrice,
        uint256 _minPercentageToAsk
    )
        external
        whenNotPaused
        isSupportedCurrency(_currency)
        isValidStartTime(_startTime)
        isValidMinPercentageToAsk(_minPercentageToAsk)
        nonReentrant
    {
        _addDutchAuction(
            _collection,
            _tokenId,
            _currency,
            _startTime,
            _duration,
            _dropInterval,
            _startPrice,
            _endPrice,
            _minPercentageToAsk
        );
    }

    function _addDutchAuction(
        IERC721 _collection,
        uint256 _tokenId,
        IERC20 _currency,
        uint96 _startTime,
        uint96 _duration,
        uint256 _dropInterval,
        uint256 _startPrice,
        uint256 _endPrice,
        uint256 _minPercentageToAsk
    ) internal {
        if (_duration == 0 || _duration < _dropInterval) {
            revert JoepegAuctionHouse__InvalidDuration();
        }
        if (_dropInterval == 0) {
            revert JoepegAuctionHouse__InvalidDropInterval();
        }
        address collectionAddress = address(_collection);
        if (dutchAuctions[collectionAddress][_tokenId].creator != address(0)) {
            revert JoepegAuctionHouse__AuctionAlreadyExists();
        }
        if (_startPrice <= _endPrice || _endPrice == 0) {
            revert JoepegAuctionHouse__DutchAuctionInvalidStartEndPrice();
        }

        DutchAuction memory auction = DutchAuction({
            creator: msg.sender,
            nonce: userLatestAuctionNonce[msg.sender],
            currency: address(_currency),
            startPrice: _startPrice,
            endPrice: _endPrice,
            startTime: _startTime,
            endTime: _startTime + _duration,
            dropInterval: _dropInterval,
            minPercentageToAsk: _minPercentageToAsk
        });
        dutchAuctions[collectionAddress][_tokenId] = auction;
        userLatestAuctionNonce[msg.sender] += 1;

        _collection.safeTransferFrom(msg.sender, address(this), _tokenId);

        emit DutchAuctionStart(
            auction.creator,
            auction.currency,
            collectionAddress,
            _tokenId,
            auction.nonce,
            auction.startPrice,
            auction.endPrice,
            auction.startTime,
            auction.endTime,
            auction.dropInterval,
            auction.minPercentageToAsk
        );
    }

    /// @notice Settles a Dutch Auction
    /// @param _collection address of ERC721 token
    /// @param _tokenId token id of ERC721 token
    function settleDutchAuction(IERC721 _collection, uint256 _tokenId)
        external
        whenNotPaused
        nonReentrant
    {
        DutchAuction memory auction = dutchAuctions[address(_collection)][
            _tokenId
        ];
        _settleDutchAuction(_collection, _tokenId, auction);
    }

    /// @notice Settles a Dutch Auction with AVAX and/or WAVAX
    /// @param _collection address of ERC721 token
    /// @param _tokenId token id of ERC721 token
    function settleDutchAuctionWithAVAXAndWAVAX(
        IERC721 _collection,
        uint256 _tokenId
    ) external payable whenNotPaused nonReentrant {
        DutchAuction memory auction = dutchAuctions[address(_collection)][
            _tokenId
        ];
        address currency = auction.currency;
        if (currency != WAVAX) {
            revert JoepegAuctionHouse__CurrencyMismatch();
        }

        _settleDutchAuction(_collection, _tokenId, auction);
    }

    /// @notice Calculates current Dutch Auction sale price for an ERC721 token.
    /// Returns 0 if the auction hasn't started yet.
    /// @param _collection address of ERC721 token
    /// @param _tokenId token id of ERC721 token
    /// @return current Dutch Auction sale price for specified ERC721 token
    function getDutchAuctionSalePrice(address _collection, uint256 _tokenId)
        public
        view
        returns (uint256)
    {
        DutchAuction memory auction = dutchAuctions[_collection][_tokenId];
        if (block.timestamp < auction.startTime) {
            return 0;
        }
        if (block.timestamp >= auction.endTime) {
            return auction.endPrice;
        }
        uint256 timeElapsed = block.timestamp - auction.startTime;
        uint256 elapsedSteps = timeElapsed / auction.dropInterval;
        uint256 totalPossibleSteps = (auction.endTime - auction.startTime) /
            auction.dropInterval;

        uint256 priceDifference = auction.startPrice - auction.endPrice;

        return
            auction.startPrice -
            (elapsedSteps * priceDifference) /
            totalPossibleSteps;
    }

    /// @notice Cancels a running Dutch Auction
    /// @param _collection address of ERC721 token
    /// @param _tokenId token id of ERC721 token
    function cancelDutchAuction(IERC721 _collection, uint256 _tokenId)
        external
        whenNotPaused
        nonReentrant
    {
        address collectionAddress = address(_collection);
        DutchAuction memory auction = dutchAuctions[collectionAddress][
            _tokenId
        ];
        if (msg.sender != auction.creator) {
            revert JoepegAuctionHouse__OnlyAuctionCreatorCanCancel();
        }

        delete dutchAuctions[collectionAddress][_tokenId];

        _collection.safeTransferFrom(address(this), auction.creator, _tokenId);

        emit DutchAuctionCancel(
            msg.sender,
            auction.creator,
            collectionAddress,
            _tokenId,
            auction.nonce
        );
    }

    /// @notice Only owner function to cancel a Dutch Auction in case of emergencies
    /// @param _collection address of ERC721 token
    /// @param _tokenId token id of ERC721 token
    function emergencyCancelDutchAuction(IERC721 _collection, uint256 _tokenId)
        external
        nonReentrant
        onlyOwner
    {
        address collectionAddress = address(_collection);
        DutchAuction memory auction = dutchAuctions[collectionAddress][
            _tokenId
        ];
        if (auction.creator == address(0)) {
            revert JoepegAuctionHouse__NoAuctionExists();
        }

        delete dutchAuctions[collectionAddress][_tokenId];

        _collection.safeTransferFrom(address(this), auction.creator, _tokenId);

        emit DutchAuctionCancel(
            msg.sender,
            auction.creator,
            collectionAddress,
            _tokenId,
            auction.nonce
        );
    }

    /// @notice Update `englishAuctionMinBidIncrementPct`
    /// @param _englishAuctionMinBidIncrementPct new minimum bid increment percetange for English auctions
    function updateEnglishAuctionMinBidIncrementPct(
        uint256 _englishAuctionMinBidIncrementPct
    ) external onlyOwner {
        _updateEnglishAuctionMinBidIncrementPct(
            _englishAuctionMinBidIncrementPct
        );
    }

    /// @notice Update `englishAuctionMinBidIncrementPct`
    /// @param _englishAuctionMinBidIncrementPct new minimum bid increment percetange for English auctions
    function _updateEnglishAuctionMinBidIncrementPct(
        uint256 _englishAuctionMinBidIncrementPct
    ) internal {
        if (
            _englishAuctionMinBidIncrementPct == 0 ||
            _englishAuctionMinBidIncrementPct > PERCENTAGE_PRECISION
        ) {
            revert JoepegAuctionHouse__EnglishAuctionInvalidMinBidIncrementPct();
        }

        uint256 oldEnglishAuctionMinBidIncrementPct = englishAuctionMinBidIncrementPct;
        englishAuctionMinBidIncrementPct = _englishAuctionMinBidIncrementPct;
        emit EnglishAuctionMinBidIncrementPctSet(
            oldEnglishAuctionMinBidIncrementPct,
            _englishAuctionMinBidIncrementPct
        );
    }

    /// @notice Update `englishAuctionRefreshTime`
    /// @param _englishAuctionRefreshTime new refresh time for English auctions
    function updateEnglishAuctionRefreshTime(uint96 _englishAuctionRefreshTime)
        external
        onlyOwner
    {
        _updateEnglishAuctionRefreshTime(_englishAuctionRefreshTime);
    }

    /// @notice Update `englishAuctionRefreshTime`
    /// @param _englishAuctionRefreshTime new refresh time for English auctions
    function _updateEnglishAuctionRefreshTime(uint96 _englishAuctionRefreshTime)
        internal
    {
        if (_englishAuctionRefreshTime == 0) {
            revert JoepegAuctionHouse__EnglishAuctionInvalidRefreshTime();
        }
        uint96 oldEnglishAuctionRefreshTime = englishAuctionRefreshTime;
        englishAuctionRefreshTime = _englishAuctionRefreshTime;
        emit EnglishAuctionRefreshTimeSet(
            oldEnglishAuctionRefreshTime,
            englishAuctionRefreshTime
        );
    }

    /// @notice Update currency manager
    /// @param _currencyManager new currency manager address
    function updateCurrencyManager(address _currencyManager)
        external
        onlyOwner
    {
        _updateCurrencyManager(_currencyManager);
    }

    /// @notice Update currency manager
    /// @param _currencyManager new currency manager address
    function _updateCurrencyManager(address _currencyManager) internal {
        if (_currencyManager == address(0)) {
            revert JoepegAuctionHouse__ExpectedNonNullAddress();
        }
        address oldCurrencyManagerAddress = address(currencyManager);
        currencyManager = ICurrencyManager(_currencyManager);
        emit CurrencyManagerSet(oldCurrencyManagerAddress, _currencyManager);
    }

    /// @notice Update protocol fee manager
    /// @param _protocolFeeManager new protocol fee manager address
    function updateProtocolFeeManager(address _protocolFeeManager)
        external
        onlyOwner
    {
        _updateProtocolFeeManager(_protocolFeeManager);
    }

    /// @notice Update protocol fee manager
    /// @param _protocolFeeManager new protocol fee manager address
    function _updateProtocolFeeManager(address _protocolFeeManager) internal {
        if (_protocolFeeManager == address(0)) {
            revert JoepegAuctionHouse__ExpectedNonNullAddress();
        }
        address oldProtocolFeeManagerAddress = address(protocolFeeManager);
        protocolFeeManager = IProtocolFeeManager(_protocolFeeManager);
        emit ProtocolFeeManagerSet(
            oldProtocolFeeManagerAddress,
            _protocolFeeManager
        );
    }

    /// @notice Update protocol fee recipient
    /// @param _protocolFeeRecipient new recipient for protocol fees
    function updateProtocolFeeRecipient(address _protocolFeeRecipient)
        external
        onlyOwner
    {
        _updateProtocolFeeRecipient(_protocolFeeRecipient);
    }

    /// @notice Update protocol fee recipient
    /// @param _protocolFeeRecipient new recipient for protocol fees
    function _updateProtocolFeeRecipient(address _protocolFeeRecipient)
        internal
    {
        if (_protocolFeeRecipient == address(0)) {
            revert JoepegAuctionHouse__ExpectedNonNullAddress();
        }
        address oldProtocolFeeRecipient = protocolFeeRecipient;
        protocolFeeRecipient = _protocolFeeRecipient;
        emit ProtocolFeeRecipientSet(
            oldProtocolFeeRecipient,
            _protocolFeeRecipient
        );
    }

    /// @notice Update royalty fee manager
    /// @param _royaltyFeeManager new fee manager address
    function updateRoyaltyFeeManager(address _royaltyFeeManager)
        external
        onlyOwner
    {
        _updateRoyaltyFeeManager(_royaltyFeeManager);
    }

    /// @notice Update royalty fee manager
    /// @param _royaltyFeeManager new fee manager address
    function _updateRoyaltyFeeManager(address _royaltyFeeManager) internal {
        if (_royaltyFeeManager == address(0)) {
            revert JoepegAuctionHouse__ExpectedNonNullAddress();
        }
        address oldRoyaltyFeeManagerAddress = address(royaltyFeeManager);
        royaltyFeeManager = IRoyaltyFeeManager(_royaltyFeeManager);
        emit RoyaltyFeeManagerSet(
            oldRoyaltyFeeManagerAddress,
            _royaltyFeeManager
        );
    }

    /// @dev Returns true if this contract implements the interface defined by
    /// `interfaceId`. See the corresponding
    /// https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
    /// to learn more about how these ids are created.
    /// This function call must use less than 30 000 gas.
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return
            interfaceId == type(IERC721Receiver).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /// @notice Place bid on a running English Auction
    /// @dev Note:
    /// - Requires holding the bid in escrow until either a higher bid is placed
    ///   or the auction is settled
    /// - If a bid already exists, only bids at least `englishAuctionMinBidIncrementPct`
    ///   percent higher can be placed
    /// @param _collection address of ERC721 token
    /// @param _tokenId token id of ERC721 token
    /// @param _bidAmount amount of currency to bid
    function _placeEnglishAuctionBid(
        IERC721 _collection,
        uint256 _tokenId,
        uint256 _bidAmount,
        EnglishAuction memory auction
    ) internal {
        if (auction.creator == address(0)) {
            revert JoepegAuctionHouse__NoAuctionExists();
        }
        if (_bidAmount == 0) {
            revert JoepegAuctionHouse__EnglishAuctionInsufficientBidAmount();
        }
        if (msg.sender == auction.creator) {
            revert JoepegAuctionHouse__EnglishAuctionCreatorCannotPlaceBid();
        }
        if (block.timestamp < auction.startTime) {
            revert JoepegAuctionHouse__EnglishAuctionCannotBidOnUnstartedAuction();
        }
        if (block.timestamp >= auction.endTime) {
            revert JoepegAuctionHouse__EnglishAuctionCannotBidOnEndedAuction();
        }

        uint96 endTimeExtension;
        if (auction.endTime - block.timestamp <= englishAuctionRefreshTime) {
            endTimeExtension = englishAuctionRefreshTime;
            auction.endTime += endTimeExtension;
        }

        if (auction.lastBidPrice == 0) {
            if (_bidAmount < auction.startPrice) {
                revert JoepegAuctionHouse__EnglishAuctionInsufficientBidAmount();
            }
            auction.lastBidder = msg.sender;
            auction.lastBidPrice = _bidAmount;
        } else {
            if (msg.sender == auction.lastBidder) {
                // If bidder is same as last bidder, ensure their bid is at least
                // `englishAuctionMinBidIncrementPct` percent of their previous bid
                if (
                    _bidAmount * PERCENTAGE_PRECISION <
                    auction.lastBidPrice * englishAuctionMinBidIncrementPct
                ) {
                    revert JoepegAuctionHouse__EnglishAuctionInsufficientBidAmount();
                }
                auction.lastBidPrice += _bidAmount;
            } else {
                // Ensure bid is at least `englishAuctionMinBidIncrementPct` percent greater
                // than last bid
                if (
                    _bidAmount * PERCENTAGE_PRECISION <
                    auction.lastBidPrice *
                        (PERCENTAGE_PRECISION +
                            englishAuctionMinBidIncrementPct)
                ) {
                    revert JoepegAuctionHouse__EnglishAuctionInsufficientBidAmount();
                }

                address previousBidder = auction.lastBidder;
                uint256 previousBidPrice = auction.lastBidPrice;

                auction.lastBidder = msg.sender;
                auction.lastBidPrice = _bidAmount;

                // Transfer previous bid back to bidder
                IERC20(auction.currency).safeTransfer(
                    previousBidder,
                    previousBidPrice
                );
            }
        }

        address collectionAddress = address(_collection);
        englishAuctions[collectionAddress][_tokenId] = auction;

        emit EnglishAuctionPlaceBid(
            auction.creator,
            auction.lastBidder,
            auction.currency,
            collectionAddress,
            _tokenId,
            auction.nonce,
            auction.lastBidPrice,
            endTimeExtension
        );
    }

    /// @notice Settles a Dutch Auction
    /// @dev Note:
    /// - Transfers funds and fees appropriately to seller, royalty receiver, and protocol fee recipient
    /// - Transfers ERC721 token to buyer
    /// @param _collection address of ERC721 token
    /// @param _tokenId token id of ERC721 token
    function _settleDutchAuction(
        IERC721 _collection,
        uint256 _tokenId,
        DutchAuction memory _auction
    ) internal {
        if (_auction.creator == address(0)) {
            revert JoepegAuctionHouse__NoAuctionExists();
        }
        if (msg.sender == _auction.creator) {
            revert JoepegAuctionHouse__DutchAuctionCreatorCannotSettle();
        }
        if (block.timestamp < _auction.startTime) {
            revert JoepegAuctionHouse__DutchAuctionCannotSettleUnstartedAuction();
        }

        // Get auction sale price
        address collectionAddress = address(_collection);
        uint256 salePrice = getDutchAuctionSalePrice(
            collectionAddress,
            _tokenId
        );

        delete dutchAuctions[collectionAddress][_tokenId];

        if (_auction.currency == WAVAX) {
            // Transfer WAVAX if needed
            if (salePrice > msg.value) {
                IERC20(WAVAX).safeTransferFrom(
                    msg.sender,
                    address(this),
                    salePrice - msg.value
                );
            }

            // Wrap AVAX if needed
            if (msg.value > 0) {
                IWAVAX(WAVAX).deposit{value: msg.value}();
            }

            // Refund excess AVAX if needed
            if (salePrice < msg.value) {
                IERC20(WAVAX).safeTransfer(msg.sender, msg.value - salePrice);
            }

            _transferFeesAndFunds(
                collectionAddress,
                _tokenId,
                IERC20(WAVAX),
                address(this),
                _auction.creator,
                salePrice,
                _auction.minPercentageToAsk
            );
        } else {
            _transferFeesAndFunds(
                collectionAddress,
                _tokenId,
                IERC20(_auction.currency),
                msg.sender,
                _auction.creator,
                salePrice,
                _auction.minPercentageToAsk
            );
        }

        _collection.safeTransferFrom(address(this), msg.sender, _tokenId);

        emit DutchAuctionSettle(
            _auction.creator,
            msg.sender,
            _auction.currency,
            collectionAddress,
            _tokenId,
            _auction.nonce,
            salePrice
        );
    }

    /// @notice Transfer fees and funds to royalty recipient, protocol, and seller
    /// @param _collection address of ERC721 token
    /// @param _tokenId token id of ERC721 token
    /// @param _currency address of token being used for the purchase (e.g. USDC)
    /// @param _from sender of the funds
    /// @param _to seller's recipient
    /// @param _amount amount being transferred (in currency)
    /// @param _minPercentageToAsk minimum percentage of the gross amount that goes to ask
    function _transferFeesAndFunds(
        address _collection,
        uint256 _tokenId,
        IERC20 _currency,
        address _from,
        address _to,
        uint256 _amount,
        uint256 _minPercentageToAsk
    ) internal {
        // Initialize the final amount that is transferred to seller
        uint256 finalSellerAmount = _amount;

        // 1. Protocol fee
        {
            uint256 protocolFeeAmount = _calculateProtocolFee(
                _collection,
                _amount
            );
            address _protocolFeeRecipient = protocolFeeRecipient;

            // Check if the protocol fee is different than 0 for this strategy
            if (
                (_protocolFeeRecipient != address(0)) &&
                (protocolFeeAmount != 0)
            ) {
                _currency.safeTransferFrom(
                    _from,
                    _protocolFeeRecipient,
                    protocolFeeAmount
                );
                finalSellerAmount -= protocolFeeAmount;
            }
        }

        // 2. Royalty fees
        {
            RoyaltyFeeTypes.FeeAmountPart[]
                memory feeAmountParts = royaltyFeeManager
                    .calculateRoyaltyFeeAmountParts(
                        _collection,
                        _tokenId,
                        _amount
                    );

            for (uint256 i; i < feeAmountParts.length; i++) {
                RoyaltyFeeTypes.FeeAmountPart
                    memory feeAmountPart = feeAmountParts[i];
                _currency.safeTransferFrom(
                    _from,
                    feeAmountPart.receiver,
                    feeAmountPart.amount
                );
                finalSellerAmount -= feeAmountPart.amount;

                emit RoyaltyPayment(
                    _collection,
                    _tokenId,
                    feeAmountPart.receiver,
                    address(_currency),
                    feeAmountPart.amount
                );
            }
        }

        // Ensure seller gets minimum expected fees
        if (
            finalSellerAmount * PERCENTAGE_PRECISION <
            _minPercentageToAsk * _amount
        ) {
            revert JoepegAuctionHouse__FeesHigherThanExpected();
        }

        // 3. Transfer final amount (post-fees) to seller
        {
            _currency.safeTransferFrom(_from, _to, finalSellerAmount);
        }
    }

    /// @notice Calculate protocol fee for a given collection
    /// @param _collection address of collection
    /// @param _amount amount to transfer
    function _calculateProtocolFee(address _collection, uint256 _amount)
        internal
        view
        returns (uint256)
    {
        uint256 protocolFee = protocolFeeManager.protocolFeeForCollection(
            _collection
        );
        return (protocolFee * _amount) / PERCENTAGE_PRECISION;
    }
}