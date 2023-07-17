// SPDX-License-Identifier: LGPL-3.0-only
// Created By: Art Blocks Inc.

import "../../interfaces/0.8.x/IGenArt721CoreContractV3_Base.sol";
import "../../interfaces/0.8.x/IMinterFilterV0.sol";
import "../../interfaces/0.8.x/IFilteredMinterDAExpSettlementV1.sol";
import "./MinterBase_v0_1_1.sol";

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
 * - setProjectMaxInvocations
 * - manuallyLimitProjectMaxInvocations
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
contract MinterDAExpSettlementV2 is
    ReentrancyGuard,
    MinterBase,
    IFilteredMinterDAExpSettlementV1
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
    string public constant minterType = "MinterDAExpSettlementV2";

    uint256 constant ONE_MILLION = 1_000_000;

    struct ProjectConfig {
        // maxHasBeenInvoked is only true if invocations are equal to the
        // locally limited max invocations value, `maxInvocations`. It may be
        // stale (e.g. a different minter reachd max invocations), may return a
        // false negative if stale, and must be accounted for in this minter's
        // logic.
        bool maxHasBeenInvoked;
        // maxInvocations is the maximum number of tokens that may be minted
        // for this project. The value here is cached on the minter, and may
        // be out of sync with the core contract's value. It is guaranteed to
        // be either manually populated or synced to the core contract value if
        // an auction has been populated (i.e. no stale initial values). This
        // behavior must be appropriately accounted for in this minter's logic.
        uint24 maxInvocations;
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

    // function to restrict access to only AdminACL or the artist
    function _onlyCoreAdminACLOrArtist(
        uint256 _projectId,
        bytes4 _selector
    ) internal {
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
    }

    // function to restrict access to only AdminACL allowed calls
    // @dev defers which ACL contract is used to the core contract
    function _onlyCoreAdminACL(bytes4 _selector) internal {
        require(
            genArtCoreContract_Base.adminACLAllowed(
                msg.sender,
                address(this),
                _selector
            ),
            "Only Core AdminACL allowed"
        );
    }

    function _onlyArtist(uint256 _projectId) internal view {
        require(
            (msg.sender ==
                genArtCoreContract_Base.projectIdToArtistAddress(_projectId)),
            "Only Artist"
        );
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
     * @notice This function is intentionally not implemented for this version
     * of the minter. Due to potential for unintended consequences, the
     * function `manuallyLimitProjectMaxInvocations` should be used to manually
     * and explicitly limit the maximum invocations for a project to a value
     * other than the core contract's maximum invocations for a project.
     * @param _projectId Project ID to set the maximum invocations for.
     * @dev This function is included for interface conformance purposes only.
     */
    function setProjectMaxInvocations(uint256 _projectId) external view {
        _onlyArtist(_projectId);
        revert("Not implemented");
    }

    /**
     * @notice Manually sets the local maximum invocations of project `_projectId`
     * with the provided `_maxInvocations`, checking that `_maxInvocations` is less
     * than or equal to the value of project `_project_id`'s maximum invocations that is
     * set on the core contract.
     * @dev Note that a `_maxInvocations` of 0 can only be set if the current `invocations`
     * value is also 0 and this would also set `maxHasBeenInvoked` to true, correctly short-circuiting
     * this minter's purchase function, avoiding extra gas costs from the core contract's maxInvocations check.
     * @param _projectId Project ID to set the maximum invocations for.
     * @param _maxInvocations Maximum invocations to set for the project.
     */
    function manuallyLimitProjectMaxInvocations(
        uint256 _projectId,
        uint256 _maxInvocations
    ) external {
        _onlyArtist(_projectId);
        // CHECKS
        // require that new maxInvocations is greater than 0 to prevent
        // accidental premature closure of a project when artist is
        // configuring, forever preventing any purchases on this minter
        require(_maxInvocations > 0, "Only max invocations gt 0");
        // do not allow changing maxInvocations if maxHasBeenInvoked is true
        // @dev this is a guardrail to prevent accidental re-opening of a
        // completed project that is waiting for revenues to be withdrawn
        // @dev intentionally do not refresh maxHasBeenInvoked here via
        // `_refreshMaxInvocations` because in the edge case of a stale
        // hasMaxBeenInvoked, it is too difficult to determine what the artist
        // may or may not want to do
        ProjectConfig storage _projectConfig = projectConfig[_projectId];
        require(
            !_projectConfig.maxHasBeenInvoked,
            "Max invocations already reached"
        );

        // ensure that the manually set maxInvocations is not greater than what is set on the core contract
        uint256 coreInvocations;
        uint256 coreMaxInvocations;
        (
            coreInvocations,
            coreMaxInvocations
        ) = _getProjectCoreInvocationsAndMaxInvocations(_projectId);
        require(
            _maxInvocations <= coreMaxInvocations,
            "Cannot increase project max invocations above core contract set project max invocations"
        );
        require(
            _maxInvocations >= coreInvocations,
            "Cannot set project max invocations to less than current invocations"
        );
        // EFFECTS
        // update storage with results
        _projectConfig.maxInvocations = uint24(_maxInvocations);
        // We need to ensure maxHasBeenInvoked is correctly set after manually setting the
        // local maxInvocations value.
        _projectConfig.maxHasBeenInvoked = coreInvocations == _maxInvocations;

        emit ProjectMaxInvocationsLimitUpdated(_projectId, _maxInvocations);
    }

    /**
     * @notice Warning: Disabling purchaseTo is not supported on this minter.
     * This method exists purely for interface-conformance purposes.
     */
    function togglePurchaseToDisabled(uint256 _projectId) external view {
        _onlyArtist(_projectId);
        revert("Action not supported");
    }

    /**
     * @notice projectId => has project reached its maximum number of
     * invocations on this minter?
     * Note that this returns a local cached value on the minter, and may be
     * out of sync with the core core contract's state, in which case it may
     * return a false negative.
     */
    function projectMaxHasBeenInvoked(
        uint256 _projectId
    ) external view returns (bool) {
        ProjectConfig storage _projectConfig = projectConfig[_projectId];
        return _projectConfig.maxHasBeenInvoked;
    }

    /**
     * @notice projectId => project's maximum number of invocations.
     * Note that this returns a local cached value, and may be manually
     * limited to be different than the core contract's maxInvocations,
     * or may be out of sync with the core contract's maxInvocations state.
     */
    function projectMaxInvocations(
        uint256 _projectId
    ) external view returns (uint256) {
        return projectConfig[_projectId].maxInvocations;
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
    ) external {
        _onlyCoreAdminACL(
            this.setAllowablePriceDecayHalfLifeRangeSeconds.selector
        );
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
     * @dev Note that this function also populates the local minter max
     * invocation values for the project. This is done to ensure that the
     * minter's local max invocation values are guarenteed to be at least
     * populated when an auction is configured.
     */
    function setAuctionDetails(
        uint256 _projectId,
        uint256 _auctionTimestampStart,
        uint256 _priceDecayHalfLifeSeconds,
        uint256 _startPrice,
        uint256 _basePrice
    ) external {
        _onlyArtist(_projectId);
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

        // refresh max invocations, ensuring the values are populated, and
        // updating any local values that are illogical with respect to the
        // current core contract state.
        // @dev this refresh enables the guarantee that a project's max
        // invocation state is always populated if an auction is configured.
        _refreshMaxInvocations(_projectId);
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
    function resetAuctionDetails(uint256 _projectId) external {
        _onlyCoreAdminACL(this.resetAuctionDetails.selector);
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
     * This is only intended to be used in the case where for some reason, the
     * sellout price was too high.
     * @param _projectId Project ID to reduce auction sellout price for.
     * @param _newSelloutPrice New sellout price to set for the auction. Must
     * be less than the current sellout price.
     */
    function adminEmergencyReduceSelloutPrice(
        uint256 _projectId,
        uint256 _newSelloutPrice
    ) external {
        _onlyCoreAdminACL(this.adminEmergencyReduceSelloutPrice.selector);
        ProjectConfig storage _projectConfig = projectConfig[_projectId];
        require(
            !_projectConfig.auctionRevenuesCollected,
            "Only before revenues collected"
        );

        // refresh max invocations, updating any local values that are
        // illogical with respect to the current core contract state, and
        // ensuring that local hasMaxBeenInvoked is accurate.
        _refreshMaxInvocations(_projectId);

        // require max invocations has been reached
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
        // ensure _newSelloutPrice is non-zero
        require(_newSelloutPrice > 0, "Only sellout prices > 0");
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
    ) external nonReentrant {
        _onlyCoreAdminACLOrArtist(
            _projectId,
            this.withdrawArtistAndAdminRevenues.selector
        );
        ProjectConfig storage _projectConfig = projectConfig[_projectId];
        // CHECKS
        // require revenues to not have already been collected
        require(
            !_projectConfig.auctionRevenuesCollected,
            "Revenues already collected"
        );

        // refresh max invocations, updating any local values that are
        // illogical with respect to the current core contract state, and
        // ensuring that local hasMaxBeenInvoked is accurate.
        _refreshMaxInvocations(_projectId);

        // get the current net price of the auction - reverts if no auction
        // is configured.
        // @dev we use _getPriceUnsafe here, since we just safely synced the
        // project's max invocations and maxHasBeenInvoked, which guarantees
        // an accurate price calculation from _getPriceUnsafe, while being
        // more gas efficient than _getPriceSafe.
        // @dev price is guaranteed <= _projectConfig.latestPurchasePrice,
        // since this minter enforces monotonically decreasing purchase prices.
        uint256 _price = _getPriceUnsafe(_projectId);
        // if the price is not base price, require that the auction have
        // reached max invocations. This prevents premature withdrawl
        // before final auction price is possible to know.
        if (_price != _projectConfig.basePrice) {
            // @dev we can trust maxHasBeenInvoked, since we just
            // refreshed it above with _refreshMaxInvocations, preventing any
            // false negatives
            require(
                _projectConfig.maxHasBeenInvoked,
                "Active auction not yet sold out"
            );
        } else {
            uint256 basePrice = _projectConfig.basePrice;
            // base price of zero indicates no sales, since base price of zero
            // is not allowed when configuring an auction.
            require(basePrice > 0, "Only latestPurchasePrice > 0");
            // update the latest purchase price to the base price, to ensure
            // the base price is used for all future settlement calculations
            _projectConfig.latestPurchasePrice = basePrice;
        }
        // EFFECTS
        _projectConfig.auctionRevenuesCollected = true;
        // if the price is base price, the auction is valid and may be claimed
        // calculate the artist and admin revenues
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

        // Enforce the local limit of maxHasBeenInvoked, which is guaranteed
        // to be populated for all configured auctions.
        // @dev maxHasBeenInvoked can be sale and return a false negative.
        // protect against that case by checking minted token's invocation
        // against this minter's local max invocations immediately after
        // receiving the newly minted tokenID.
        require(
            !_projectConfig.maxHasBeenInvoked,
            "Maximum number of invocations reached"
        );

        // _getPriceUnsafe reverts if auction has not yet started or auction is
        // unconfigured, and auction has not sold out or revenues have not been
        // withdrawn.
        // @dev _getPriceUnsafe is guaranteed to be accurate unless the core
        // contract is limiting invocations and we have stale local state
        // returning a false negative that max invocations have been reached.
        // This is acceptable, because that case will revert this
        // call later on in this function, when the core contract's max
        // invocation check fails.
        uint256 currentPriceInWei = _getPriceUnsafe(_projectId);

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

        // invocation is token number plus one, and will never overflow due to
        // limit of 1e6 invocations per project. block scope for gas efficiency
        // (i.e. avoid an unnecessary var initialization to 0).
        unchecked {
            uint256 tokenInvocation = (tokenId % ONE_MILLION) + 1;
            uint256 localMaxInvocations = _projectConfig.maxInvocations;
            // handle the case where the token invocation == minter local max
            // invocations occurred on a different minter, and we have a stale
            // local maxHasBeenInvoked value returning a false negative.
            // @dev this is a CHECK after EFFECTS, so security was considered
            // in detail here.
            require(
                tokenInvocation <= localMaxInvocations,
                "Maximum number of invocations reached"
            );
            // in typical case, update the local maxHasBeenInvoked value
            // to true if the token invocation == minter local max invocations
            // (enables gas efficient reverts after sellout)
            if (tokenInvocation == localMaxInvocations) {
                _projectConfig.maxHasBeenInvoked = true;
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
     * Reverts if auction has not yet started or auction is unconfigured, and
     * auction has not sold out or revenues have not been withdrawn.
     * Price is guaranteed to be accurate, regardless of the current state of
     * the locally cached minter max invocations.
     * @dev This method is less gas efficient than `_getPriceUnsafe`, but is
     * guaranteed to be accurate.
     * @param _projectId Project ID to get price of token for.
     * @return tokenPriceInWei current price of token in Wei
     * @dev This method calculates price decay using a linear interpolation
     * of exponential decay based on the artist-provided half-life for price
     * decay, `_priceDecayHalfLifeSeconds`.
     */
    function _getPriceSafe(
        uint256 _projectId
    ) private view returns (uint256 tokenPriceInWei) {
        // accurately check if project has sold out
        if (_projectMaxHasBeenInvokedSafe(_projectId)) {
            // max invocations have been reached, return the latest purchased
            // price
            tokenPriceInWei = projectConfig[_projectId].latestPurchasePrice;
        } else {
            // if not sold out, return the current price
            tokenPriceInWei = _getPriceUnsafe(_projectId);
        }
        return tokenPriceInWei;
    }

    /**
     * @notice Gets price of minting a token on project `_projectId` given
     * the project's AuctionParameters and current block timestamp.
     * Reverts if auction has not yet started or auction is unconfigured, and
     * local hasMaxBeenInvoked is false and revenues have not been withdrawn.
     * Price is guaranteed to be accurate unless the minter's local
     * hasMaxBeenInvoked is stale and returning a false negative.
     * @dev when an accurate price is required regardless of the current state
     * state of the locally cached minter max invocations, use the less gas
     * efficient function `_getPriceSafe`.
     * @param _projectId Project ID to get price of token for.
     * @return uint256 current price of token in Wei, accurate if minter max
     * invocations are up to date
     * @dev This method calculates price decay using a linear interpolation
     * of exponential decay based on the artist-provided half-life for price
     * decay, `_priceDecayHalfLifeSeconds`.
     */
    function _getPriceUnsafe(
        uint256 _projectId
    ) private view returns (uint256) {
        ProjectConfig storage _projectConfig = projectConfig[_projectId];
        // return latest purchase price if:
        // - minter is aware of a sold-out auction (without updating max
        //   invocation value)
        // - auction revenues have been collected, at which point the
        //   latest purchase price will never change again
        if (
            _projectConfig.maxHasBeenInvoked ||
            _projectConfig.auctionRevenuesCollected
        ) {
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
            tokenPriceInWei = _getPriceSafe(_projectId);
        }
        currencySymbol = "ETH";
        currencyAddress = address(0);
    }

    /**
     * @notice Sets the local max invocation values of a project equal to the
     * values on the core contract.
     * @param _projectId Project ID to set the maximum invocations for.
     */
    function _syncProjectMaxInvocationsCoreCached(uint256 _projectId) internal {
        uint256 coreMaxInvocations;
        uint256 coreInvocations;
        (
            coreInvocations,
            coreMaxInvocations
        ) = _getProjectCoreInvocationsAndMaxInvocations(_projectId);
        ProjectConfig storage _projectConfig = projectConfig[_projectId];
        // update storage with results, emit event after change
        _projectConfig.maxInvocations = uint24(coreMaxInvocations);
        _projectConfig.maxHasBeenInvoked =
            coreMaxInvocations == coreInvocations;

        emit ProjectMaxInvocationsLimitUpdated(_projectId, coreMaxInvocations);
    }

    /**
     * @notice Returns the current invocations and maximum invocations of
     * project `_projectId` from the core contract.
     * @param _projectId Project ID to get invocations and maximum invocations
     * for.
     * @return invocations current invocations of project.
     * @return maxInvocations maximum invocations of project.
     */
    function _getProjectCoreInvocationsAndMaxInvocations(
        uint256 _projectId
    ) internal view returns (uint256 invocations, uint256 maxInvocations) {
        (invocations, maxInvocations, , , , ) = genArtCoreContract_Base
            .projectStateData(_projectId);
    }

    /**
     * @notice Verifies the cached values of a project's maxInvocation state
     * are logically consistent with the core contract's maxInvocation state,
     * or populates them to equal the core contract's maxInvocation state if
     *  they have never been populated.
     */
    function _refreshMaxInvocations(uint256 _projectId) internal {
        ProjectConfig storage _projectConfig = projectConfig[_projectId];
        // project's max invocations and has max been invoked can only be
        // initial values if never populated, because setting a maxInvocations
        // of zero means maxHasBeenInvoked would be set to true
        bool notPopulated = (_projectConfig.maxInvocations == 0 &&
            _projectConfig.maxHasBeenInvoked == false);
        if (notPopulated) {
            // sync the minter max invocation state to equal the values on the
            // core contract (least restrictive state)
            _syncProjectMaxInvocationsCoreCached(_projectId);
        } else {
            // if using local max invocations, validate the local state
            // (i.e. ensure local max invocations not greater than core max
            // invocations)
            _validateProjectMaxInvocations(_projectId);
        }
    }

    /**
     * @notice Checks and updates local project max invocations to determine if
     * if they are in an illogical state relative to the core contract's max
     * invocations.
     * This updates the project's local max invocations if the value is greater
     * than the core contract's max invocations, which is an illogical state
     * since V3 core contracts cannot increase max invocations. In that case,
     * the project's local max invocations are set to the core contract's max
     * invocations, and the project's `maxHasBeenInvoked` state is refreshed.
     * This also updates the project's `maxHasBeenInvoked` state if the core
     * contract's invocations are greater than or equal to the minter's local
     * max invocations. This handles the case where a different minter has been
     * used to mint above the local max invocations, which would cause
     * `maxHasBeenInvoked` to return a false negative.
     * @param _projectId Project ID to set the maximum invocations for.
     */
    function _validateProjectMaxInvocations(uint256 _projectId) internal {
        uint256 coreMaxInvocations;
        uint256 coreInvocations;
        (
            coreInvocations,
            coreMaxInvocations
        ) = _getProjectCoreInvocationsAndMaxInvocations(_projectId);
        ProjectConfig storage _projectConfig = projectConfig[_projectId];
        uint256 localMaxInvocations = _projectConfig.maxInvocations;
        // check if local max invocations is illogical relative to core
        // contract's max invocations
        if (localMaxInvocations > coreMaxInvocations) {
            // set local max invocations to core contract's max invocations
            _projectConfig.maxInvocations = uint24(coreMaxInvocations);
            // update the project's `maxHasBeenInvoked` state
            // @dev core values are equivalent to local values, use for gas
            // efficiency
            _projectConfig.maxHasBeenInvoked = (coreMaxInvocations ==
                coreInvocations);
            emit ProjectMaxInvocationsLimitUpdated(
                _projectId,
                coreMaxInvocations
            );
        } else if (coreInvocations >= localMaxInvocations) {
            // ensure the local `maxHasBeenInvoked` state is accurate to
            // prevent any false negatives due to minting on other minters
            _projectConfig.maxHasBeenInvoked = true;
            // emit event to ensure any indexers are aware of the change
            // @dev this is not strictly necessary, but is included for
            // convenience
            emit ProjectMaxInvocationsLimitUpdated(
                _projectId,
                coreMaxInvocations
            );
        }
    }

    /**
     * @notice Returns true if the project `_projectId` is sold out, false
     * otherwise. This function returns an accurate value regardless of whether
     * the project's maximum invocations value cached locally on the minter is
     * up to date with the core contract's maximum invocations value.
     * @param _projectId Project ID to check if sold out.
     * @return bool true if the project is sold out, false otherwise.
     * @dev this is a view method, and will not update the minter's local
     * cached state.
     */
    function _projectMaxHasBeenInvokedSafe(
        uint256 _projectId
    ) internal view returns (bool) {
        // get max invocations from core contract
        uint256 coreInvocations;
        uint256 coreMaxInvocations;
        (
            coreInvocations,
            coreMaxInvocations
        ) = _getProjectCoreInvocationsAndMaxInvocations(_projectId);
        ProjectConfig storage _projectConfig = projectConfig[_projectId];
        uint256 localMaxInvocations = _projectConfig.maxInvocations;
        // value is locally defined, and could be out of date.
        // only possible illogical state is if local max invocations is
        // greater than core contract's max invocations, in which case
        // we should use the core contract's max invocations
        if (localMaxInvocations > coreMaxInvocations) {
            // local max invocations is stale and illogical, defer to core
            // contract's max invocations since it is the limiting factor
            return (coreMaxInvocations == coreInvocations);
        }
        // local max invocations is limiting, so check core invocations against
        // local max invocations
        return (coreInvocations >= localMaxInvocations);
    }
}