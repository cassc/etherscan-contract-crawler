// SPDX-License-Identifier: LGPL-3.0-only
// Created By: Art Blocks Inc.

import "../../../interfaces/0.8.x/IGenArt721CoreContractV3_Base.sol";
import "../../../interfaces/0.8.x/IMinterFilterV0.sol";
import "../../../interfaces/0.8.x/IFilteredMinterDAExpSettlementV0.sol";
import "../MinterBase_v0_1_1.sol";

import "@openzeppelin-4.7/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin-4.7/contracts/utils/math/SafeCast.sol";

pragma solidity 0.8.17;

/**
 * @title Filtered Minter contract that allows tokens to be minted with ETH.
 * Pricing is achieved using an automated Dutch-auction mechanism, with a
 * settlement mechanism for tokens purchased before the auction ends.
 * This is designed to be used with GenArt721CoreContractV3 flagship or
 * engine contracts.
 * @author Art Blocks Inc.
 * @notice Privileged Roles and Ownership:
 * This contract is designed to be managed, with limited powers.
 * Privileged roles and abilities are controlled by the core contract's Admin
 * ACL contract and a project's artist. Both of these roles hold extensive
 * power and can modify minter details.
 * Care must be taken to ensure that the admin ACL contract and artist
 * addresses are secure behind a multi-sig or other access control mechanism.
 * Additionally, the purchaser of a token has some trust assumptions regarding
 * settlement, beyond typical minter Art Blocks trust assumptions. In general,
 * Artists and Admin are trusted to not abuse their powers in a way that
 * would artifically inflate the sellout price of a project. They are
 * incentivized to not do so, as it would diminish their reputation and
 * ability to sell future projects. Agreements between Admin and Artist
 * may or may not be in place to further dissuade artificial inflation of an
 * auction's sellout price.
 * ----------------------------------------------------------------------------
 * The following functions are restricted to the core contract's Admin ACL
 * contract:
 * - setAllowablePriceDecayHalfLifeRangeSeconds (note: this range is only
 *   enforced when creating new auctions)
 * - resetAuctionDetails (note: this will prevent minting until a new auction
 *   is created)
 * - adminEmergencyReduceSelloutPrice
 * ----------------------------------------------------------------------------
 * The following functions are restricted to a project's artist or the core
 * contract's Admin ACL contract:
 * - withdrawArtistAndAdminRevenues (note: this may only be called after an
 *   auction has sold out or has reached base price)
 * ----------------------------------------------------------------------------
 * The following functions are restricted to a project's artist:
 * - setAuctionDetails (note: this may only be called when there is no active
 *   auction, and must start at a price less than or equal to any previously
 *   made purchases)
 * ----------------------------------------------------------------------------
 * Additional admin and artist privileged roles may be described on other
 * contracts that this minter integrates with.
 *
 * @dev Note that while this minter makes use of `block.timestamp` and it is
 * technically possible that this value is manipulated by block producers via
 * denial of service (in PoS), such manipulation will not have material impact
 * on the price values of this minter given the business practices for how
 * pricing is congfigured for this minter and that variations on the order of
 * less than a minute should not meaningfully impact price given the minimum
 * allowable price decay rate that this minter intends to support.
 */
