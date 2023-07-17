// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

import "./ERC721Base.sol";
import "fount-contracts/utils/Withdraw.sol";
import "./interfaces/IMorningsPayments.sol";

/**
 * @author Fount Gallery
 * @title  Mornings Open Editions by Gutty Kreum
 * @notice Mornings is a collection of digital memories exploring morning ambience by pixel artist, Gutty Kreum.
 *         A limited release in collaboration with Fount Gallery, Mornings drops on June 22, 2023.
 *
 * Features:
 *   - Mixed 1/1 and limited edition NFTs
 *   - Auctions with "Buy it now" for 1/1 NFTs
 *   - Flexible collecting conditions with EIP-712 signatures or on-chain Fount Card checks
 *   - Swappable metadata contract
 *   - On-chain royalties standard (EIP-2981)
 *   - Support for OpenSea's Operator Filterer to allow royalties
 */
contract MorningsLimitedEditions is ERC721Base, Withdraw {
    /* ------------------------------------------------------------------------
       S T O R A G E
    ------------------------------------------------------------------------ */

    /// @dev Cap for edition sizes. Also used to generate token ids for editions.
    uint256 internal constant MAX_EDITION_SIZE = 1000;

    /// @dev Stores information about a sale for a given token
    struct TokenData {
        uint128 price;
        uint16 editionSize;
        uint16 collected;
        bool fountExclusive;
        bool requiresSig;
        bool freeToCollect;
    }

    /// @dev Mapping of base token id to token data
    mapping(uint256 => TokenData) internal _baseIdToTokenData;

    /// @dev General auction config
    uint256 public auctionTimeBuffer = 5 minutes;
    uint256 public auctionIncPercentage = 10;

    /// @dev Auction config for a specific token auction
    struct AuctionData {
        uint32 duration;
        uint32 startTime;
        uint32 firstBidTime;
        address highestBidder;
        uint128 highestBid;
        uint128 reservePrice;
    }

    /// @dev Mapping of base token id to auction data
    mapping(uint256 => AuctionData) public auctions;

    /// @dev Counter to keep track of active auctions. Prevents withdrawals unless zero.
    uint256 public activeAuctions;

    /// @notice Address where proceeds should be sent
    address public payments;

    /// @dev Toggle to allow collecting
    bool internal _isSaleLive;

    /* ------------------------------------------------------------------------
       M O D I F I E R S
    ------------------------------------------------------------------------ */

    /**
     * @dev Makes sure that the sale is live before proceeding
     */
    modifier onlyWhenSaleIsLive() {
        if (!_isSaleLive) revert SaleNotLive();
        _;
    }

    /* ------------------------------------------------------------------------
       E R R O R S
    ------------------------------------------------------------------------ */

    /** TOKEN DATA ---------------------------------------------------------- */
    error TokenDataDoesNotExist();
    error TokenDataAlreadyExists();
    error InvalidBaseId();
    error CannotSetEditionSizeToZero();

    /** SALE CONDITIONS ---------------------------------------------------- */
    error SaleNotLive();
    error RequiresFountCard();
    error RequiresSignature();
    error InvalidSignature();

    /** PURCHASING --------------------------------------------------------- */
    error NotForSale();
    error IncorrectPaymentAmount();

    /** ONE OF ONES -------------------------------------------------------- */
    error NotOneOfOne();

    /** AUCTIONS ----------------------------------------------------------- */
    error AuctionDoesNotExist();
    error AuctionNotStarted();
    error AuctionAlreadyExists();
    error AuctionAlreadyStarted();
    error AuctionReserveNotMet(uint256 reserve, uint256 sent);
    error AuctionMinimumBidNotMet(uint256 minBid, uint256 sent);
    error AuctionNotEnded();
    error AuctionEnded();
    error AuctionAlreadySettled();
    error AlreadySold();
    error CannotSetAuctionDurationToZero();
    error CannotSetAuctionStartTimeToZero();
    error CannotSetAuctionReservePriceToZero();
    error CannotWithdrawWithActiveAuctions();

    /** EDITIONS ----------------------------------------------------------- */
    error NotEdition();
    error EditionSoldOut();
    error EditionSizeLessThanCurrentlySold();
    error EditionSizeExceedsMaxValue();

    /** PAYMENTS ----------------------------------------------------------- */
    error CannotSetPaymentAddressToZero();

    /* ------------------------------------------------------------------------
       E V E N T S
    ------------------------------------------------------------------------ */

    event TokenDataAdded(uint256 indexed id, TokenData tokenData);
    event TokenDataSalePriceUpdated(uint256 indexed id, TokenData tokenData);
    event TokenDataSaleConditionsUpdated(uint256 indexed id, TokenData tokenData);

    event AuctionCreated(uint256 indexed id, AuctionData auction);
    event AuctionBid(uint256 indexed id, AuctionData auction);
    event AuctionSettled(uint256 indexed id, AuctionData auction);
    event AuctionSoldEarly(uint256 indexed id, AuctionData auction);
    event AuctionCancelled(uint256 indexed id);

    event AuctionDurationUpdated(uint256 indexed id, uint256 indexed duration);
    event AuctionStartTimeUpdated(uint256 indexed id, uint256 indexed startTime);
    event AuctionReservePriceUpdated(uint256 indexed id, uint256 indexed reservePrice);

    event CollectedOneOfOne(uint256 indexed id);
    event CollectedEdition(
        uint256 indexed baseId,
        uint256 indexed editionNumber,
        uint256 indexed tokenId
    );

    /* ------------------------------------------------------------------------
       I N I T
    ------------------------------------------------------------------------ */

    /**
     * @param owner_ The owner of the contract
     * @param admin_ The admin of the contract
     * @param payments_ The address where payments should be sent
     * @param royaltiesAmount_ The royalty percentage with two decimals (10,000 = 100%)
     * @param metadata_ The initial metadata contract address
     * @param fountCard_ The address of the Fount Gallery Patron Card
     */
    constructor(
        address owner_,
        address admin_,
        address payments_,
        uint256 royaltiesAmount_,
        address metadata_,
        address fountCard_
    ) ERC721Base(owner_, admin_, payments_, royaltiesAmount_, metadata_, fountCard_) {
        payments = payments_;
    }

    /* ------------------------------------------------------------------------
       O N E   O F   O N E S
    ------------------------------------------------------------------------ */

    /** AUCTION BIDS ------------------------------------------------------- */

    /**
     * @notice Places a bid for a token
     * @dev Calls internal `_placeBid` function for logic.
     *
     * Reverts if:
     *   - the token requires an off-chain signature
     *   - see `_placeBid` for other conditions
     *
     * @param baseId The base id of the token to register a bid for
     */
    function placeBid(uint256 baseId) external payable onlyWhenSaleIsLive {
        TokenData memory tokenData = _baseIdToTokenData[baseId];
        if (tokenData.requiresSig) revert RequiresSignature();
        _placeBid(baseId, tokenData);
    }

    /**
     * @notice Places a bid for a token with an off-chain signature
     * @dev Calls internal `_placeBid` function for logic.
     *
     * Reverts if:
     *   - the token requires an off-chain signature and the signature is invalid
     *   - see `_placeBid` for other conditions
     *
     * @param baseId The base id of the token to register a bid for
     * @param signature The off-chain signature that permits a mint
     */
    function placeBid(
        uint256 baseId,
        bytes calldata signature
    ) external payable onlyWhenSaleIsLive {
        TokenData memory tokenData = _baseIdToTokenData[baseId];
        if (tokenData.requiresSig && !_verifyMintSignature(baseId, msg.sender, signature)) {
            revert InvalidSignature();
        }
        _placeBid(baseId, tokenData);
    }

    /**
     * @notice Internal function to place a bid for a token
     * @dev Takes the amount of ETH sent as the bid. If the bid is the new highest bid,
     * then the previous highest bidder is refunded (in WETH if the refund fails with ETH).
     * If a bid is placed within the auction time buffer then the buffer is added to the
     * time remaining on the auction e.g. extends by 5 minutes.
     *
     * Reverts if:
     *   - the token requires a Fount Card, but msg.sender does not hold one
     *   - the auction has not yet started
     *   - the auction has ended
     *   - the auction reserve bid has not been met if it's the first bid
     *   - the bid does not meet the minimum (increment percentage of current highest bid)
     *
     * @param baseId The base id of the token to register a bid for
     * @param tokenData Information about the token
     */
    function _placeBid(uint256 baseId, TokenData memory tokenData) internal {
        // Check msg.sender qualifies to bid
        if (tokenData.fountExclusive && !_isFountCardHolder(msg.sender)) revert RequiresFountCard();

        // Load the auction
        AuctionData memory auction = auctions[baseId];

        // Check auction is ready to accept bids
        if (auction.startTime == 0 || auction.startTime > block.timestamp) {
            revert AuctionNotStarted();
        }

        // If first bid, start the auction
        if (auction.firstBidTime == 0) {
            // Check the first bid meets the reserve
            if (auction.reservePrice > msg.value) {
                revert AuctionReserveNotMet(auction.reservePrice, msg.value);
            }

            // Save the bid time
            auction.firstBidTime = uint32(block.timestamp);
        } else {
            // Check it hasn't ended
            if (block.timestamp > (auction.firstBidTime + auction.duration)) revert AuctionEnded();

            // Check the value sent meets the minimum price increase
            uint256 highestBid = auction.highestBid;
            uint256 minBid;
            unchecked {
                minBid = highestBid + ((highestBid * auctionIncPercentage) / 100);
            }
            if (minBid > msg.value) revert AuctionMinimumBidNotMet(minBid, msg.value);

            // Refund the previous highest bid
            _transferETHWithFallback(auction.highestBidder, highestBid);
        }

        // Save the new highest bid and bidder
        auction.highestBid = uint96(msg.value);
        auction.highestBidder = msg.sender;

        // Calculate the time remaining
        uint256 timeRemaining;
        unchecked {
            timeRemaining = auction.firstBidTime + auction.duration - block.timestamp;
        }

        // If bid is placed within the time buffer of the auction ending, increase the duration
        if (timeRemaining < auctionTimeBuffer) {
            unchecked {
                auction.duration += uint32(auctionTimeBuffer - timeRemaining);
            }
        }

        // Save the new auction data
        auctions[baseId] = auction;

        // Emit event
        emit AuctionBid(baseId, auction);
    }

    /** AUCTION SETTLEMENT ------------------------------------------------- */

    /**
     * @notice Allows the winner to settle the auction which mints of their new NFT
     * @dev Mints the NFT to the highest bidder (winner) only once the auction is over.
     * Can be called by anyone so Fount Gallery can pay the gas if needed.
     *
     * Reverts if:
     *   - the auction hasn't started yet
     *   - the auction is not over
     *   - the token has already been sold via `collectOneOfOne`
     *
     * @param baseId The base id of token to settle the auction for
     */
    function settleAuction(uint256 baseId) external {
        AuctionData memory auction = auctions[baseId];

        // Check auction has started
        if (auction.firstBidTime == 0) revert AuctionNotStarted();

        // Check auction has ended
        if (auction.firstBidTime + auction.duration > block.timestamp) revert AuctionNotEnded();

        // Transfer the NFT to the highest bidder
        if (_ownerOf[baseId] != artist) revert AlreadySold();
        _transferFromArtist(auction.highestBidder, baseId);
        emit CollectedOneOfOne(baseId);

        // Decrease the active auctions count
        unchecked {
            --activeAuctions;
        }

        // Emit event
        emit AuctionSettled(baseId, auction);
    }

    /* ------------------------------------------------------------------------
       L I M I T E D   E D I T I O N S
    ------------------------------------------------------------------------ */

    /**
     * @notice Mints the next edition of a limited edition NFT
     * @dev Calls internal `_collectEdition` for logic.
     *
     * Reverts if:
     *  - the edition requires an off-chain signature
     *  - see `_collectEdition` for other conditions
     *
     * @param baseId The base NFT id of the edition
     * @param to The address to mint the token to
     */
    function collectEdition(uint256 baseId, address to) external payable onlyWhenSaleIsLive {
        TokenData memory tokenData = _baseIdToTokenData[baseId];
        if (tokenData.requiresSig) revert RequiresSignature();
        _collectEdition(baseId, to, tokenData);
    }

    /**
     * @notice Mints the next edition of a limited edition NFT with an off-chain signature
     * @dev Calls internal `_collectEdition` for logic.
     *
     * Reverts if:
     *  - the edition requires an off-chain signature and the signature is invalid
     *  - see `_collectEdition` for other conditions
     *
     * @param baseId The base NFT id of the edition
     * @param to The address to mint the token to
     * @param signature The off-chain signature which permits a mint
     */
    function collectEdition(
        uint256 baseId,
        address to,
        bytes calldata signature
    ) external payable onlyWhenSaleIsLive {
        TokenData memory tokenData = _baseIdToTokenData[baseId];
        if (tokenData.requiresSig && !_verifyMintSignature(baseId, to, signature)) {
            revert InvalidSignature();
        }
        _collectEdition(baseId, to, tokenData);
    }

    /**
     * @notice Internal function to collect the next edition with some conditions
     * @dev Allows collecting to a different address from msg.sender.
     *
     * Reverts if:
     *  - the token is not an edition
     *  - the edition is sold out
     *  - msg.value does not equal the required amount
     *  - the edition requires a Fount Card, but `to` does not hold one
     *
     * @param baseId The base NFT id of the edition
     * @param to The address to collect the token to
     * @param tokenData Information about the token
     */
    function _collectEdition(uint256 baseId, address to, TokenData memory tokenData) internal {
        // Check to see if the next edition is collectable and the price is correct
        if (tokenData.editionSize < 2) revert NotEdition();
        if (tokenData.collected + 1 > tokenData.editionSize) revert EditionSoldOut();
        if (!tokenData.freeToCollect && tokenData.price == 0) revert NotForSale();
        if (tokenData.price != msg.value) revert IncorrectPaymentAmount();

        // Check if it's a Fount Gallery exclusive
        if (tokenData.fountExclusive && !_isFountCardHolder(to)) revert RequiresFountCard();

        // Get the next edition number and token id
        uint256 editionNumber = tokenData.collected + 1;
        uint256 tokenId = _getEditionTokenId(baseId, editionNumber);

        // Add the new mint to the token data
        unchecked {
            ++tokenData.collected;
        }
        _baseIdToTokenData[baseId] = tokenData;

        // Transfer the NFT from Gutty Kreum to the `to` address
        _transferFromArtist(to, tokenId);
        emit CollectedEdition(baseId, editionNumber, tokenId);
    }

    /** UTILS -------------------------------------------------------------- */

    /**
     * @notice Internal function to get the token id for an edition
     * @param baseId The base NFT id of the edition
     * @param editionNumber The edition number to make the token id for
     * @return tokenId The token id for the edition
     */
    function _getEditionTokenId(
        uint256 baseId,
        uint256 editionNumber
    ) internal pure returns (uint256) {
        return baseId * MAX_EDITION_SIZE + editionNumber;
    }

    /**
     * @notice Get the token id for a specific edition number
     * @param baseId The base NFT id of the edition
     * @param editionNumber The edition number to make the token id for
     * @return tokenId The token id for the edition
     */
    function getEditionTokenId(
        uint256 baseId,
        uint256 editionNumber
    ) external pure returns (uint256) {
        return _getEditionTokenId(baseId, editionNumber);
    }

    /**
     * @notice Get the edition number from a token id
     * @dev Returns `0` if it's not an edition
     * @param tokenId The token id for the edition
     * @return editionNumber The edition number e.g. 2 of 10
     */
    function getEditionNumberFromTokenId(uint256 tokenId) external pure returns (uint256) {
        if (tokenId >= MAX_EDITION_SIZE) return 0;
        return tokenId % MAX_EDITION_SIZE;
    }

    /**
     * @notice Get the base NFT id from a token id
     * @dev Returns the token id argument if it's not an edition
     * @param tokenId The token id for the edition
     * @return baseId The base NFT id e.g. 2 from "2004"
     */
    function getEditionBaseIdFromTokenId(uint256 tokenId) external pure returns (uint256) {
        if (tokenId >= MAX_EDITION_SIZE) return tokenId;
        return tokenId / MAX_EDITION_SIZE;
    }

    /* ------------------------------------------------------------------------
       A D M I N
    ------------------------------------------------------------------------ */

    /** ADD TOKEN DATA ----------------------------------------------------- */

    /**
     * @notice Admin function to make a token available for sale
     * @dev As soon as the token data is registered, the NFT will be available to collect provided
     * a price has been set. This prevents auctions without a "buy it now" price from being
     * purchased for free unintentionally.
     *
     * If a free mint is intended, set `price` to zero and `freeMint` to true.
     *
     * Reverts if:
     *  - the edition size exeeds the max allowed value (`MAX_EDITION_SIZE`)
     *  - the token data already exists (to update token data, use the other admin
     *    functions to set price and sale conditions)
     *
     * @param baseId The base NFT id
     * @param price The sale price (buy it now for auctions)
     * @param editionSize The size of the edition. Set to 1 for one of one NFTs.
     * @param fountExclusive If the sale requires a Fount Gallery Patron card
     * @param requiresSig If the sale requires an off-chain signature
     * @param freeMint If the sale requires an off-chain signature
     */
    function addTokenForSale(
        uint256 baseId,
        uint128 price,
        uint16 editionSize,
        bool fountExclusive,
        bool requiresSig,
        bool freeMint
    ) external onlyOwnerOrAdmin {
        // Check the baseId is valid
        if (baseId > type(uint256).max / MAX_EDITION_SIZE) revert InvalidBaseId();

        // Check a valid edition size has been used
        if (editionSize == 0) revert CannotSetEditionSizeToZero();

        // Check the edition size does not exceed the max
        if (editionSize > MAX_EDITION_SIZE - 1) revert EditionSizeExceedsMaxValue();

        TokenData memory tokenData = _baseIdToTokenData[baseId];

        // Check the token data is empty before adding
        if (tokenData.editionSize != 0) revert TokenDataAlreadyExists();

        // Set the new token data
        tokenData.price = price;
        tokenData.editionSize = editionSize;
        tokenData.fountExclusive = fountExclusive;
        tokenData.requiresSig = requiresSig;
        tokenData.freeToCollect = freeMint;
        _baseIdToTokenData[baseId] = tokenData;
        emit TokenDataAdded(baseId, tokenData);

        // Mint to Gutty Kreum
        if (editionSize == 1) {
            _mint(artist, baseId);
        } else {
            for (uint256 i = 0; i < editionSize; i++) {
                _mint(artist, _getEditionTokenId(baseId, i + 1));
            }
        }
    }

    /** SET SALE PRICE ----------------------------------------------------- */

    /**
     * @notice Admin function to update the sale price for a token
     * @dev Reverts if the token data does not exist. Must be added with `addTokenForSale` first.
     * @param baseId The base NFT id
     * @param price The new sale price
     * @param freeMint If the NFT can be minted for free
     */
    function setTokenSalePrice(
        uint256 baseId,
        uint128 price,
        bool freeMint
    ) external onlyOwnerOrAdmin {
        TokenData memory tokenData = _baseIdToTokenData[baseId];

        // Check the token data already exists.
        // If not, it should be created with `addTokenForSale` first.
        if (tokenData.editionSize == 0) revert TokenDataDoesNotExist();

        // Set the new sale price
        tokenData.price = price;
        tokenData.freeToCollect = freeMint;
        _baseIdToTokenData[baseId] = tokenData;
        emit TokenDataSalePriceUpdated(baseId, tokenData);
    }

    /** SET SALE CONDITIONS ------------------------------------------------ */

    /**
     * @notice Admin function to update the sale conditions for a token
     * @dev Reverts if the token data does not exist. Must be added with `addTokenForSale` first.
     * @param baseId The base NFT id
     * @param fountExclusive If the sale requires a Fount Gallery Patron card
     * @param requiresSig If the sale requires an off-chain signature
     */
    function setTokenSaleConditions(
        uint256 baseId,
        bool fountExclusive,
        bool requiresSig
    ) external onlyOwnerOrAdmin {
        TokenData memory tokenData = _baseIdToTokenData[baseId];

        // Check the token data already exists.
        // If not, it should be created with `addTokenForSale` first.
        if (tokenData.editionSize == 0) revert TokenDataDoesNotExist();

        tokenData.fountExclusive = fountExclusive;
        tokenData.requiresSig = requiresSig;
        _baseIdToTokenData[baseId] = tokenData;
        emit TokenDataSaleConditionsUpdated(baseId, tokenData);
    }

    /** AUCTION CREATION --------------------------------------------------- */

    /**
     * @notice Admin function to create an auction for a 1/1
     * @dev Can only create auctions for 1/1 NFTs, not editions.
     *
     * Reverts if:
     *  - the token is not a 1/1
     *  - the auction already exists
     *
     * @param baseId The base NFT id
     */
    function createAuction(
        uint256 baseId,
        uint32 duration,
        uint32 startTime,
        uint128 reservePrice
    ) external onlyOwnerOrAdmin {
        if (duration == 0) revert CannotSetAuctionDurationToZero();
        if (startTime == 0) revert CannotSetAuctionStartTimeToZero();

        // Check if the token data exists and it's a 1/1
        TokenData memory tokenData = _baseIdToTokenData[baseId];
        if (tokenData.editionSize != 1) revert NotOneOfOne();

        // Load the auction data
        AuctionData memory auction = auctions[baseId];

        // Check there's no auction already
        if (auction.startTime > 0) revert AuctionAlreadyExists();

        // Create the auction data
        auction.duration = duration;
        auction.startTime = startTime;
        auction.reservePrice = reservePrice;
        auctions[baseId] = auction;

        // Increment active auctions counter
        unchecked {
            ++activeAuctions;
        }

        // Emit created event
        emit AuctionCreated(baseId, auction);
    }

    /** AUCTION CANCELLATION ----------------------------------------------- */

    /**
     * @notice Admin function to cancel an auction
     * @dev Calls internal `_cancelAuction` for logic.
     * @param baseId The base NFT id
     */
    function cancelAuction(uint256 baseId) external onlyOwnerOrAdmin {
        AuctionData memory auction = auctions[baseId];
        _cancelAuction(baseId, auction);
    }

    /**
     * @notice Internal function for cancelling an auction
     * @dev Cancels the auction by refunding the highest bid and deleting the data
     *
     * Reverts if:
     *  - the auctions has ended (in case it hasn't been settled yet)
     *
     * @param baseId The base NFT id
     * @param auction The auction data to determine conditions and refunds
     */
    function _cancelAuction(uint256 baseId, AuctionData memory auction) internal {
        if (auction.firstBidTime > 0) {
            // Prevent cancelling if the auction has ended in case it hasn't been settled yet
            if (block.timestamp > (auction.firstBidTime + auction.duration)) revert AuctionEnded();
            // Refund the highest bidder
            _transferETHWithFallback(auction.highestBidder, auction.highestBid);
        }

        // Delete the auction data and reduce the active auction count
        delete auctions[baseId];
        unchecked {
            --activeAuctions;
        }

        emit AuctionCancelled(baseId);
    }

    /** AUCTION DURATION --------------------------------------------------- */

    /**
     * @notice Admin function to set the duration of a specific auction
     * @dev Emits an `AuctionDurationUpdated` event if successful
     *
     * Reverts if:
     *  - `duration` is zero
     *  - the auction does not exist
     *  - the auction already has bids
     *
     * @param baseId The base NFT id
     * @param duration The new auction duration
     */
    function setAuctionDuration(uint256 baseId, uint32 duration) external onlyOwnerOrAdmin {
        if (duration == 0) revert CannotSetAuctionDurationToZero();

        AuctionData memory auction = auctions[baseId];
        if (auction.startTime == 0) revert AuctionDoesNotExist();
        if (auction.firstBidTime > 0) revert AuctionAlreadyStarted();

        auction.duration = duration;
        auctions[baseId] = auction;
        emit AuctionDurationUpdated(baseId, duration);
    }

    /** AUCTION START TIME ------------------------------------------------- */

    /**
     * @notice Admin function to set the start time of a specific auction
     * @dev Emits an `AuctionStartTimeUpdated` event if successful
     *
     * Reverts if:
     *  - `startTime` is zero
     *  - the auction does not exist
     *  - the auction already has bids
     *
     * @param baseId The base NFT id
     * @param startTime The new auction start time
     */
    function setAuctionStartTime(uint256 baseId, uint32 startTime) external onlyOwnerOrAdmin {
        if (startTime == 0) revert CannotSetAuctionStartTimeToZero();

        AuctionData memory auction = auctions[baseId];
        if (auction.startTime == 0) revert AuctionDoesNotExist();
        if (auction.firstBidTime > 0) revert AuctionAlreadyStarted();

        auction.startTime = startTime;
        auctions[baseId] = auction;
        emit AuctionStartTimeUpdated(baseId, startTime);
    }

    /** AUCTION RESERVE PRICE ---------------------------------------------- */

    /**
     * @notice Admin function to set the reserve price of a specific auction
     * @dev Emits an `AuctionReservePriceUpdated` event if successful
     *
     * Reverts if:
     *  - `reservePrice` is zero
     *  - the auction does not exist
     *  - the auction already has bids
     *
     * @param baseId The base NFT id
     * @param reservePrice The new auction start time
     */
    function setAuctionReservePrice(
        uint256 baseId,
        uint128 reservePrice
    ) external onlyOwnerOrAdmin {
        if (reservePrice == 0) revert CannotSetAuctionReservePriceToZero();

        AuctionData memory auction = auctions[baseId];
        if (auction.startTime == 0) revert AuctionDoesNotExist();
        if (auction.firstBidTime > 0) revert AuctionAlreadyStarted();

        auction.reservePrice = reservePrice;
        auctions[baseId] = auction;
        emit AuctionReservePriceUpdated(baseId, reservePrice);
    }

    /** TAKE SALE LIVE ----------------------------------------------------- */

    /**
     * @notice Admin function to set the sale live state
     * @dev If set to false, then collecting will be paused.
     * @param isLive Whether the sale is live or not
     */
    function setSaleLiveState(bool isLive) external onlyOwnerOrAdmin {
        _isSaleLive = isLive;
    }

    /** PAYMENTS ----------------------------------------------------------- */

    /**
     * @notice Admin function to set the payment address for withdrawing funds
     * @param paymentAddress The new address where payments should be sent upon withdrawal
     */
    function setPaymentAddress(address paymentAddress) external onlyOwnerOrAdmin {
        if (paymentAddress == address(0)) revert CannotSetPaymentAddressToZero();
        payments = paymentAddress;
    }

    /* ------------------------------------------------------------------------
                                   G E T T E R S
    ------------------------------------------------------------------------ */

    function tokenPrice(uint256 baseId) external view returns (uint256) {
        return _baseIdToTokenData[baseId].price;
    }

    function tokenIsOneOfOne(uint256 baseId) external view returns (bool) {
        return _baseIdToTokenData[baseId].editionSize == 1;
    }

    function tokenIsEdition(uint256 baseId) external view returns (bool) {
        return _baseIdToTokenData[baseId].editionSize > 1;
    }

    function tokenEditionSize(uint256 baseId) external view returns (uint256) {
        return _baseIdToTokenData[baseId].editionSize;
    }

    function tokenCollectedCount(uint256 baseId) external view returns (uint256) {
        return _baseIdToTokenData[baseId].collected;
    }

    function tokenIsFountExclusive(uint256 baseId) external view returns (bool) {
        return _baseIdToTokenData[baseId].fountExclusive;
    }

    function tokenRequiresOffChainSignatureToCollect(uint256 baseId) external view returns (bool) {
        return _baseIdToTokenData[baseId].requiresSig;
    }

    function tokenIsFreeToCollect(uint256 baseId) external view returns (bool) {
        TokenData memory tokenData = _baseIdToTokenData[baseId];
        return tokenData.price == 0 && tokenData.freeToCollect;
    }

    function auctionHasStarted(uint256 baseId) external view returns (bool) {
        return auctions[baseId].firstBidTime > 0;
    }

    function auctionStartTime(uint256 baseId) external view returns (uint256) {
        return auctions[baseId].startTime;
    }

    function auctionHasEnded(uint256 baseId) external view returns (bool) {
        AuctionData memory auction = auctions[baseId];
        bool hasStarted = auctions[baseId].firstBidTime > 0;
        return hasStarted && block.timestamp >= auction.firstBidTime + auction.duration;
    }

    function auctionEndTime(uint256 baseId) external view returns (uint256) {
        AuctionData memory auction = auctions[baseId];
        bool hasStarted = auctions[baseId].firstBidTime > 0;
        return hasStarted ? auction.startTime + auction.duration : 0;
    }

    function auctionDuration(uint256 baseId) external view returns (uint256) {
        return auctions[baseId].duration;
    }

    function auctionFirstBidTime(uint256 baseId) external view returns (uint256) {
        return auctions[baseId].firstBidTime;
    }

    function auctionHighestBidder(uint256 baseId) external view returns (address) {
        return auctions[baseId].highestBidder;
    }

    function auctionHighestBid(uint256 baseId) external view returns (uint256) {
        return auctions[baseId].highestBid;
    }

    function auctionReservePrice(uint256 baseId) external view returns (uint256) {
        return auctions[baseId].reservePrice;
    }

    /* ------------------------------------------------------------------------
       W I T H D R A W
    ------------------------------------------------------------------------ */

    /**
     * @notice Admin function to withdraw ETH from this contract
     * @dev Withdraws to the `payments` address.
     *
     * Reverts if:
     *  - there are active auctions
     *  - the payments address is set to zero
     *
     */
    function withdrawETH() public onlyOwnerOrAdmin {
        // Check there are no active auctions
        if (activeAuctions > 0) revert CannotWithdrawWithActiveAuctions();
        // Send the eth to the payments address
        _withdrawETH(payments);
    }

    /**
     * @notice Admin function to withdraw ETH from this contract and release from payments contract
     * @dev Withdraws to the `payments` address, then calls `releaseAllETH` as a splitter.
     *
     * Reverts if:
     *  - there are active auctions
     *  - the payments address is set to zero
     *
     */
    function withdrawAndReleaseAllETH() public onlyOwnerOrAdmin {
        // Check there are no active auctions
        if (activeAuctions > 0) revert CannotWithdrawWithActiveAuctions();
        // Send the eth to the payments address
        _withdrawETH(payments);
        // And then release all the ETH to the payees
        IMorningsPayments(payments).releaseAllETH();
    }

    /**
     * @notice Admin function to withdraw ERC-20 tokens from this contract
     * @dev Withdraws to the `payments` address.
     *
     * Reverts if:
     *  - the payments address is set to zero
     *
     */
    function withdrawTokens(address tokenAddress) public onlyOwnerOrAdmin {
        // Send the tokens to the payments address
        _withdrawToken(tokenAddress, payments);
    }

    /**
     * @notice Admin function to withdraw ERC-20 tokens from this contract
     * @param to The address to send the ERC-20 tokens to
     */
    function withdrawTokens(address tokenAddress, address to) public onlyOwnerOrAdmin {
        _withdrawToken(tokenAddress, to);
    }
}