// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.15;

import {ERC20} from "solmate/tokens/ERC20.sol";
import {ReentrancyGuard} from "solmate/utils/ReentrancyGuard.sol";
import {Auth, Authority} from "solmate/auth/Auth.sol";

import {IBondSDA, IBondAuctioneer} from "../interfaces/IBondSDA.sol";
import {IBondTeller} from "../interfaces/IBondTeller.sol";
import {IBondCallback} from "../interfaces/IBondCallback.sol";
import {IBondAggregator} from "../interfaces/IBondAggregator.sol";

import {TransferHelper} from "../lib/TransferHelper.sol";
import {FullMath} from "../lib/FullMath.sol";

/// @title Bond Sequential Dutch Auctioneer (SDA)
/// @notice Bond Sequential Dutch Auctioneer Base Contract
/// @dev Bond Protocol is a system to create Olympus-style bond markets
///      for any token pair. The markets do not require maintenance and will manage
///      bond prices based on activity. Bond issuers create BondMarkets that pay out
///      a Payout Token in exchange for deposited Quote Tokens. Users can purchase
///      future-dated Payout Tokens with Quote Tokens at the current market price and
///      receive Bond Tokens to represent their position while their bond vests.
///      Once the Bond Tokens vest, they can redeem it for the Quote Tokens.
///
/// @dev The Auctioneer contract allows users to create and manage bond markets.
///      All bond pricing logic and market data is stored in the Auctioneer.
///      A Auctioneer is dependent on a Teller to serve external users and
///      an Aggregator to register new markets. This implementation of the Auctioneer
///      uses a Sequential Dutch Auction pricing system to buy a target amount of quote
///      tokens or sell a target amount of payout tokens over the duration of a market.
///
/// @author Oighty, Zeus, Potted Meat, indigo
abstract contract BondBaseSDA is IBondSDA, Auth {
    using TransferHelper for ERC20;
    using FullMath for uint256;

    /* ========== ERRORS ========== */

    error Auctioneer_OnlyMarketOwner();
    error Auctioneer_InitialPriceLessThanMin();
    error Auctioneer_MarketConcluded(uint256 conclusion_);
    error Auctioneer_MaxPayoutExceeded();
    error Auctioneer_AmountLessThanMinimum();
    error Auctioneer_NotEnoughCapacity();
    error Auctioneer_InvalidCallback();
    error Auctioneer_BadExpiry();
    error Auctioneer_InvalidParams();
    error Auctioneer_NotAuthorized();
    error Auctioneer_NewMarketsNotAllowed();

    /* ========== EVENTS ========== */

    event MarketCreated(
        uint256 indexed id,
        address indexed payoutToken,
        address indexed quoteToken,
        uint48 vesting,
        uint256 initialPrice
    );
    event MarketClosed(uint256 indexed id);
    event Tuned(uint256 indexed id, uint256 oldControlVariable, uint256 newControlVariable);

    /* ========== STATE VARIABLES ========== */

    /// @notice Main information pertaining to bond market
    mapping(uint256 => BondMarket) public markets;

    /// @notice Information used to control how a bond market changes
    mapping(uint256 => BondTerms) public terms;

    /// @notice Data needed for tuning bond market
    mapping(uint256 => BondMetadata) public metadata;

    /// @notice Control variable changes
    mapping(uint256 => Adjustment) public adjustments;

    /// @notice New address to designate as market owner. They must accept ownership to transfer permissions.
    mapping(uint256 => address) public newOwners;

    /// @notice Whether or not the auctioneer allows new markets to be created
    /// @dev    Changing to false will sunset the auctioneer after all active markets end
    bool public allowNewMarkets;

    /// @notice Whether or not the market creator is authorized to use a callback address
    mapping(address => bool) public callbackAuthorized;

    /// Sane defaults for tuning. Can be adjusted for a specific market via setters.
    uint32 public defaultTuneInterval;
    uint32 public defaultTuneAdjustment;
    /// Minimum values for decay, deposit interval, market duration and debt buffer.
    uint32 public minDebtDecayInterval;
    uint32 public minDepositInterval;
    uint32 public minMarketDuration;
    uint32 public minDebtBuffer;

    // A 'vesting' param longer than 50 years is considered a timestamp for fixed expiry.
    uint48 internal constant MAX_FIXED_TERM = 52 weeks * 50;
    uint48 internal constant FEE_DECIMALS = 1e5; // one percent equals 1000.

    // BondAggregator contract with utility functions
    IBondAggregator internal immutable _aggregator;

    // BondTeller contract that handles interactions with users and issues tokens
    IBondTeller internal immutable _teller;

    constructor(
        IBondTeller teller_,
        IBondAggregator aggregator_,
        address guardian_,
        Authority authority_
    ) Auth(guardian_, authority_) {
        _aggregator = aggregator_;
        _teller = teller_;

        defaultTuneInterval = 24 hours;
        defaultTuneAdjustment = 1 hours;
        minDebtDecayInterval = 3 days;
        minDepositInterval = 1 hours;
        minMarketDuration = 1 days;
        minDebtBuffer = 10000; // 10%

        allowNewMarkets = true;
    }

    /* ========== MARKET FUNCTIONS ========== */

    /// @inheritdoc IBondAuctioneer
    function createMarket(bytes calldata params_) external virtual returns (uint256);

    /// @notice core market creation logic, see IBondAuctioneer.createMarket documentation
    function _createMarket(MarketParams memory params_) internal returns (uint256) {
        {
            // Check that the auctioneer is allowing new markets to be created
            if (!allowNewMarkets) revert Auctioneer_NewMarketsNotAllowed();

            // Ensure params are in bounds
            uint8 payoutTokenDecimals = params_.payoutToken.decimals();
            uint8 quoteTokenDecimals = params_.quoteToken.decimals();

            if (payoutTokenDecimals < 6 || payoutTokenDecimals > 18)
                revert Auctioneer_InvalidParams();
            if (quoteTokenDecimals < 6 || quoteTokenDecimals > 18)
                revert Auctioneer_InvalidParams();
            if (params_.scaleAdjustment < -24 || params_.scaleAdjustment > 24)
                revert Auctioneer_InvalidParams();

            // Restrict the use of a callback address unless allowed
            if (!callbackAuthorized[msg.sender] && params_.callbackAddr != address(0))
                revert Auctioneer_NotAuthorized();
        }

        // Unit to scale calculation for this market by to ensure reasonable values
        // for price, debt, and control variable without under/overflows.
        // See IBondAuctioneer for more details.
        //
        // scaleAdjustment should be equal to (payoutDecimals - quoteDecimals) - ((payoutPriceDecimals - quotePriceDecimals) / 2)
        uint256 scale;
        unchecked {
            scale = 10**uint8(36 + params_.scaleAdjustment);
        }

        if (params_.formattedInitialPrice < params_.formattedMinimumPrice)
            revert Auctioneer_InitialPriceLessThanMin();

        // Record new market into array for later retrieval and get marketId
        uint256 marketId = _aggregator.registerMarket(params_.payoutToken, params_.quoteToken);

        uint32 secondsToConclusion;
        uint32 debtDecayInterval;
        {
            secondsToConclusion = uint32(params_.conclusion - block.timestamp);
            if (
                secondsToConclusion < minMarketDuration ||
                params_.depositInterval < minDepositInterval
            ) revert Auctioneer_InvalidParams();

            // At minimum, the interval is how long it takes for price to drop to 0. In reality, a 50% drop is likely a guaranteed
            // bond sale. So debt decay interval needs to be long enough to allow a bond to adjust if oversold.
            // Needs to be some multiple of deposit interval because you don't want to go from 100 to 0 during the time frame
            // you expected to sell a single bond. 5 is a sane default observed from running OP v1 bond markets.
            uint32 userDebtDecay = params_.depositInterval * 5;
            debtDecayInterval = minDebtDecayInterval > userDebtDecay
                ? minDebtDecayInterval
                : userDebtDecay;

            uint256 tuneIntervalCapacity = params_.capacity.mulDiv(
                uint256(
                    params_.depositInterval > defaultTuneInterval
                        ? params_.depositInterval
                        : defaultTuneInterval
                ),
                uint256(secondsToConclusion)
            );

            metadata[marketId] = BondMetadata({
                lastTune: uint48(block.timestamp),
                lastDecay: uint48(block.timestamp),
                length: secondsToConclusion,
                depositInterval: params_.depositInterval,
                tuneInterval: params_.depositInterval > defaultTuneInterval
                    ? params_.depositInterval
                    : defaultTuneInterval,
                tuneAdjustmentDelay: defaultTuneAdjustment,
                debtDecayInterval: debtDecayInterval,
                tuneIntervalCapacity: tuneIntervalCapacity,
                tuneBelowCapacity: params_.capacity - tuneIntervalCapacity,
                lastTuneDebt: (
                    params_.capacityInQuote
                        ? params_.capacity.mulDiv(scale, params_.formattedInitialPrice)
                        : params_.capacity
                ).mulDiv(uint256(debtDecayInterval), uint256(secondsToConclusion))
            });
        }

        // Initial target debt is equal to capacity scaled by the ratio of the debt decay interval and the length of the market.
        // This is the amount of debt that should be decayed over the decay interval if no purchases are made.
        // Note price should be passed in a specific format:
        // price = (payoutPriceCoefficient / quotePriceCoefficient)
        //         * 10**(36 + scaleAdjustment + quoteDecimals - payoutDecimals + payoutPriceDecimals - quotePriceDecimals)
        // See IBondAuctioneer for more details and variable definitions.
        uint256 targetDebt;
        uint256 maxPayout;
        {
            uint256 capacity = params_.capacityInQuote
                ? params_.capacity.mulDiv(scale, params_.formattedInitialPrice)
                : params_.capacity;

            targetDebt = capacity.mulDiv(uint256(debtDecayInterval), uint256(secondsToConclusion));

            // Max payout is the amount of capacity that should be utilized in a deposit
            // interval. for example, if capacity is 1,000 TOKEN, there are 10 days to conclusion,
            // and the preferred deposit interval is 1 day, max payout would be 100 TOKEN.
            maxPayout = capacity.mulDiv(
                uint256(params_.depositInterval),
                uint256(secondsToConclusion)
            );
        }

        markets[marketId] = BondMarket({
            owner: msg.sender,
            payoutToken: params_.payoutToken,
            quoteToken: params_.quoteToken,
            callbackAddr: params_.callbackAddr,
            capacityInQuote: params_.capacityInQuote,
            capacity: params_.capacity,
            totalDebt: targetDebt,
            minPrice: params_.formattedMinimumPrice,
            maxPayout: maxPayout,
            purchased: 0,
            sold: 0,
            scale: scale
        });

        // Max debt serves as a circuit breaker for the market. let's say the quote token is a stablecoin,
        // and that stablecoin depegs. without max debt, the market would continue to buy until it runs
        // out of capacity. this is configurable with a 3 decimal buffer (1000 = 1% above initial price).
        // Note that its likely advisable to keep this buffer wide.
        // Note that the buffer is above 100%. i.e. 10% buffer = initial debt * 1.1
        // 1e5 = 100,000. 10,000 / 100,000 = 10%.
        uint256 minDebtBuffer_ = maxPayout.mulDiv(FEE_DECIMALS, targetDebt) > minDebtBuffer
            ? maxPayout.mulDiv(FEE_DECIMALS, targetDebt)
            : minDebtBuffer;
        uint256 maxDebt = targetDebt +
            targetDebt.mulDiv(
                uint256(params_.debtBuffer > minDebtBuffer_ ? params_.debtBuffer : minDebtBuffer_),
                1e5
            );

        // The control variable is set so that initial price equals the desired initial price. the control
        // variable is the ultimate determinant of price, so we compute this last.
        //
        // price = control variable * debt / scale
        // therefore, control variable = price * scale / debt
        uint256 controlVariable = params_.formattedInitialPrice.mulDiv(scale, targetDebt);

        terms[marketId] = BondTerms({
            controlVariable: controlVariable,
            maxDebt: maxDebt,
            vesting: params_.vesting,
            conclusion: params_.conclusion
        });

        emit MarketCreated(
            marketId,
            address(params_.payoutToken),
            address(params_.quoteToken),
            params_.vesting,
            params_.formattedInitialPrice
        );

        return marketId;
    }

    /// @inheritdoc IBondAuctioneer
    function setIntervals(uint256 id_, uint32[3] calldata intervals_) external override {
        // Check that the intervals are non-zero
        if (intervals_[0] == 0 || intervals_[1] == 0 || intervals_[2] == 0)
            revert Auctioneer_InvalidParams();

        // Check that tuneInterval >= tuneAdjustmentDelay
        if (intervals_[0] < intervals_[1]) revert Auctioneer_InvalidParams();

        BondMetadata storage meta = metadata[id_];
        // Check that tuneInterval >= depositInterval
        if (intervals_[0] < meta.depositInterval) revert Auctioneer_InvalidParams();

        // Check that debtDecayInterval >= minDebtDecayInterval
        if (intervals_[2] < minDebtDecayInterval) revert Auctioneer_InvalidParams();

        // Check that sender is market owner
        BondMarket memory market = markets[id_];
        if (msg.sender != market.owner) revert Auctioneer_OnlyMarketOwner();

        // Update intervals
        meta.tuneInterval = intervals_[0];
        meta.tuneIntervalCapacity = market.capacity.mulDiv(
            uint256(intervals_[0]),
            uint256(terms[id_].conclusion) - block.timestamp
        ); // don't have a stored value for market duration, this will update tuneIntervalCapacity based on time remaining
        meta.tuneAdjustmentDelay = intervals_[1];
        meta.debtDecayInterval = intervals_[2];
    }

    /// @inheritdoc IBondAuctioneer
    function pushOwnership(uint256 id_, address newOwner_) external override {
        if (msg.sender != markets[id_].owner) revert Auctioneer_OnlyMarketOwner();
        newOwners[id_] = newOwner_;
    }

    /// @inheritdoc IBondAuctioneer
    function pullOwnership(uint256 id_) external override {
        if (msg.sender != newOwners[id_]) revert Auctioneer_NotAuthorized();
        markets[id_].owner = newOwners[id_];
    }

    /// @inheritdoc IBondAuctioneer
    function setDefaults(uint32[6] memory defaults_) external override requiresAuth {
        // Restricted to authorized addresses, initially restricted to policy
        defaultTuneInterval = defaults_[0];
        defaultTuneAdjustment = defaults_[1];
        minDebtDecayInterval = defaults_[2];
        minDepositInterval = defaults_[3];
        minMarketDuration = defaults_[4];
        minDebtBuffer = defaults_[5];
    }

    /// @inheritdoc IBondAuctioneer
    function setAllowNewMarkets(bool status_) external override requiresAuth {
        // Restricted to authorized addresses, initially restricted to guardian
        allowNewMarkets = status_;
    }

    /// @inheritdoc IBondAuctioneer
    function setCallbackAuthStatus(address creator_, bool status_) external override requiresAuth {
        // Restricted to authorized addresses, initially restricted to guardian
        callbackAuthorized[creator_] = status_;
    }

    /// @inheritdoc IBondAuctioneer
    function closeMarket(uint256 id_) external override {
        if (msg.sender != markets[id_].owner) revert Auctioneer_OnlyMarketOwner();
        _close(id_);
    }

    /* ========== TELLER FUNCTIONS ========== */

    /// @inheritdoc IBondAuctioneer
    function purchaseBond(
        uint256 id_,
        uint256 amount_,
        uint256 minAmountOut_
    ) external override returns (uint256 payout) {
        if (msg.sender != address(_teller)) revert Auctioneer_NotAuthorized();

        BondMarket storage market = markets[id_];
        BondTerms memory term = terms[id_];

        // Markets end at a defined timestamp
        uint48 currentTime = uint48(block.timestamp);
        if (currentTime >= term.conclusion) revert Auctioneer_MarketConcluded(term.conclusion);

        uint256 price;
        (price, payout) = _decayAndGetPrice(id_, amount_, uint48(block.timestamp)); // Debt and the control variable decay over time

        // Payout must be greater than user inputted minimum
        if (payout < minAmountOut_) revert Auctioneer_AmountLessThanMinimum();

        // Markets have a max payout amount, capping size because deposits
        // do not experience slippage. max payout is recalculated upon tuning
        if (payout > market.maxPayout) revert Auctioneer_MaxPayoutExceeded();

        // Update Capacity and Debt values

        // Capacity is either the number of payout tokens that the market can sell
        // (if capacity in quote is false),
        //
        // or the number of quote tokens that the market can buy
        // (if capacity in quote is true)

        // If amount/payout is greater than capacity remaining, revert
        if (market.capacityInQuote ? amount_ > market.capacity : payout > market.capacity)
            revert Auctioneer_NotEnoughCapacity();
        unchecked {
            // Capacity is decreased by the deposited or paid amount
            market.capacity -= market.capacityInQuote ? amount_ : payout;

            // Markets keep track of how many quote tokens have been
            // purchased, and how many payout tokens have been sold
            market.purchased += amount_;
            market.sold += payout;
        }

        // Circuit breaker. If max debt is breached, the market is closed
        if (term.maxDebt < market.totalDebt) {
            _close(id_);
        } else {
            // If market will continue, the control variable is tuned to hit targets on time
            _tune(id_, currentTime, price);
        }
    }

    /* ========== INTERNAL DEPO FUNCTIONS ========== */

    /// @notice          Close a market
    /// @dev             Closing a market sets capacity to 0 and immediately stops bonding
    function _close(uint256 id_) internal {
        terms[id_].conclusion = uint48(block.timestamp);
        markets[id_].capacity = 0;

        emit MarketClosed(id_);
    }

    /// @notice                 Decay debt, and adjust control variable if there is an active change
    /// @param id_              ID of market
    /// @param amount_          Amount of quote tokens being purchased
    /// @param time_            Current timestamp (saves gas when passed in)
    /// @return marketPrice_    Current market price of bond, accounting for decay
    /// @return payout_         Amount of payout tokens received at current price
    function _decayAndGetPrice(
        uint256 id_,
        uint256 amount_,
        uint48 time_
    ) internal returns (uint256 marketPrice_, uint256 payout_) {
        BondMarket memory market = markets[id_];

        // Debt is a time-decayed sum of tokens spent in a market
        // Debt is added when deposits occur and removed over time
        // |
        // |    debt falls with
        // |   / \  inactivity        / \
        // | /     \              /\ /   \
        // |         \           /        \ / \
        // |           \      /\/
        // |             \  /  and rises
        // |                with deposits
        // |
        // |------------------------------------| t

        // Decay debt by the amount of time since the last decay
        uint256 decayedDebt = currentDebt(id_);
        markets[id_].totalDebt = decayedDebt;

        // Control variable decay

        // The bond control variable is continually tuned. When it is lowered (which
        // lowers the market price), the change is carried out smoothly over time.
        if (adjustments[id_].active) {
            Adjustment storage adjustment = adjustments[id_];

            (uint256 adjustBy, uint48 secondsSince, bool stillActive) = _controlDecay(id_);
            terms[id_].controlVariable -= adjustBy;

            if (stillActive) {
                adjustment.change -= adjustBy;
                adjustment.timeToAdjusted -= secondsSince;
                adjustment.lastAdjustment = time_;
            } else {
                adjustment.active = false;
            }
        }

        // Price is not allowed to be lower than the minimum price
        marketPrice_ = _currentMarketPrice(id_);
        uint256 minPrice = market.minPrice;
        if (marketPrice_ < minPrice) marketPrice_ = minPrice;

        // Payout for the deposit = amount / price
        //
        // where:
        // payout = payout tokens out
        // amount = quote tokens in
        // price = quote tokens : payout token (i.e. 200 QUOTE : BASE), adjusted for scaling
        payout_ = amount_.mulDiv(market.scale, marketPrice_);

        // Cache storage variables to memory
        uint256 debtDecayInterval = uint256(metadata[id_].debtDecayInterval);
        uint256 lastTuneDebt = metadata[id_].lastTuneDebt;
        uint256 lastDecay = uint256(metadata[id_].lastDecay);

        // Set last decay timestamp based on size of purchase to linearize decay
        uint256 lastDecayIncrement = debtDecayInterval.mulDiv(payout_, lastTuneDebt);
        metadata[id_].lastDecay += uint48(lastDecayIncrement);

        // Update total debt following the purchase
        // Goal is to have the same decayed debt post-purchase as pre-purchase so that price is the same as before purchase and then add new debt to increase price
        // 1. Adjust total debt so that decayed debt is equal to the current debt after updating the last decay timestamp.
        //    This is the currentDebt function solved for totalDebt and adding lastDecayIncrement (the number of seconds lastDecay moves forward in time)
        //    to the number of seconds used to calculate the previous currentDebt.
        // 2. Add the payout to the total debt to increase the price.
        uint256 decayOffset = time_ > lastDecay
            ? (
                debtDecayInterval > (time_ - lastDecay)
                    ? debtDecayInterval - (time_ - lastDecay)
                    : 0
            )
            : debtDecayInterval + (lastDecay - time_);
        markets[id_].totalDebt =
            decayedDebt.mulDiv(debtDecayInterval, decayOffset + lastDecayIncrement) +
            payout_ +
            1; // add 1 to satisfy price inequality
    }

    /// @notice             Auto-adjust control variable to hit capacity/spend target
    /// @param id_          ID of market
    /// @param time_        Timestamp (saves gas when passed in)
    /// @param price_       Current price of the market
    function _tune(
        uint256 id_,
        uint48 time_,
        uint256 price_
    ) internal {
        BondMetadata memory meta = metadata[id_];
        BondMarket memory market = markets[id_];

        // Market tunes in 2 situations:
        // 1. If capacity has exceeded target since last tune adjustment and the market is oversold
        // 2. If a tune interval has passed since last tune adjustment and the market is undersold
        //
        // Intuition:
        // Markets are created with a target capacity with the expectation that capacity will
        // be utilized evenly over the duration of the market.
        // The intuition with tuning is:
        // - When the market is ahead of target capacity, we should tune based on capacity.
        // - When the market is behind target capacity, we should tune based on time.

        // Compute seconds remaining until market will conclude
        uint256 timeRemaining = uint256(terms[id_].conclusion - time_);

        // Standardize capacity into an payout token amount
        uint256 capacity = market.capacityInQuote
            ? market.capacity.mulDiv(market.scale, price_)
            : market.capacity;
        // Calculate initial capacity based on remaining capacity and amount sold/purchased up to this point
        uint256 initialCapacity = capacity +
            (market.capacityInQuote ? market.purchased.mulDiv(market.scale, price_) : market.sold);

        // Calculate timeNeutralCapacity as the capacity expected to be sold up to this point and the current capacity
        // Higher than initial capacity means the market is undersold, lower than initial capacity means the market is oversold
        uint256 timeNeutralCapacity = initialCapacity.mulDiv(
            uint256(meta.length) - timeRemaining,
            uint256(meta.length)
        ) + capacity;

        if (
            (market.capacity < meta.tuneBelowCapacity && timeNeutralCapacity < initialCapacity) ||
            (time_ >= meta.lastTune + meta.tuneInterval && timeNeutralCapacity > initialCapacity)
        ) {
            // Calculate the correct payout to complete on time assuming each bond
            // will be max size in the desired deposit interval for the remaining time
            //
            // i.e. market has 10 days remaining. deposit interval is 1 day. capacity
            // is 10,000 TOKEN. max payout would be 1,000 TOKEN (10,000 * 1 / 10).
            markets[id_].maxPayout = capacity.mulDiv(uint256(meta.depositInterval), timeRemaining);

            // Calculate ideal target debt to satisty capacity in the remaining time
            // The target debt is based on whether the market is under or oversold at this point in time
            // This target debt will ensure price is reactive while ensuring the magnitude of being over/undersold
            // doesn't cause larger fluctuations towards the end of the market.
            //

            // Calculate target debt from the timeNeutralCapacity and the ratio of debt decay interval and the length of the market
            uint256 targetDebt = timeNeutralCapacity.mulDiv(
                uint256(meta.debtDecayInterval),
                uint256(meta.length)
            );

            // Derive a new control variable from the target debt
            uint256 controlVariable = terms[id_].controlVariable;
            uint256 newControlVariable = price_.mulDivUp(market.scale, targetDebt);

            emit Tuned(id_, controlVariable, newControlVariable);

            if (newControlVariable < controlVariable) {
                // If decrease, control variable change will be carried out over the tune interval
                // this is because price will be lowered
                uint256 change = controlVariable - newControlVariable;
                adjustments[id_] = Adjustment(change, time_, meta.tuneAdjustmentDelay, true);
            } else {
                // Tune up immediately
                terms[id_].controlVariable = newControlVariable;
                // Set current adjustment to inactive (e.g. if we are re-tuning early)
                adjustments[id_].active = false;
            }

            metadata[id_].lastTune = time_;
            metadata[id_].tuneBelowCapacity = market.capacity > meta.tuneIntervalCapacity
                ? market.capacity - meta.tuneIntervalCapacity
                : 0;
            metadata[id_].lastTuneDebt = targetDebt;
        }
    }

    /* ========== INTERNAL VIEW FUNCTIONS ========== */

    /// @notice             Calculate current market price of payout token in quote tokens
    /// @dev                See marketPrice() in IBondAuctioneer for explanation of price computation
    /// @dev                Uses info from storage because data has been updated before call (vs marketPrice())
    /// @param id_          Market ID
    /// @return             Price for market in payout token decimals
    function _currentMarketPrice(uint256 id_) internal view returns (uint256) {
        BondMarket memory market = markets[id_];
        return terms[id_].controlVariable.mulDiv(market.totalDebt, market.scale);
    }

    /// @notice                 Amount to decay control variable by
    /// @param id_              ID of market
    /// @return decay           change in control variable
    /// @return secondsSince    seconds since last change in control variable
    /// @return active          whether or not change remains active
    function _controlDecay(uint256 id_)
        internal
        view
        returns (
            uint256 decay,
            uint48 secondsSince,
            bool active
        )
    {
        Adjustment memory info = adjustments[id_];
        if (!info.active) return (0, 0, false);

        secondsSince = uint48(block.timestamp) - info.lastAdjustment;
        active = secondsSince < info.timeToAdjusted;
        decay = active
            ? info.change.mulDiv(uint256(secondsSince), uint256(info.timeToAdjusted))
            : info.change;
    }

    /* ========== EXTERNAL VIEW FUNCTIONS ========== */

    /// @inheritdoc IBondAuctioneer
    function getMarketInfoForPurchase(uint256 id_)
        external
        view
        returns (
            address owner,
            address callbackAddr,
            ERC20 payoutToken,
            ERC20 quoteToken,
            uint48 vesting,
            uint256 maxPayout
        )
    {
        BondMarket memory market = markets[id_];
        return (
            market.owner,
            market.callbackAddr,
            market.payoutToken,
            market.quoteToken,
            terms[id_].vesting,
            market.maxPayout
        );
    }

    /// @inheritdoc IBondSDA
    function marketPrice(uint256 id_) public view override returns (uint256) {
        uint256 price = currentControlVariable(id_).mulDivUp(currentDebt(id_), markets[id_].scale);

        return (price > markets[id_].minPrice) ? price : markets[id_].minPrice;
    }

    /// @inheritdoc IBondAuctioneer
    function marketScale(uint256 id_) external view override returns (uint256) {
        return markets[id_].scale;
    }

    /// @inheritdoc IBondAuctioneer
    function payoutFor(
        uint256 amount_,
        uint256 id_,
        address referrer_
    ) public view override returns (uint256) {
        // Calculate the payout for the given amount of tokens
        uint256 fee = amount_.mulDiv(_teller.getFee(referrer_), 1e5);
        uint256 payout = (amount_ - fee).mulDiv(markets[id_].scale, marketPrice(id_));

        // Check that the payout is less than or equal to the maximum payout,
        // Revert if not, otherwise return the payout
        if (payout > markets[id_].maxPayout) {
            revert Auctioneer_MaxPayoutExceeded();
        } else {
            return payout;
        }
    }

    /// @inheritdoc IBondAuctioneer
    function maxAmountAccepted(uint256 id_, address referrer_) external view returns (uint256) {
        // Calculate maximum amount of quote tokens that correspond to max bond size
        // Maximum of the maxPayout and the remaining capacity converted to quote tokens
        BondMarket memory market = markets[id_];
        uint256 price = marketPrice(id_);
        uint256 quoteCapacity = market.capacityInQuote
            ? market.capacity
            : market.capacity.mulDiv(price, market.scale);
        uint256 maxQuote = market.maxPayout.mulDiv(price, market.scale);
        uint256 amountAccepted = quoteCapacity < maxQuote ? quoteCapacity : maxQuote;

        // Take into account teller fees and return
        // Estimate fee based on amountAccepted. Fee taken will be slightly larger than
        // this given it will be taken off the larger amount, but this avoids rounding
        // errors with trying to calculate the exact amount.
        // Therefore, the maxAmountAccepted is slightly conservative.
        uint256 estimatedFee = amountAccepted.mulDiv(_teller.getFee(referrer_), 1e5);

        return amountAccepted + estimatedFee;
    }

    /// @inheritdoc IBondSDA
    function currentDebt(uint256 id_) public view override returns (uint256) {
        BondMetadata memory meta = metadata[id_];
        uint256 lastDecay = uint256(meta.lastDecay);
        uint256 currentTime = block.timestamp;

        // Determine if decay should increase or decrease debt based on last decay time
        // If last decay time is in the future, then debt should be increased
        // If last decay time is in the past, then debt should be decreased
        if (lastDecay > currentTime) {
            uint256 secondsUntil;
            unchecked {
                secondsUntil = lastDecay - currentTime;
            }
            return
                markets[id_].totalDebt.mulDiv(
                    uint256(meta.debtDecayInterval) + secondsUntil,
                    uint256(meta.debtDecayInterval)
                );
        } else {
            uint256 secondsSince;
            unchecked {
                secondsSince = currentTime - lastDecay;
            }
            return
                secondsSince > meta.debtDecayInterval
                    ? 0
                    : markets[id_].totalDebt.mulDiv(
                        uint256(meta.debtDecayInterval) - secondsSince,
                        uint256(meta.debtDecayInterval)
                    );
        }
    }

    /// @inheritdoc IBondSDA
    function currentControlVariable(uint256 id_) public view override returns (uint256) {
        (uint256 decay, , ) = _controlDecay(id_);
        return terms[id_].controlVariable - decay;
    }

    /// @inheritdoc IBondAuctioneer
    function isInstantSwap(uint256 id_) public view returns (bool) {
        uint256 vesting = terms[id_].vesting;
        return (vesting <= MAX_FIXED_TERM) ? vesting == 0 : vesting <= block.timestamp;
    }

    /// @inheritdoc IBondAuctioneer
    function isLive(uint256 id_) public view override returns (bool) {
        return (markets[id_].capacity != 0 && terms[id_].conclusion > block.timestamp);
    }

    /// @inheritdoc IBondAuctioneer
    function ownerOf(uint256 id_) external view override returns (address) {
        return markets[id_].owner;
    }

    /// @inheritdoc IBondAuctioneer
    function getTeller() external view override returns (IBondTeller) {
        return _teller;
    }

    /// @inheritdoc IBondAuctioneer
    function getAggregator() external view override returns (IBondAggregator) {
        return _aggregator;
    }

    /// @inheritdoc IBondAuctioneer
    function currentCapacity(uint256 id_) external view override returns (uint256) {
        return markets[id_].capacity;
    }
}