contract MinterDAExpSettlementV1 is
    ReentrancyGuard,
    MinterBase,
    IFilteredMinterDAExpSettlementV0
{
    using SafeCast for uint256;

    /// Core contract address this minter interacts with
    address public immutable genArt721CoreAddress;
    /// The core contract integrates with V3 contracts
    IGenArt721CoreContractV3_Base private immutable genArtCoreContract_Base;

    /// Minter filter address this minter interacts with
    address public immutable minterFilterAddress;

    /// Minter filter this minter may interact with.
    IMinterFilterV0 private immutable minterFilter;

    /// minterType for this minter
    string public constant minterType = "MinterDAExpSettlementV1";

    uint256 constant ONE_MILLION = 1_000_000;

    struct ProjectConfig {
        // on this minter, hasMaxBeenInvoked is updated only during every
        // purchase, and is only true if this minter minted the final token.
        // this enables the minter to know when a sellout price is greater than
        // the auction's base price.
        bool maxHasBeenInvoked;
        // set to true only after artist + admin revenues have been collected
        bool auctionRevenuesCollected;
        // number of tokens minted that have potential of future settlement.
        // max uint24 > 16.7 million tokens > 1 million tokens/project max
        uint24 numSettleableInvocations;
        // max uint64 ~= 1.8e19 sec ~= 570 billion years
        uint64 timestampStart;
        uint64 priceDecayHalfLifeSeconds;
        // Prices are packed internally as uint128, resulting in a maximum
        // allowed price of ~3.4e20 ETH. This is many orders of magnitude
        // greater than current ETH supply.
        uint128 startPrice;
        // base price is non-zero for all configured auctions on this minter
        uint128 basePrice;
        // This value is only zero if no purchases have been made on this
        // minter.
        // When non-zero, this value is used as a reference when an auction is
        // reset by admin, and then a new auction is configured by an artist.
        // In that case, the new auction will be required to have a starting
        // price less than or equal to this value, if one or more purchases
        // have been made on this minter.
        uint256 latestPurchasePrice;
    }

    mapping(uint256 => ProjectConfig) public projectConfig;

    /// Minimum price decay half life: price must decay with a half life of at
    /// least this amount (must cut in half at least every N seconds).
    uint256 public minimumPriceDecayHalfLifeSeconds = 300; // 5 minutes
    /// Maximum price decay half life: price may decay with a half life of no
    /// more than this amount (may cut in half at no more than every N seconds).
    uint256 public maximumPriceDecayHalfLifeSeconds = 3600; // 60 minutes

    struct Receipt {
        // max uint232 allows for > 1e51 ETH (much more than max supply)
        uint232 netPosted;
        // max uint24 still allows for > max project supply of 1 million tokens
        uint24 numPurchased;
    }
    /// user address => project ID => receipt
    mapping(address => mapping(uint256 => Receipt)) receipts;

    // modifier to restrict access to only AdminACL or the artist
    modifier onlyCoreAdminACLOrArtist(uint256 _projectId, bytes4 _selector) {
        require(
            (msg.sender ==
                genArtCoreContract_Base.projectIdToArtistAddress(_projectId)) ||
                (
                    genArtCoreContract_Base.adminACLAllowed(
                        msg.sender,
                        address(this),
                        _selector
                    )
                ),
            "Only Artist or Admin ACL"
        );
        _;
    }

    // modifier to restrict access to only AdminACL allowed calls
    // @dev defers which ACL contract is used to the core contract
    modifier onlyCoreAdminACL(bytes4 _selector) {
        require(
            genArtCoreContract_Base.adminACLAllowed(
                msg.sender,
                address(this),
                _selector
            ),
            "Only Core AdminACL allowed"
        );
        _;
    }

    modifier onlyArtist(uint256 _projectId) {
        require(
            (msg.sender ==
                genArtCoreContract_Base.projectIdToArtistAddress(_projectId)),
            "Only Artist"
        );
        _;
    }

    /**
     * @notice Initializes contract to be a Filtered Minter for
     * `_minterFilter`, integrated with Art Blocks core contract
     * at address `_genArt721Address`.
     * @param _genArt721Address Art Blocks core contract address for
     * which this contract will be a minter.
     * @param _minterFilter Minter filter for which
     * this will a filtered minter.
     */
    constructor(
        address _genArt721Address,
        address _minterFilter
    ) ReentrancyGuard() MinterBase(_genArt721Address) {
        genArt721CoreAddress = _genArt721Address;
        // always populate immutable engine contracts, but only use appropriate
        // interface based on isEngine in the rest of the contract
        genArtCoreContract_Base = IGenArt721CoreContractV3_Base(
            _genArt721Address
        );
        minterFilterAddress = _minterFilter;
        minterFilter = IMinterFilterV0(_minterFilter);
        require(
            minterFilter.genArt721CoreAddress() == _genArt721Address,
            "Illegal contract pairing"
        );
    }

    /**
     * @notice This function is not implemented on this minter, and exists only
     * for interface conformance reasons. This minter checks if max invocations
     * have been reached during every purchase to determine if a sellout has
     * occurred. Therefore, the local caching of max invocations is not
     * beneficial or necessary.
     */
    function setProjectMaxInvocations(uint256 /*_projectId*/) external pure {
        // not implemented because maxInvocations must be checked during every mint
        // to know if final price should be set
        revert(
            "setProjectMaxInvocations not implemented - updated during every mint"
        );
    }

    /**
     * @notice Warning: Disabling purchaseTo is not supported on this minter.
     * This method exists purely for interface-conformance purposes.
     */
    function togglePurchaseToDisabled(
        uint256 _projectId
    ) external view onlyArtist(_projectId) {
        revert("Action not supported");
    }

    /**
     * @notice projectId => has project reached its maximum number of
     * invocations while being minted with this minter?
     * Note that this returns a local cache of the core contract's
     * state, and may be out of sync with the core contract. This is
     * intentional. A false negative will only result in a gas cost increase,
     * since the core contract will still enforce max invocations during during
     * minting. A false negative will also only occur if the max invocations
     * was either reduced on the core contract to equal current invocations, or
     * if the max invocations was reached by minting on a different minter.
     * In both of these cases, we expect the net purchase price (after
     * settlement) shall be the base price of the project's auction. This
     * prevents an artist from benefiting by reducing max invocations on the
     * core mid-auction, or by minting on a different minter.
     * Note that if an artist wishes to reduce the max invocations on the core
     * to something less than the current invocations, but more than max
     * invocations (with the hope of increasing the sellout price), an admin
     * function is provided to manually reduce the sellout price to a lower
     * value, if desired, in the `adminEmergencyReduceSelloutPrice`
     * function.
     * @param _projectId projectId to be queried
     *
     */
    function projectMaxHasBeenInvoked(
        uint256 _projectId
    ) external view returns (bool) {
        return projectConfig[_projectId].maxHasBeenInvoked;
    }

    /**
     * @notice projectId => auction parameters
     */
    function projectAuctionParameters(
        uint256 _projectId
    )
        external
        view
        returns (
            uint256 timestampStart,
            uint256 priceDecayHalfLifeSeconds,
            uint256 startPrice,
            uint256 basePrice
        )
    {
        ProjectConfig storage _projectConfig = projectConfig[_projectId];
        return (
            _projectConfig.timestampStart,
            _projectConfig.priceDecayHalfLifeSeconds,
            _projectConfig.startPrice,
            _projectConfig.basePrice
        );
    }

    /**
     * @notice Sets the minimum and maximum values that are settable for
     * `_priceDecayHalfLifeSeconds` across all projects.
     * @param _minimumPriceDecayHalfLifeSeconds Minimum price decay half life
     * (in seconds).
     * @param _maximumPriceDecayHalfLifeSeconds Maximum price decay half life
     * (in seconds).
     */
    function setAllowablePriceDecayHalfLifeRangeSeconds(
        uint256 _minimumPriceDecayHalfLifeSeconds,
        uint256 _maximumPriceDecayHalfLifeSeconds
    )
        external
        onlyCoreAdminACL(
            this.setAllowablePriceDecayHalfLifeRangeSeconds.selector
        )
    {
        require(
            _maximumPriceDecayHalfLifeSeconds >
                _minimumPriceDecayHalfLifeSeconds,
            "Maximum half life must be greater than minimum"
        );
        require(
            _minimumPriceDecayHalfLifeSeconds > 0,
            "Half life of zero not allowed"
        );
        minimumPriceDecayHalfLifeSeconds = _minimumPriceDecayHalfLifeSeconds;
        maximumPriceDecayHalfLifeSeconds = _maximumPriceDecayHalfLifeSeconds;
        emit AuctionHalfLifeRangeSecondsUpdated(
            _minimumPriceDecayHalfLifeSeconds,
            _maximumPriceDecayHalfLifeSeconds
        );
    }

    ////// Auction Functions
    /**
     * @notice Sets auction details for project `_projectId`.
     * @param _projectId Project ID to set auction details for.
     * @param _auctionTimestampStart Timestamp at which to start the auction.
     * @param _priceDecayHalfLifeSeconds The half life with which to decay the
     *  price (in seconds).
     * @param _startPrice Price at which to start the auction, in Wei.
     * If a previous auction existed on this minter and at least one settleable
     * purchase has been made, this value must be less than or equal to the
     * price when the previous auction was paused. This enforces an overall
     * monatonically decreasing auction. Must be greater than or equal to
     * max(uint128) for internal storage packing purposes.
     * @param _basePrice Resting price of the auction, in Wei. Must be greater
     * than or equal to max(uint128) for internal storage packing purposes.
     * @dev Note that setting the auction price explicitly to `0` is
     * intentionally not allowed. This allows the minter to use the assumption
     * that a price of `0` indicates that the auction is not configured.
     * @dev Note that prices must be <= max(128) for internal storage packing
     * efficiency purposes only. This function's interface remains unchanged
     * for interface conformance purposes.
     */
    function setAuctionDetails(
        uint256 _projectId,
        uint256 _auctionTimestampStart,
        uint256 _priceDecayHalfLifeSeconds,
        uint256 _startPrice,
        uint256 _basePrice
    ) external onlyArtist(_projectId) {
        // CHECKS
        ProjectConfig storage _projectConfig = projectConfig[_projectId];
        require(
            _projectConfig.timestampStart == 0 ||
                block.timestamp < _projectConfig.timestampStart,
            "No modifications mid-auction"
        );
        require(
            block.timestamp < _auctionTimestampStart,
            "Only future auctions"
        );
        require(
            _startPrice > _basePrice,
            "Auction start price must be greater than auction end price"
        );
        // require _basePrice is non-zero to simplify logic of this minter
        require(_basePrice > 0, "Base price must be non-zero");
        // If previous purchases have been made, require monotonically
        // decreasing purchase prices to preserve settlement and revenue
        // claiming logic. Since base price is always non-zero, if
        // latestPurchasePrice is zero, then no previous purchases have been
        // made, and startPrice may be set to any value.
        require(
            _projectConfig.latestPurchasePrice == 0 || // never purchased
                _startPrice <= _projectConfig.latestPurchasePrice,
            "Auction start price must be <= latest purchase price"
        );
        require(
            (_priceDecayHalfLifeSeconds >= minimumPriceDecayHalfLifeSeconds) &&
                (_priceDecayHalfLifeSeconds <=
                    maximumPriceDecayHalfLifeSeconds),
            "Price decay half life must fall between min and max allowable values"
        );
        // EFFECTS
        _projectConfig.timestampStart = _auctionTimestampStart.toUint64();
        _projectConfig.priceDecayHalfLifeSeconds = _priceDecayHalfLifeSeconds
            .toUint64();
        _projectConfig.startPrice = _startPrice.toUint128();
        _projectConfig.basePrice = _basePrice.toUint128();

        emit SetAuctionDetails(
            _projectId,
            _auctionTimestampStart,
            _priceDecayHalfLifeSeconds,
            _startPrice,
            _basePrice
        );
    }

    /**
     * @notice Resets auction details for project `_projectId`, zero-ing out all
     * relevant auction fields. Not intended to be used in normal auction
     * operation, but rather only in case of the need to reset an ongoing
     * auction. An expected time this might occur would be when a frontend
     * issue was occuring, and many typical users are actively being prevented
     * from easily minting (even though minting would technically be possible
     * directly from the contract).
     * This function is only callable by the core admin during an active
     * auction, before revenues have been collected.
     * The price at the time of the reset will be the maximum starting price
     * when re-configuring the next auction if one or more settleable purchases
     * have been made.
     * This is to ensure that purchases up through the block that this is
     * called on will remain settleable, and that revenue claimed does not
     * surpass (payments - excess_settlement_funds) for a given project.
     * @param _projectId Project ID to set auction details for.
     */
    function resetAuctionDetails(
        uint256 _projectId
    ) external onlyCoreAdminACL(this.resetAuctionDetails.selector) {
        // CHECKS
        ProjectConfig storage _projectConfig = projectConfig[_projectId];
        require(_projectConfig.startPrice != 0, "Auction must be configured");
        // no reset after revenues collected, since that solidifies amount due
        require(
            !_projectConfig.auctionRevenuesCollected,
            "Only before revenues collected"
        );
        // EFFECTS
        // reset to initial values
        _projectConfig.timestampStart = 0;
        _projectConfig.priceDecayHalfLifeSeconds = 0;
        _projectConfig.startPrice = 0;
        _projectConfig.basePrice = 0;
        // Since auction revenues have not been collected, we can safely assume
        // that numSettleableInvocations is the number of purchases made on
        // this minter. A dummy value of 0 is used for latest purchase price if
        // no purchases have been made.
        emit ResetAuctionDetails(
            _projectId,
            _projectConfig.numSettleableInvocations,
            _projectConfig.latestPurchasePrice
        );
    }

    /**
     * @notice This represents an admin stepping in and reducing the sellout
     * price of an auction. This is only callable by the core admin, only
     * after the auction is complete, but before project revenues are
     * withdrawn.
     * This is only intended to be used in the case where for some reason,
     * whether malicious or accidental, the sellout price was too high.
     * Examples of this include:
     *  - The artist reducing a project's maxInvocations on the core contract
     *    after an auction has started, but before it ends, eliminating the
     *    ability of purchasers to fairly determine market price under the
     *    original, expected auction parameters.
     *  - Any other reason the admin deems to be a valid reason to reduce the
     *    sellout price of an auction, prior to marking it as valid.
     * @param _projectId Project ID to reduce auction sellout price for.
     * @param _newSelloutPrice New sellout price to set for the auction. Must
     * be less than the current sellout price.
     */
    function adminEmergencyReduceSelloutPrice(
        uint256 _projectId,
        uint256 _newSelloutPrice
    )
        external
        onlyCoreAdminACL(this.adminEmergencyReduceSelloutPrice.selector)
    {
        ProjectConfig storage _projectConfig = projectConfig[_projectId];
        require(_projectConfig.maxHasBeenInvoked, "Auction must be complete");
        // @dev no need to check that auction max invocations has been reached,
        // because if it was, the sellout price will be zero, and the following
        // check will fail.
        require(
            _newSelloutPrice < _projectConfig.latestPurchasePrice,
            "May only reduce sellout price"
        );
        require(
            _newSelloutPrice >= _projectConfig.basePrice,
            "May only reduce sellout price to base price or greater"
        );
        // ensure latestPurchasePrice is non-zero if any purchases on minter
        // @dev only possible to fail this if auction is in a reset state
        require(_newSelloutPrice > 0, "Only sellout prices > 0");
        require(
            !_projectConfig.auctionRevenuesCollected,
            "Only before revenues collected"
        );
        _projectConfig.latestPurchasePrice = _newSelloutPrice;
        emit SelloutPriceUpdated(_projectId, _newSelloutPrice);
    }

    /**
     * @notice This withdraws project revenues for the artist and admin.
     * This function is only callable by the artist or admin, and only after
     * one of the following is true:
     * - the auction has sold out above base price
     * - the auction has reached base price
     * Note that revenues are not claimable if in a temporary state after
     * an auction is reset.
     * Revenues may only be collected a single time per project.
     * After revenues are collected, auction parameters will never be allowed
     * to be reset, and excess settlement funds will become immutable and fully
     * deterministic.
     */
    function withdrawArtistAndAdminRevenues(
        uint256 _projectId
    )
        external
        nonReentrant
        onlyCoreAdminACLOrArtist(
            _projectId,
            this.withdrawArtistAndAdminRevenues.selector
        )
    {
        ProjectConfig storage _projectConfig = projectConfig[_projectId];
        // CHECKS
        // require revenues to not have already been collected
        require(
            !_projectConfig.auctionRevenuesCollected,
            "Revenues already collected"
        );
        // get the current net price of the auction - reverts if no auction
        // is configured.
        // @dev _getPrice is guaranteed <= _projectConfig.latestPurchasePrice,
        // since this minter enforces monotonically decreasing purchase prices.
        uint256 _price = _getPrice(_projectId);
        // if the price is not base price, require that the auction have
        // reached max invocations. This prevents premature withdrawl
        // before final auction price is possible to know.
        if (_price != _projectConfig.basePrice) {
            // prefer to use locally cached value of maxHasBeenInvoked, which
            // is only updated when a purchase is made. This is to handle the
            // case where an artist reduced max invocations to current
            // invocations on the core contract mid-auction. In that case, the
            // the following _projectConfig.maxHasBeenInvoked check will fail
            // (only a local cache is used). This is a valid state, and in that
            // somewhat suspicious case, the artist must wait until the auction
            // reaches base price before withdrawing funds, at which point the
            // latestPurchasePrice will be set to base price, maximizing
            // purchaser excess settlement amounts, and minimizing artist/admin
            // revenue.
            require(
                _projectConfig.maxHasBeenInvoked,
                "Active auction not yet sold out"
            );
        } else {
            // update the latest purchase price to the base price, to ensure
            // the base price is used for all future settlement calculations
            _projectConfig.latestPurchasePrice = _projectConfig.basePrice;
        }
        // EFFECTS
        _projectConfig.auctionRevenuesCollected = true;
        // if the price is base price, the auction is valid and may be claimed
        // calculate the artist and admin revenues (no check requuired)
        uint256 netRevenues = _projectConfig.numSettleableInvocations * _price;
        // INTERACTIONS
        splitRevenuesETH(_projectId, netRevenues, genArt721CoreAddress);
        emit ArtistAndAdminRevenuesWithdrawn(_projectId);
    }

    /**
     * @notice Purchases a token from project `_projectId`.
     * @param _projectId Project ID to mint a token on.
     * @return tokenId Token ID of minted token
     */
    function purchase(
        uint256 _projectId
    ) external payable returns (uint256 tokenId) {
        tokenId = purchaseTo_do6(msg.sender, _projectId);
        return tokenId;
    }

    /**
     * @notice gas-optimized version of purchase(uint256).
     */
    function purchase_H4M(
        uint256 _projectId
    ) external payable returns (uint256 tokenId) {
        tokenId = purchaseTo_do6(msg.sender, _projectId);
        return tokenId;
    }

    /**
     * @notice Purchases a token from project `_projectId` and sets
     * the token's owner to `_to`.
     * @param _to Address to be the new token's owner.
     * @param _projectId Project ID to mint a token on.
     * @return tokenId Token ID of minted token
     */
    function purchaseTo(
        address _to,
        uint256 _projectId
    ) external payable returns (uint256 tokenId) {
        return purchaseTo_do6(_to, _projectId);
    }

    /**
     * @notice gas-optimized version of purchaseTo(address, uint256).
     */
    function purchaseTo_do6(
        address _to,
        uint256 _projectId
    ) public payable nonReentrant returns (uint256 tokenId) {
        // CHECKS
        ProjectConfig storage _projectConfig = projectConfig[_projectId];

        // Note that `maxHasBeenInvoked` is only checked here to reduce gas
        // consumption after a project has been fully minted.
        // `_projectConfig.maxHasBeenInvoked` is locally cached during every
        // purchase to reduce gas consumption and enable recording of sellout
        // price, but if not in sync with the core contract's value,
        // the core contract also enforces its own max invocation check during
        // minting.
        require(
            !_projectConfig.maxHasBeenInvoked,
            "Maximum number of invocations reached"
        );

        // _getPrice reverts if auction is unconfigured or has not started
        uint256 currentPriceInWei = _getPrice(_projectId);

        // EFFECTS
        // update the purchaser's receipt and require sufficient net payment
        Receipt storage receipt = receipts[msg.sender][_projectId];

        // in memory copy + update
        uint256 netPosted = receipt.netPosted + msg.value;
        uint256 numPurchased = receipt.numPurchased + 1;

        // require sufficient payment on project
        require(
            netPosted >= numPurchased * currentPriceInWei,
            "Must send minimum value to mint"
        );

        // update Receipt in storage
        // @dev overflow checks are not required since the added values cannot
        // be enough to overflow due to maximum invocations or supply of ETH
        receipt.netPosted = uint232(netPosted);
        receipt.numPurchased = uint24(numPurchased);

        // emit event indicating new receipt state
        emit ReceiptUpdated(msg.sender, _projectId, numPurchased, netPosted);

        // update latest purchase price (on this minter) in storage
        // @dev this is used to enforce monotonically decreasing purchase price
        // across multiple auctions
        _projectConfig.latestPurchasePrice = currentPriceInWei;

        tokenId = minterFilter.mint(_to, _projectId, msg.sender);

        // Note that this requires that the core contract's maxInvocations
        // be accurate to ensure that the minters maxHasBeenInvoked is
        // accurate, so we get the value from the core contract directly.
        uint256 maxInvocations;
        (, maxInvocations, , , , ) = genArtCoreContract_Base.projectStateData(
            _projectId
        );
        // okay if this underflows because if statement will always eval false.
        // this is only for gas optimization and recording sellout price in
        // an event (core enforces maxInvocations).
        unchecked {
            if (tokenId % ONE_MILLION == maxInvocations - 1) {
                _projectConfig.maxHasBeenInvoked = true;
                emit SelloutPriceUpdated(_projectId, currentPriceInWei);
            }
        }

        // INTERACTIONS
        if (_projectConfig.auctionRevenuesCollected) {
            // if revenues have been collected, split funds immediately.
            // @dev note that we are guaranteed to be at auction base price,
            // since we know we didn't sellout prior to this tx.
            // note that we don't refund msg.sender here, since a separate
            // settlement mechanism is provided on this minter, unrelated to
            // msg.value
            splitRevenuesETH(
                _projectId,
                currentPriceInWei,
                genArt721CoreAddress
            );
        } else {
            // increment the number of settleable invocations that will be
            // claimable by the artist and admin once auction is validated.
            // do not split revenue here since will be claimed at a later time.
            _projectConfig.numSettleableInvocations++;
        }

        return tokenId;
    }

    /**
     * @notice Reclaims the sender's payment above current settled price for
     * project `_projectId`. The current settled price is the the price paid
     * for the most recently purchased token, or the base price if the artist
     * has withdrawn revenues after the auction reached base price.
     * This function is callable at any point, but is expected to typically be
     * called after auction has sold out above base price or after the auction
     * has been purchased at base price. This minimizes the amount of gas
     * required to send all excess settlement funds to the sender.
     * Sends excess settlement funds to msg.sender.
     * @param _projectId Project ID to reclaim excess settlement funds on.
     */
    function reclaimProjectExcessSettlementFunds(uint256 _projectId) external {
        reclaimProjectExcessSettlementFundsTo(payable(msg.sender), _projectId);
    }

    /**
     * @notice Reclaims the sender's payment above current settled price for
     * project `_projectId`. The current settled price is the the price paid
     * for the most recently purchased token, or the base price if the artist
     * has withdrawn revenues after the auction reached base price.
     * This function is callable at any point, but is expected to typically be
     * called after auction has sold out above base price or after the auction
     * has been purchased at base price. This minimizes the amount of gas
     * required to send all excess settlement funds.
     * Sends excess settlement funds to address `_to`.
     * @param _to Address to send excess settlement funds to.
     * @param _projectId Project ID to reclaim excess settlement funds on.
     */
    function reclaimProjectExcessSettlementFundsTo(
        address payable _to,
        uint256 _projectId
    ) public nonReentrant {
        ProjectConfig storage _projectConfig = projectConfig[_projectId];
        Receipt storage receipt = receipts[msg.sender][_projectId];
        uint256 numPurchased = receipt.numPurchased;
        // CHECKS
        // input validation
        require(_to != address(0), "No claiming to the zero address");
        // require that a user has purchased at least one token on this project
        require(numPurchased > 0, "No purchases made by this address");
        // get the latestPurchasePrice, which returns the sellout price if the
        // auction sold out before reaching base price, or returns the base
        // price if auction has reached base price and artist has withdrawn
        // revenues.
        // @dev if user is eligible for a reclaiming, they have purchased a
        // token, therefore we are guaranteed to have a populated
        // latestPurchasePrice
        uint256 currentSettledTokenPrice = _projectConfig.latestPurchasePrice;

        // EFFECTS
        // calculate the excess settlement funds amount
        // implicit overflow/underflow checks in solidity ^0.8
        uint256 requiredAmountPosted = numPurchased * currentSettledTokenPrice;
        uint256 excessSettlementFunds = receipt.netPosted -
            requiredAmountPosted;
        // update Receipt in storage
        receipt.netPosted = requiredAmountPosted.toUint232();
        // emit event indicating new receipt state
        emit ReceiptUpdated(
            msg.sender,
            _projectId,
            numPurchased,
            requiredAmountPosted
        );

        // INTERACTIONS
        bool success_;
        (success_, ) = _to.call{value: excessSettlementFunds}("");
        require(success_, "Reclaiming failed");
    }

    /**
     * @notice Reclaims the sender's payment above current settled price for
     * projects in `_projectIds`. The current settled price is the the price
     * paid for the most recently purchased token, or the base price if the
     * artist has withdrawn revenues after the auction reached base price.
     * This function is callable at any point, but is expected to typically be
     * called after auction has sold out above base price or after the auction
     * has been purchased at base price. This minimizes the amount of gas
     * required to send all excess settlement funds to the sender.
     * Sends total of all excess settlement funds to msg.sender in a single
     * chunk. Entire transaction reverts if any excess settlement calculation
     * fails.
     * @param _projectIds Array of project IDs to reclaim excess settlement
     * funds on.
     */
    function reclaimProjectsExcessSettlementFunds(
        uint256[] calldata _projectIds
    ) external {
        reclaimProjectsExcessSettlementFundsTo(
            payable(msg.sender),
            _projectIds
        );
    }

    /**
     * @notice Reclaims the sender's payment above current settled price for
     * projects in `_projectIds`. The current settled price is the the price
     * paid for the most recently purchased token, or the base price if the
     * artist has withdrawn revenues after the auction reached base price.
     * This function is callable at any point, but is expected to typically be
     * called after auction has sold out above base price or after the auction
     * has been purchased at base price. This minimizes the amount of gas
     * required to send all excess settlement funds to the sender.
     * Sends total of all excess settlement funds to `_to` in a single
     * chunk. Entire transaction reverts if any excess settlement calculation
     * fails.
     * @param _to Address to send excess settlement funds to.
     * @param _projectIds Array of project IDs to reclaim excess settlement
     * funds on.
     */
    function reclaimProjectsExcessSettlementFundsTo(
        address payable _to,
        uint256[] memory _projectIds
    ) public nonReentrant {
        // CHECKS
        // input validation
        require(_to != address(0), "No claiming to the zero address");
        // EFFECTS
        // for each project, tally up the excess settlement funds and update
        // the receipt in storage
        uint256 excessSettlementFunds;
        uint256 projectIdsLength = _projectIds.length;
        for (uint256 i; i < projectIdsLength; ) {
            uint256 projectId = _projectIds[i];
            ProjectConfig storage _projectConfig = projectConfig[projectId];
            Receipt storage receipt = receipts[msg.sender][projectId];
            uint256 numPurchased = receipt.numPurchased;
            // input validation
            // require that a user has purchased at least one token on this project
            require(numPurchased > 0, "No purchases made by this address");
            // get the latestPurchasePrice, which returns the sellout price if the
            // auction sold out before reaching base price, or returns the base
            // price if auction has reached base price and artist has withdrawn
            // revenues.
            // @dev if user is eligible for a claim, they have purchased a token,
            // therefore we are guaranteed to have a populated
            // latestPurchasePrice
            uint256 currentSettledTokenPrice = _projectConfig
                .latestPurchasePrice;
            // calculate the excessSettlementFunds amount
            // implicit overflow/underflow checks in solidity ^0.8
            uint256 requiredAmountPosted = numPurchased *
                currentSettledTokenPrice;
            excessSettlementFunds += (receipt.netPosted - requiredAmountPosted);
            // reduce the netPosted (in storage) to value after excess settlement
            // funds deducted
            receipt.netPosted = requiredAmountPosted.toUint232();
            // emit event indicating new receipt state
            emit ReceiptUpdated(
                msg.sender,
                projectId,
                numPurchased,
                requiredAmountPosted
            );
            // gas efficiently increment i
            // won't overflow due to for loop, as well as gas limts
            unchecked {
                ++i;
            }
        }

        // INTERACTIONS
        // send excess settlement funds in a single chunk for all
        // projects
        bool success_;
        (success_, ) = _to.call{value: excessSettlementFunds}("");
        require(success_, "Reclaiming failed");
    }

    /**
     * @notice Gets price of minting a token on project `_projectId` given
     * the project's AuctionParameters and current block timestamp.
     * Reverts if auction has not yet started or auction is unconfigured.
     * Returns auction last purchase price if auction sold out before reaching
     * base price.
     * @param _projectId Project ID to get price of token for.
     * @return current price of token in Wei
     * @dev This method calculates price decay using a linear interpolation
     * of exponential decay based on the artist-provided half-life for price
     * decay, `_priceDecayHalfLifeSeconds`.
     */
    function _getPrice(uint256 _projectId) private view returns (uint256) {
        ProjectConfig storage _projectConfig = projectConfig[_projectId];
        // if auction sold out on this minter, return the latest purchase
        // price (which is the sellout price). This is the price that is due
        // after an auction is complete.
        if (_projectConfig.maxHasBeenInvoked) {
            return _projectConfig.latestPurchasePrice;
        }
        // otherwise calculate price based on current block timestamp and
        // auction configuration (will revert if auction has not started)
        // move parameters to memory if used more than once
        uint256 _timestampStart = uint256(_projectConfig.timestampStart);
        uint256 _priceDecayHalfLifeSeconds = uint256(
            _projectConfig.priceDecayHalfLifeSeconds
        );
        uint256 _basePrice = _projectConfig.basePrice;

        require(block.timestamp > _timestampStart, "Auction not yet started");
        require(_priceDecayHalfLifeSeconds > 0, "Only configured auctions");
        uint256 decayedPrice = _projectConfig.startPrice;
        uint256 elapsedTimeSeconds;
        unchecked {
            // already checked that block.timestamp > _timestampStart above
            elapsedTimeSeconds = block.timestamp - _timestampStart;
        }
        // Divide by two (via bit-shifting) for the number of entirely completed
        // half-lives that have elapsed since auction start time.
        unchecked {
            // already required _priceDecayHalfLifeSeconds > 0
            decayedPrice >>= elapsedTimeSeconds / _priceDecayHalfLifeSeconds;
        }
        // Perform a linear interpolation between partial half-life points, to
        // approximate the current place on a perfect exponential decay curve.
        unchecked {
            // value of expression is provably always less than decayedPrice,
            // so no underflow is possible when the subtraction assignment
            // operator is used on decayedPrice.
            decayedPrice -=
                (decayedPrice *
                    (elapsedTimeSeconds % _priceDecayHalfLifeSeconds)) /
                _priceDecayHalfLifeSeconds /
                2;
        }
        if (decayedPrice < _basePrice) {
            // Price may not decay below stay `basePrice`.
            return _basePrice;
        }
        return decayedPrice;
    }

    /**
     * @notice Gets the current excess settlement funds on project `_projectId`
     * for address `_walletAddress`. The returned value is expected to change
     * throughtout an auction, since the latest purchase price is used when
     * determining excess settlement funds.
     * A user may claim excess settlement funds by calling the function
     * `reclaimProjectExcessSettlementFunds(_projectId)`.
     * @param _projectId Project ID to query.
     * @param _walletAddress Account address for which the excess posted funds
     * is being queried.
     * @return excessSettlementFundsInWei Amount of excess settlement funds, in
     * wei
     */
    function getProjectExcessSettlementFunds(
        uint256 _projectId,
        address _walletAddress
    ) external view returns (uint256 excessSettlementFundsInWei) {
        // input validation
        require(_walletAddress != address(0), "No zero address");
        // load struct from storage
        ProjectConfig storage _projectConfig = projectConfig[_projectId];
        Receipt storage receipt = receipts[_walletAddress][_projectId];
        // require that a user has purchased at least one token on this project
        require(receipt.numPurchased > 0, "No purchases made by this address");
        // get the latestPurchasePrice, which returns the sellout price if the
        // auction sold out before reaching base price, or returns the base
        // price if auction has reached base price and artist has withdrawn
        // revenues.
        // @dev if user is eligible for a reclaiming, they have purchased a
        // token, therefore we are guaranteed to have a populated
        // latestPurchasePrice
        uint256 currentSettledTokenPrice = _projectConfig.latestPurchasePrice;

        // EFFECTS
        // calculate the excess settlement funds amount and return
        // implicit overflow/underflow checks in solidity ^0.8
        uint256 requiredAmountPosted = receipt.numPurchased *
            currentSettledTokenPrice;
        excessSettlementFundsInWei = receipt.netPosted - requiredAmountPosted;
        return excessSettlementFundsInWei;
    }

    /**
     * @notice Gets the latest purchase price for project `_projectId`, or 0 if
     * no purchases have been made.
     */
    function getProjectLatestPurchasePrice(
        uint256 _projectId
    ) external view returns (uint256 latestPurchasePrice) {
        return projectConfig[_projectId].latestPurchasePrice;
    }

    /**
     * @notice Gets the number of settleable invocations for project `_projectId`.
     */
    function getNumSettleableInvocations(
        uint256 _projectId
    ) external view returns (uint256 numSettleableInvocations) {
        return projectConfig[_projectId].numSettleableInvocations;
    }

    /**
     * @notice Gets if price of token is configured, price of minting a
     * token on project `_projectId`, and currency symbol and address to be
     * used as payment. Supersedes any core contract price information.
     * @param _projectId Project ID to get price information for.
     * @return isConfigured true only if project's auction parameters have been
     * configured on this minter
     * @return tokenPriceInWei current price of token on this minter - invalid
     * if auction has not yet been configured
     * @return currencySymbol currency symbol for purchases of project on this
     * minter. This minter always returns "ETH"
     * @return currencyAddress currency address for purchases of project on
     * this minter. This minter always returns null address, reserved for ether
     */
    function getPriceInfo(
        uint256 _projectId
    )
        external
        view
        returns (
            bool isConfigured,
            uint256 tokenPriceInWei,
            string memory currencySymbol,
            address currencyAddress
        )
    {
        ProjectConfig storage _projectConfig = projectConfig[_projectId];

        isConfigured = (_projectConfig.startPrice > 0);
        if (block.timestamp <= _projectConfig.timestampStart) {
            // Provide a reasonable value for `tokenPriceInWei` when it would
            // otherwise revert, using the starting price before auction starts.
            tokenPriceInWei = _projectConfig.startPrice;
        } else if (_projectConfig.startPrice == 0) {
            // In the case of unconfigured auction, return price of zero when
            // it would otherwise revert
            tokenPriceInWei = 0;
        } else {
            tokenPriceInWei = _getPrice(_projectId);
        }
        currencySymbol = "ETH";
        currencyAddress = address(0);
    }
}