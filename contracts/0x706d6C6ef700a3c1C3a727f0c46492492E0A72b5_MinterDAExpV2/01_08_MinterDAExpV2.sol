// SPDX-License-Identifier: LGPL-3.0-only
// Created By: Art Blocks Inc.

import "../../../interfaces/0.8.x/IGenArt721CoreContractV3.sol";
import "../../../interfaces/0.8.x/IMinterFilterV0.sol";
import "../../../interfaces/0.8.x/IFilteredMinterV0.sol";

import "@openzeppelin-4.5/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin-4.5/contracts/utils/math/SafeCast.sol";

pragma solidity 0.8.17;

/**
 * @title Filtered Minter contract that allows tokens to be minted with ETH.
 * Pricing is achieved using an automated Dutch-auction mechanism.
 * This is designed to be used with IGenArt721CoreContractV3 contracts.
 * @author Art Blocks Inc.
 * @notice Privileged Roles and Ownership:
 * This contract is designed to be managed, with limited powers.
 * Privileged roles and abilities are controlled by the core contract's Admin
 * ACL contract and a project's artist. Both of these roles hold extensive
 * power and can modify minter details.
 * Care must be taken to ensure that the admin ACL contract and artist
 * addresses are secure behind a multi-sig or other access control mechanism.
 * ----------------------------------------------------------------------------
 * The following functions are restricted to the core contract's Admin ACL
 * contract:
 * - setAllowablePriceDecayHalfLifeRangeSeconds (note: this range is only
 *   enforced when creating new auctions)
 * - resetAuctionDetails (note: this will prevent minting until a new auction
 *   is created)
 * ----------------------------------------------------------------------------
 * The following functions are restricted to a project's artist:
 * - setAuctionDetails (note: this may only be called when there is no active
 *   auction)
 * ----------------------------------------------------------------------------
 * Additional admin and artist privileged roles may be described on other
 * contracts that this minter integrates with.
 *
 * @dev Note that while this minter makes use of `block.timestamp` and it is
 * technically possible that this value is manipulated by block producers, such
 * manipulation will not have material impact on the price values of this minter
 * given the business practices for how pricing is congfigured for this minter
 * and that variations on the order of less than a minute should not
 * meaningfully impact price given the minimum allowable price decay rate that
 * this minter intends to support.
 */
contract MinterDAExpV2 is ReentrancyGuard, IFilteredMinterV0 {
    using SafeCast for uint256;

    /// Auction details updated for project `projectId`.
    event SetAuctionDetails(
        uint256 indexed projectId,
        uint256 _auctionTimestampStart,
        uint256 _priceDecayHalfLifeSeconds,
        uint256 _startPrice,
        uint256 _basePrice
    );

    /// Auction details cleared for project `projectId`.
    event ResetAuctionDetails(uint256 indexed projectId);

    /// Maximum and minimum allowed price decay half lifes updated.
    event AuctionHalfLifeRangeSecondsUpdated(
        uint256 _minimumPriceDecayHalfLifeSeconds,
        uint256 _maximumPriceDecayHalfLifeSeconds
    );

    /// Core contract address this minter interacts with
    address public immutable genArt721CoreAddress;

    /// This contract handles cores with interface IV3
    IGenArt721CoreContractV3 private immutable genArtCoreContract;

    /// Minter filter address this minter interacts with
    address public immutable minterFilterAddress;

    /// Minter filter this minter may interact with.
    IMinterFilterV0 private immutable minterFilter;

    /// minterType for this minter
    string public constant minterType = "MinterDAExpV2";

    uint256 constant ONE_MILLION = 1_000_000;

    struct ProjectConfig {
        bool maxHasBeenInvoked;
        uint24 maxInvocations;
        // max uint64 ~= 1.8e19 sec ~= 570 billion years
        uint64 timestampStart;
        uint64 priceDecayHalfLifeSeconds;
        uint256 startPrice;
        uint256 basePrice;
    }

    mapping(uint256 => ProjectConfig) public projectConfig;

    /// Minimum price decay half life: price must decay with a half life of at
    /// least this amount (must cut in half at least every N seconds).
    uint256 public minimumPriceDecayHalfLifeSeconds = 300; // 5 minutes
    /// Maximum price decay half life: price may decay with a half life of no
    /// more than this amount (may cut in half at no more than every N seconds).
    uint256 public maximumPriceDecayHalfLifeSeconds = 3600; // 60 minutes

    // modifier to restrict access to only AdminACL allowed calls
    // @dev defers which ACL contract is used to the core contract
    modifier onlyCoreAdminACL(bytes4 _selector) {
        require(
            genArtCoreContract.adminACLAllowed(
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
                genArtCoreContract.projectIdToArtistAddress(_projectId)),
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
    constructor(address _genArt721Address, address _minterFilter)
        ReentrancyGuard()
    {
        genArt721CoreAddress = _genArt721Address;
        genArtCoreContract = IGenArt721CoreContractV3(_genArt721Address);
        minterFilterAddress = _minterFilter;
        minterFilter = IMinterFilterV0(_minterFilter);
        require(
            minterFilter.genArt721CoreAddress() == _genArt721Address,
            "Illegal contract pairing"
        );
    }

    /**
     * @notice Syncs local maximum invocations of project `_projectId` based on
     * the value currently defined in the core contract. Only used for gas
     * optimization of mints after maxInvocations has been reached.
     * @param _projectId Project ID to set the maximum invocations for.
     * @dev this enables gas reduction after maxInvocations have been reached -
     * core contracts shall still enforce a maxInvocation check during mint.
     * @dev function is intentionally not gated to any specific access control;
     * it only syncs a local state variable to the core contract's state.
     */
    function setProjectMaxInvocations(uint256 _projectId) external {
        uint256 maxInvocations;
        (, maxInvocations, , , , ) = genArtCoreContract.projectStateData(
            _projectId
        );
        // update storage with results
        projectConfig[_projectId].maxInvocations = uint24(maxInvocations);
    }

    /**
     * @notice Warning: Disabling purchaseTo is not supported on this minter.
     * This method exists purely for interface-conformance purposes.
     */
    function togglePurchaseToDisabled(uint256 _projectId)
        external
        view
        onlyArtist(_projectId)
    {
        revert("Action not supported");
    }

    /**
     * @notice projectId => has project reached its maximum number of
     * invocations? Note that this returns a local cache of the core contract's
     * state, and may be out of sync with the core contract. This is
     * intentional, as it only enables gas optimization of mints after a
     * project's maximum invocations has been reached. A false negative will
     * only result in a gas cost increase, since the core contract will still
     * enforce a maxInvocation check during minting. A false positive is not
     * possible because the V3 core contract only allows maximum invocations
     * to be reduced, not increased. Based on this rationale, we intentionally
     * do not do input validation in this method as to whether or not the input
     * `_projectId` is an existing project ID.
     *
     */
    function projectMaxHasBeenInvoked(uint256 _projectId)
        external
        view
        returns (bool)
    {
        return projectConfig[_projectId].maxHasBeenInvoked;
    }

    /**
     * @notice projectId => project's maximum number of invocations.
     * Optionally synced with core contract value, for gas optimization.
     * Note that this returns a local cache of the core contract's
     * state, and may be out of sync with the core contract. This is
     * intentional, as it only enables gas optimization of mints after a
     * project's maximum invocations has been reached.
     * @dev A number greater than the core contract's project max invocations
     * will only result in a gas cost increase, since the core contract will
     * still enforce a maxInvocation check during minting. A number less than
     * the core contract's project max invocations is only possible when the
     * project's max invocations have not been synced on this minter, since the
     * V3 core contract only allows maximum invocations to be reduced, not
     * increased. When this happens, the minter will enable minting, allowing
     * the core contract to enforce the max invocations check. Based on this
     * rationale, we intentionally do not do input validation in this method as
     * to whether or not the input `_projectId` is an existing project ID.
     */
    function projectMaxInvocations(uint256 _projectId)
        external
        view
        returns (uint256)
    {
        return uint256(projectConfig[_projectId].maxInvocations);
    }

    /**
     * @notice projectId => auction parameters
     */
    function projectAuctionParameters(uint256 _projectId)
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
     * @param _basePrice Resting price of the auction, in Wei.
     * @dev Note that it is intentionally supported here that the configured
     * price may be explicitly set to `0`.
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
        _projectConfig.startPrice = _startPrice;
        _projectConfig.basePrice = _basePrice;

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
     * operation, but rather only in case of the need to halt an auction.
     * @param _projectId Project ID to set auction details for.
     */
    function resetAuctionDetails(uint256 _projectId)
        external
        onlyCoreAdminACL(this.resetAuctionDetails.selector)
    {
        ProjectConfig storage _projectConfig = projectConfig[_projectId];
        // reset to initial values
        _projectConfig.timestampStart = 0;
        _projectConfig.priceDecayHalfLifeSeconds = 0;
        _projectConfig.startPrice = 0;
        _projectConfig.basePrice = 0;

        emit ResetAuctionDetails(_projectId);
    }

    /**
     * @notice Purchases a token from project `_projectId`.
     * @param _projectId Project ID to mint a token on.
     * @return tokenId Token ID of minted token
     */
    function purchase(uint256 _projectId)
        external
        payable
        returns (uint256 tokenId)
    {
        tokenId = purchaseTo_do6(msg.sender, _projectId);
        return tokenId;
    }

    /**
     * @notice gas-optimized version of purchase(uint256).
     */
    function purchase_H4M(uint256 _projectId)
        external
        payable
        returns (uint256 tokenId)
    {
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
    function purchaseTo(address _to, uint256 _projectId)
        external
        payable
        returns (uint256 tokenId)
    {
        return purchaseTo_do6(_to, _projectId);
    }

    /**
     * @notice gas-optimized version of purchaseTo(address, uint256).
     */
    function purchaseTo_do6(address _to, uint256 _projectId)
        public
        payable
        nonReentrant
        returns (uint256 tokenId)
    {
        // CHECKS
        ProjectConfig storage _projectConfig = projectConfig[_projectId];

        // Note that `maxHasBeenInvoked` is only checked here to reduce gas
        // consumption after a project has been fully minted.
        // `_projectConfig.maxHasBeenInvoked` is locally cached to reduce
        // gas consumption, but if not in sync with the core contract's value,
        // the core contract also enforces its own max invocation check during
        // minting.
        require(
            !_projectConfig.maxHasBeenInvoked,
            "Maximum number of invocations reached"
        );

        // _getPrice reverts if auction is unconfigured or has not started
        uint256 currentPriceInWei = _getPrice(_projectId);
        require(
            msg.value >= currentPriceInWei,
            "Must send minimum value to mint!"
        );

        // EFFECTS
        tokenId = minterFilter.mint(_to, _projectId, msg.sender);

        // okay if this underflows because if statement will always eval false.
        // this is only for gas optimization (core enforces maxInvocations).
        unchecked {
            if (tokenId % ONE_MILLION == _projectConfig.maxInvocations - 1) {
                _projectConfig.maxHasBeenInvoked = true;
            }
        }

        // INTERACTIONS
        _splitFundsETHAuction(_projectId, currentPriceInWei);
        return tokenId;
    }

    /**
     * @dev splits ETH funds between sender (if refund), foundation,
     * artist, and artist's additional payee for a token purchased on
     * project `_projectId`.
     * @dev possible DoS during splits is acknowledged, and mitigated by
     * business practices, including end-to-end testing on mainnet, and
     * admin-accepted artist payment addresses.
     * @param _projectId Project ID for which funds shall be split.
     * @param _currentPriceInWei Current price of token, in Wei.
     */
    function _splitFundsETHAuction(
        uint256 _projectId,
        uint256 _currentPriceInWei
    ) internal {
        if (msg.value > 0) {
            bool success_;
            // send refund to sender
            uint256 refund = msg.value - _currentPriceInWei;
            if (refund > 0) {
                (success_, ) = msg.sender.call{value: refund}("");
                require(success_, "Refund failed");
            }
            // split remaining funds between foundation, artist, and artist's
            // additional payee
            (
                uint256 artblocksRevenue_,
                address payable artblocksAddress_,
                uint256 artistRevenue_,
                address payable artistAddress_,
                uint256 additionalPayeePrimaryRevenue_,
                address payable additionalPayeePrimaryAddress_
            ) = genArtCoreContract.getPrimaryRevenueSplits(
                    _projectId,
                    _currentPriceInWei
                );
            // Art Blocks payment
            if (artblocksRevenue_ > 0) {
                (success_, ) = artblocksAddress_.call{value: artblocksRevenue_}(
                    ""
                );
                require(success_, "Art Blocks payment failed");
            }
            // artist payment
            if (artistRevenue_ > 0) {
                (success_, ) = artistAddress_.call{value: artistRevenue_}("");
                require(success_, "Artist payment failed");
            }
            // additional payee payment
            if (additionalPayeePrimaryRevenue_ > 0) {
                (success_, ) = additionalPayeePrimaryAddress_.call{
                    value: additionalPayeePrimaryRevenue_
                }("");
                require(success_, "Additional Payee payment failed");
            }
        }
    }

    /**
     * @notice Gets price of minting a token on project `_projectId` given
     * the project's AuctionParameters and current block timestamp.
     * Reverts if auction has not yet started or auction is unconfigured.
     * @param _projectId Project ID to get price of token for.
     * @return current price of token in Wei
     * @dev This method calculates price decay using a linear interpolation
     * of exponential decay based on the artist-provided half-life for price
     * decay, `_priceDecayHalfLifeSeconds`.
     */
    function _getPrice(uint256 _projectId) private view returns (uint256) {
        ProjectConfig storage _projectConfig = projectConfig[_projectId];
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
    function getPriceInfo(uint256 _projectId)
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