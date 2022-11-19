// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.15;

import {ReentrancyGuard} from "solmate/utils/ReentrancyGuard.sol";
import {ERC20} from "solmate/tokens/ERC20.sol";

import {TransferHelper} from "libraries/TransferHelper.sol";
import {FullMath} from "libraries/FullMath.sol";

import {IOperator} from "policies/interfaces/IOperator.sol";
import {IBondCallback} from "interfaces/IBondCallback.sol";
import {IBondSDA} from "interfaces/IBondSDA.sol";

import {RolesConsumer} from "modules/ROLES/OlympusRoles.sol";
import {ROLESv1} from "modules/ROLES/ROLES.v1.sol";
import {TRSRYv1} from "modules/TRSRY/TRSRY.v1.sol";
import {MINTRv1} from "modules/MINTR/MINTR.v1.sol";
import {PRICEv1} from "modules/PRICE/PRICE.v1.sol";
import {RANGEv1} from "modules/RANGE/RANGE.v1.sol";

import "src/Kernel.sol";

/// @title  Olympus Range Operator
/// @notice Olympus Range Operator (Policy) Contract
/// @dev    The Olympus Range Operator performs market operations to enforce OlympusDAO's OHM price range
///         guidance policies against a specific reserve asset. The Operator is maintained by a keeper-triggered
///         function on the Olympus Heart contract, which orchestrates state updates in the correct order to ensure
///         market operations use up to date information. When the price of OHM against the reserve asset exceeds
///         the cushion spread, the Operator deploys bond markets to support the price. The Operator also offers
///         zero slippage swaps at prices dictated by the wall spread from the moving average. These market operations
///         are performed up to a specific capacity before the market must stabilize to regenerate the capacity.
contract Operator is IOperator, Policy, RolesConsumer, ReentrancyGuard {
    using TransferHelper for ERC20;
    using FullMath for uint256;

    // =========  STATE ========= //

    // Operator variables, defined in the interface on the external getter functions
    Status internal _status;
    Config internal _config;

    /// @notice Whether the Operator has been initialized
    bool public initialized;

    /// @notice    Whether the Operator is active
    bool public active;

    // Modules
    PRICEv1 internal PRICE;
    RANGEv1 internal RANGE;
    TRSRYv1 internal TRSRY;
    MINTRv1 internal MINTR;

    // External contracts
    /// @notice Auctioneer contract used for cushion bond market deployments
    IBondSDA public auctioneer;
    /// @notice Callback contract used for cushion bond market payouts
    IBondCallback public callback;

    // Tokens
    /// @notice OHM token contract
    ERC20 public immutable ohm;
    uint8 public immutable ohmDecimals;
    /// @notice Reserve token contract
    ERC20 public immutable reserve;
    uint8 public immutable reserveDecimals;

    // Constants
    uint32 public constant ONE_HUNDRED_PERCENT = 100e2;
    uint32 public constant ONE_PERCENT = 1e2;

    //============================================================================================//
    //                                      POLICY SETUP                                          //
    //============================================================================================//

    constructor(
        Kernel kernel_,
        IBondSDA auctioneer_,
        IBondCallback callback_,
        ERC20[2] memory tokens_, // [ohm, reserve]
        uint32[8] memory configParams // [cushionFactor, cushionDuration, cushionDebtBuffer, cushionDepositInterval, reserveFactor, regenWait, regenThreshold, regenObserve] ensure the following holds: regenWait / PRICE.observationFrequency() >= regenObserve - regenThreshold
    ) Policy(kernel_) {
        // Check params are valid
        if (address(auctioneer_) == address(0) || address(callback_) == address(0))
            revert Operator_InvalidParams();

        if (configParams[1] > uint256(7 days) || configParams[1] < uint256(1 days))
            revert Operator_InvalidParams();

        if (configParams[2] < uint32(10e3)) revert Operator_InvalidParams();

        if (configParams[3] < uint32(1 hours) || configParams[3] > configParams[1])
            revert Operator_InvalidParams();

        if (configParams[0] > ONE_HUNDRED_PERCENT || configParams[0] < ONE_PERCENT)
            revert Operator_InvalidParams();

        if (configParams[4] > ONE_HUNDRED_PERCENT || configParams[4] < ONE_PERCENT)
            revert Operator_InvalidParams();

        if (
            configParams[5] < 1 hours ||
            configParams[6] > configParams[7] ||
            configParams[7] == uint32(0) ||
            configParams[6] == uint32(0)
        ) revert Operator_InvalidParams();

        auctioneer = auctioneer_;
        callback = callback_;
        ohm = tokens_[0];
        ohmDecimals = tokens_[0].decimals();
        reserve = tokens_[1];
        reserveDecimals = tokens_[1].decimals();

        Regen memory regen = Regen({
            count: uint32(0),
            lastRegen: uint48(block.timestamp),
            nextObservation: uint32(0),
            observations: new bool[](configParams[7])
        });

        _config = Config({
            cushionFactor: configParams[0],
            cushionDuration: configParams[1],
            cushionDebtBuffer: configParams[2],
            cushionDepositInterval: configParams[3],
            reserveFactor: configParams[4],
            regenWait: configParams[5],
            regenThreshold: configParams[6],
            regenObserve: configParams[7]
        });

        _status = Status({low: regen, high: regen});

        emit CushionFactorChanged(configParams[0]);
        emit CushionParamsChanged(configParams[1], configParams[2], configParams[3]);
        emit ReserveFactorChanged(configParams[4]);
        emit RegenParamsChanged(configParams[5], configParams[6], configParams[7]);
    }

    /// @inheritdoc Policy
    function configureDependencies() external override returns (Keycode[] memory dependencies) {
        dependencies = new Keycode[](5);
        dependencies[0] = toKeycode("PRICE");
        dependencies[1] = toKeycode("RANGE");
        dependencies[2] = toKeycode("TRSRY");
        dependencies[3] = toKeycode("MINTR");
        dependencies[4] = toKeycode("ROLES");

        PRICE = PRICEv1(getModuleAddress(dependencies[0]));
        RANGE = RANGEv1(getModuleAddress(dependencies[1]));
        TRSRY = TRSRYv1(getModuleAddress(dependencies[2]));
        MINTR = MINTRv1(getModuleAddress(dependencies[3]));
        ROLES = ROLESv1(getModuleAddress(dependencies[4]));

        // Approve MINTR for burning OHM (called here so that it is re-approved on updates)
        ohm.safeApprove(address(MINTR), type(uint256).max);
    }

    /// @inheritdoc Policy
    function requestPermissions() external view override returns (Permissions[] memory requests) {
        Keycode RANGE_KEYCODE = RANGE.KEYCODE();
        Keycode TRSRY_KEYCODE = TRSRY.KEYCODE();
        Keycode MINTR_KEYCODE = MINTR.KEYCODE();

        requests = new Permissions[](13);
        requests[0] = Permissions(RANGE_KEYCODE, RANGE.updateCapacity.selector);
        requests[1] = Permissions(RANGE_KEYCODE, RANGE.updateMarket.selector);
        requests[2] = Permissions(RANGE_KEYCODE, RANGE.updatePrices.selector);
        requests[3] = Permissions(RANGE_KEYCODE, RANGE.regenerate.selector);
        requests[4] = Permissions(RANGE_KEYCODE, RANGE.setSpreads.selector);
        requests[5] = Permissions(RANGE_KEYCODE, RANGE.setThresholdFactor.selector);
        requests[6] = Permissions(TRSRY_KEYCODE, TRSRY.withdrawReserves.selector);
        requests[7] = Permissions(TRSRY_KEYCODE, TRSRY.increaseWithdrawApproval.selector);
        requests[8] = Permissions(TRSRY_KEYCODE, TRSRY.decreaseWithdrawApproval.selector);
        requests[9] = Permissions(MINTR_KEYCODE, MINTR.mintOhm.selector);
        requests[10] = Permissions(MINTR_KEYCODE, MINTR.burnOhm.selector);
        requests[11] = Permissions(MINTR_KEYCODE, MINTR.increaseMintApproval.selector);
        requests[12] = Permissions(MINTR_KEYCODE, MINTR.decreaseMintApproval.selector);
    }

    //============================================================================================//
    //                                       CORE FUNCTIONS                                       //
    //============================================================================================//

    /// @dev Checks to see if the policy is active and ensures the range data isn't stale before performing market operations.
    ///      This check is different from the price feed staleness checks in the PRICE module.
    ///      The PRICE module checks new price feed data for staleness when storing a new observations,
    ///      whereas this check ensures that the range data is using a recent observation.
    modifier onlyWhileActive() {
        if (
            !active ||
            uint48(block.timestamp) > PRICE.lastObservationTime() + 3 * PRICE.observationFrequency()
        ) revert Operator_Inactive();
        _;
    }

    // =========  HEART FUNCTIONS ========= //

    /// @inheritdoc IOperator
    function operate() external override onlyWhileActive onlyRole("operator_operate") {
        // Revert if not initialized
        if (!initialized) revert Operator_NotInitialized();

        // Update the prices for the range, save new regen observations, and update capacities based on bond market activity
        _updateRangePrices();
        _addObservation();

        // Cache config in memory
        Config memory config_ = _config;

        // Check if walls can regenerate capacity
        if (
            uint48(block.timestamp) >= RANGE.lastActive(true) + uint48(config_.regenWait) &&
            _status.high.count >= config_.regenThreshold
        ) {
            _regenerate(true);
        }
        if (
            uint48(block.timestamp) >= RANGE.lastActive(false) + uint48(config_.regenWait) &&
            _status.low.count >= config_.regenThreshold
        ) {
            _regenerate(false);
        }

        // Cache range data after potential regeneration
        RANGEv1.Range memory range = RANGE.range();

        // Get latest price
        // See note in addObservation() for more details
        uint256 currentPrice = PRICE.getLastPrice();

        // Check if the cushion bond markets are active
        // if so, determine if it should stay open or close
        // if not, check if a new one should be opened
        if (range.low.active) {
            if (auctioneer.isLive(range.low.market)) {
                // if active, check if the price is back above the cushion
                // or if the price is below the wall
                // if so, close the market
                if (currentPrice > range.cushion.low.price || currentPrice < range.wall.low.price) {
                    _deactivate(false);
                }
            } else {
                // if not active, check if the price is below the cushion
                // if so, open a new bond market
                if (currentPrice < range.cushion.low.price && currentPrice > range.wall.low.price) {
                    _activate(false);
                }
            }
        }
        if (range.high.active) {
            if (auctioneer.isLive(range.high.market)) {
                // if active, check if the price is back under the cushion
                // or if the price is above the wall
                // if so, close the market
                if (
                    currentPrice < range.cushion.high.price || currentPrice > range.wall.high.price
                ) {
                    _deactivate(true);
                }
            } else {
                // if not active, check if the price is above the cushion
                // if so, open a new bond market
                if (
                    currentPrice > range.cushion.high.price && currentPrice < range.wall.high.price
                ) {
                    _activate(true);
                }
            }
        }
    }

    // =========  OPEN MARKET OPERATIONS (WALL) ========= //

    /// @inheritdoc IOperator
    function swap(
        ERC20 tokenIn_,
        uint256 amountIn_,
        uint256 minAmountOut_
    ) external override onlyWhileActive nonReentrant returns (uint256 amountOut) {
        if (tokenIn_ == ohm) {
            // Revert if lower wall is inactive
            if (!RANGE.active(false)) revert Operator_WallDown();

            // Calculate amount out (checks for sufficient capacity)
            amountOut = getAmountOut(tokenIn_, amountIn_);

            // Revert if amount out less than the minimum specified
            /// @dev even though price is fixed most of the time,
            /// it is possible that the amount out could change on a sender
            /// due to the wall prices being updated before their transaction is processed.
            /// This would be the equivalent of the heart.beat front-running the sender.
            if (amountOut < minAmountOut_)
                revert Operator_AmountLessThanMinimum(amountOut, minAmountOut_);

            // Decrement wall capacity
            _updateCapacity(false, amountOut);

            // If wall is down after swap, deactive the cushion as well
            _checkCushion(false);

            // Transfer OHM from sender
            ohm.safeTransferFrom(msg.sender, address(this), amountIn_);

            // Burn OHM
            MINTR.burnOhm(address(this), amountIn_);

            // Withdraw and transfer reserve to sender
            TRSRY.withdrawReserves(msg.sender, reserve, amountOut);

            emit Swap(ohm, reserve, amountIn_, amountOut);
        } else if (tokenIn_ == reserve) {
            // Revert if upper wall is inactive
            if (!RANGE.active(true)) revert Operator_WallDown();

            // Calculate amount out (checks for sufficient capacity)
            amountOut = getAmountOut(tokenIn_, amountIn_);

            // Revert if amount out less than the minimum specified
            /// @dev even though price is fixed most of the time,
            /// it is possible that the amount out could change on a sender
            /// due to the wall prices being updated before their transaction is processed.
            /// This would be the equivalent of the heart.beat front-running the sender.
            if (amountOut < minAmountOut_)
                revert Operator_AmountLessThanMinimum(amountOut, minAmountOut_);

            // Decrement wall capacity
            _updateCapacity(true, amountOut);

            // If wall is down after swap, deactive the cushion as well
            _checkCushion(true);

            // Transfer reserves to treasury
            reserve.safeTransferFrom(msg.sender, address(TRSRY), amountIn_);

            // Mint OHM to sender
            MINTR.mintOhm(msg.sender, amountOut);

            emit Swap(reserve, ohm, amountIn_, amountOut);
        } else {
            revert Operator_InvalidParams();
        }
    }

    // =========  BOND MARKET OPERATIONS (CUSHION) ========= //

    /// @notice             Records a bond purchase and updates capacity correctly
    /// @notice             Access restricted (BondCallback)
    /// @param id_          ID of the bond market
    /// @param amountOut_   Amount of capacity expended
    function bondPurchase(uint256 id_, uint256 amountOut_)
        external
        onlyWhileActive
        onlyRole("operator_reporter")
    {
        if (id_ == RANGE.market(true)) {
            _updateCapacity(true, amountOut_);
            _checkCushion(true);
        }
        if (id_ == RANGE.market(false)) {
            _updateCapacity(false, amountOut_);
            _checkCushion(false);
        }
    }

    /// @notice      Activate a cushion by deploying a bond market
    /// @param high_ Whether the cushion is for the high or low side of the range (true = high, false = low)
    function _activate(bool high_) internal {
        RANGEv1.Range memory range = RANGE.range();

        if (high_) {
            // Calculate scaleAdjustment for bond market
            // Price decimals are returned from the perspective of the quote token
            // so the operations assume payoutPriceDecimal is zero and quotePriceDecimals
            // is the priceDecimal value
            int8 priceDecimals = _getPriceDecimals(range.cushion.high.price);
            int8 scaleAdjustment = int8(ohmDecimals) - int8(reserveDecimals) + (priceDecimals / 2);

            // Calculate oracle scale and bond scale with scale adjustment and format prices for bond market
            uint256 oracleScale = 10**uint8(int8(PRICE.decimals()) - priceDecimals);
            uint256 bondScale = 10 **
                uint8(
                    36 + scaleAdjustment + int8(reserveDecimals) - int8(ohmDecimals) - priceDecimals
                );

            uint256 initialPrice = PRICE.getLastPrice().mulDiv(bondScale, oracleScale);
            uint256 minimumPrice = range.cushion.high.price.mulDiv(bondScale, oracleScale);

            // Cache config struct to avoid multiple SLOADs
            Config memory config_ = _config;

            // Calculate market capacity from the cushion factor
            uint256 marketCapacity = range.high.capacity.mulDiv(
                config_.cushionFactor,
                ONE_HUNDRED_PERCENT
            );

            // Create new bond market to buy the reserve with OHM
            IBondSDA.MarketParams memory params = IBondSDA.MarketParams({
                payoutToken: ohm,
                quoteToken: reserve,
                callbackAddr: address(callback),
                capacityInQuote: false,
                capacity: marketCapacity,
                formattedInitialPrice: initialPrice,
                formattedMinimumPrice: minimumPrice,
                debtBuffer: config_.cushionDebtBuffer,
                vesting: uint48(0), // Instant swaps
                conclusion: uint48(block.timestamp + config_.cushionDuration),
                depositInterval: config_.cushionDepositInterval,
                scaleAdjustment: scaleAdjustment
            });

            uint256 market = auctioneer.createMarket(abi.encode(params));

            // Whitelist the bond market on the callback
            callback.whitelist(address(auctioneer.getTeller()), market);

            // Update the market information on the range module
            RANGE.updateMarket(true, market, marketCapacity);
        } else {
            // Calculate inverse prices from the oracle feed for the low side
            uint8 oracleDecimals = PRICE.decimals();
            uint256 invCushionPrice = 10**(oracleDecimals * 2) / range.cushion.low.price;
            uint256 invCurrentPrice = 10**(oracleDecimals * 2) / PRICE.getLastPrice();

            // Calculate scaleAdjustment for bond market
            // Price decimals are returned from the perspective of the quote token
            // so the operations assume payoutPriceDecimal is zero and quotePriceDecimals
            // is the priceDecimal value
            int8 priceDecimals = _getPriceDecimals(invCushionPrice);
            int8 scaleAdjustment = int8(reserveDecimals) - int8(ohmDecimals) + (priceDecimals / 2);

            // Calculate oracle scale and bond scale with scale adjustment and format prices for bond market
            uint256 oracleScale = 10**uint8(int8(oracleDecimals) - priceDecimals);
            uint256 bondScale = 10 **
                uint8(
                    36 + scaleAdjustment + int8(ohmDecimals) - int8(reserveDecimals) - priceDecimals
                );

            uint256 initialPrice = invCurrentPrice.mulDiv(bondScale, oracleScale);
            uint256 minimumPrice = invCushionPrice.mulDiv(bondScale, oracleScale);

            // Cache config struct to avoid multiple SLOADs
            Config memory config_ = _config;

            // Calculate market capacity from the cushion factor
            uint256 marketCapacity = range.low.capacity.mulDiv(
                config_.cushionFactor,
                ONE_HUNDRED_PERCENT
            );

            // Create new bond market to buy OHM with the reserve
            IBondSDA.MarketParams memory params = IBondSDA.MarketParams({
                payoutToken: reserve,
                quoteToken: ohm,
                callbackAddr: address(callback),
                capacityInQuote: false,
                capacity: marketCapacity,
                formattedInitialPrice: initialPrice,
                formattedMinimumPrice: minimumPrice,
                debtBuffer: config_.cushionDebtBuffer,
                vesting: uint48(0), // Instant swaps
                conclusion: uint48(block.timestamp + config_.cushionDuration),
                depositInterval: config_.cushionDepositInterval,
                scaleAdjustment: scaleAdjustment
            });

            uint256 market = auctioneer.createMarket(abi.encode(params));

            // Whitelist the bond market on the callback
            callback.whitelist(address(auctioneer.getTeller()), market);

            // Update the market information on the range module
            RANGE.updateMarket(false, market, marketCapacity);
        }
    }

    /// @notice      Deactivate a cushion by closing a bond market (if it is active)
    /// @param high_ Whether the cushion is for the high or low side of the range (true = high, false = low)
    function _deactivate(bool high_) internal {
        uint256 market = RANGE.market(high_);
        if (auctioneer.isLive(market)) {
            auctioneer.closeMarket(market);
            RANGE.updateMarket(high_, type(uint256).max, 0);
        }
    }

    /// @notice         Helper function to calculate number of price decimals based on the value returned from the price feed.
    /// @param price_   The price to calculate the number of decimals for
    /// @return         The number of decimals
    function _getPriceDecimals(uint256 price_) internal view returns (int8) {
        int8 decimals;
        while (price_ >= 10) {
            price_ = price_ / 10;
            decimals++;
        }

        // Subtract the stated decimals from the calculated decimals to get the relative price decimals.
        // Required to do it this way vs. normalizing at the beginning since price decimals can be negative.
        return decimals - int8(PRICE.decimals());
    }

    // =========  INTERNAL FUNCTIONS ========= //

    /// @notice          Update the capacity on the RANGE module.
    /// @param high_     Whether to update the high side or low side capacity (true = high, false = low).
    /// @param reduceBy_ The amount to reduce the capacity by (OHM tokens for high side, Reserve tokens for low side).
    function _updateCapacity(bool high_, uint256 reduceBy_) internal {
        // Initialize update variables, decrement capacity if a reduceBy amount is provided
        uint256 capacity = RANGE.capacity(high_) - reduceBy_;

        // Update capacities on the range module for the wall and market
        RANGE.updateCapacity(high_, capacity);
    }

    /// @notice Update the prices on the RANGE module
    function _updateRangePrices() internal {
        // Get latest moving average from the price module
        uint256 movingAverage = PRICE.getMovingAverage();

        // Update the prices on the range module
        RANGE.updatePrices(movingAverage);
    }

    /// @notice Add an observation to the regeneration status variables for each side
    function _addObservation() internal {
        // Get latest moving average from the price module
        uint256 movingAverage = PRICE.getMovingAverage();

        // Get price from latest update
        uint256 currentPrice = PRICE.getLastPrice();

        // Store observations and update counts for regeneration

        // Update low side regen status with a new observation
        // Observation is positive if the current price is greater than the MA
        uint32 observe = _config.regenObserve;
        Regen memory regen = _status.low;
        if (currentPrice >= movingAverage) {
            if (!regen.observations[regen.nextObservation]) {
                _status.low.observations[regen.nextObservation] = true;
                _status.low.count++;
            }
        } else {
            if (regen.observations[regen.nextObservation]) {
                _status.low.observations[regen.nextObservation] = false;
                _status.low.count--;
            }
        }
        _status.low.nextObservation = (regen.nextObservation + 1) % observe;

        // Update high side regen status with a new observation
        // Observation is positive if the current price is less than the MA
        regen = _status.high;
        if (currentPrice <= movingAverage) {
            if (!regen.observations[regen.nextObservation]) {
                _status.high.observations[regen.nextObservation] = true;
                _status.high.count++;
            }
        } else {
            if (regen.observations[regen.nextObservation]) {
                _status.high.observations[regen.nextObservation] = false;
                _status.high.count--;
            }
        }
        _status.high.nextObservation = (regen.nextObservation + 1) % observe;
    }

    /// @notice      Regenerate the wall for a side
    /// @param high_ Whether to regenerate the high side or low side (true = high, false = low)
    function _regenerate(bool high_) internal {
        // Deactivate cushion if active on the side being regenerated
        _deactivate(high_);

        if (high_) {
            // Reset the regeneration data for the side
            _status.high.count = uint32(0);
            _status.high.observations = new bool[](_config.regenObserve);
            _status.high.nextObservation = uint32(0);
            _status.high.lastRegen = uint48(block.timestamp);

            // Calculate capacity
            uint256 capacity = fullCapacity(true);

            // Get approval from MINTR to mint OHM up to the capacity
            // If current approval is higher than the capacity, reduce it
            uint256 currentApproval = MINTR.mintApproval(address(this));
            if (currentApproval < capacity) {
                MINTR.increaseMintApproval(address(this), capacity - currentApproval);
            } else if (currentApproval > capacity) {
                MINTR.decreaseMintApproval(address(this), currentApproval - capacity);
            }

            // Regenerate the side with the capacity
            RANGE.regenerate(true, capacity);
        } else {
            // Reset the regeneration data for the side
            _status.low.count = uint32(0);
            _status.low.observations = new bool[](_config.regenObserve);
            _status.low.nextObservation = uint32(0);
            _status.low.lastRegen = uint48(block.timestamp);

            // Calculate capacity
            uint256 capacity = fullCapacity(false);

            // Get approval from the TRSRY to withdraw up to the capacity in reserves
            // If current approval is higher than the capacity, reduce it
            uint256 currentApproval = TRSRY.withdrawApproval(address(this), reserve);
            if (currentApproval < capacity) {
                TRSRY.increaseWithdrawApproval(address(this), reserve, capacity - currentApproval);
            } else if (currentApproval > capacity) {
                TRSRY.decreaseWithdrawApproval(address(this), reserve, currentApproval - capacity);
            }

            // Regenerate the side with the capacity
            RANGE.regenerate(false, capacity);
        }
    }

    /// @notice      Takes down cushions (if active) when a wall is taken down or if available capacity drops below cushion capacity
    /// @param high_ Whether to check the high side or low side cushion (true = high, false = low)
    function _checkCushion(bool high_) internal {
        // Check if the wall is down, if so ensure the cushion is also down
        // Additionally, if wall is not down, but the wall capacity has dropped below the cushion capacity, take the cushion down
        bool sideActive = RANGE.active(high_);
        uint256 market = RANGE.market(high_);
        if (
            !sideActive ||
            (sideActive &&
                auctioneer.isLive(market) &&
                RANGE.capacity(high_) < auctioneer.currentCapacity(market))
        ) {
            _deactivate(high_);
        }
    }

    //============================================================================================//
    //                                      ADMIN FUNCTIONS                                       //
    //============================================================================================//

    /// @inheritdoc IOperator
    function setSpreads(uint256 cushionSpread_, uint256 wallSpread_)
        external
        onlyRole("operator_policy")
    {
        // Set spreads on the range module
        RANGE.setSpreads(cushionSpread_, wallSpread_);

        // Update range prices (wall and cushion)
        _updateRangePrices();
    }

    /// @inheritdoc IOperator
    function setThresholdFactor(uint256 thresholdFactor_) external onlyRole("operator_policy") {
        // Set threshold factor on the range module
        RANGE.setThresholdFactor(thresholdFactor_);
    }

    /// @inheritdoc IOperator
    function setCushionFactor(uint32 cushionFactor_) external onlyRole("operator_policy") {
        // Confirm factor is within allowed values
        if (cushionFactor_ > ONE_HUNDRED_PERCENT || cushionFactor_ < ONE_PERCENT)
            revert Operator_InvalidParams();

        // Set factor
        _config.cushionFactor = cushionFactor_;

        emit CushionFactorChanged(cushionFactor_);
    }

    /// @inheritdoc IOperator
    function setCushionParams(
        uint32 duration_,
        uint32 debtBuffer_,
        uint32 depositInterval_
    ) external onlyRole("operator_policy") {
        // Confirm values are valid
        if (duration_ > uint256(7 days) || duration_ < uint256(1 days))
            revert Operator_InvalidParams();
        if (debtBuffer_ < uint32(10_000)) revert Operator_InvalidParams();
        if (depositInterval_ < uint32(1 hours) || depositInterval_ > duration_)
            revert Operator_InvalidParams();

        // Update values
        _config.cushionDuration = duration_;
        _config.cushionDebtBuffer = debtBuffer_;
        _config.cushionDepositInterval = depositInterval_;

        emit CushionParamsChanged(duration_, debtBuffer_, depositInterval_);
    }

    /// @inheritdoc IOperator
    function setReserveFactor(uint32 reserveFactor_) external onlyRole("operator_policy") {
        // Confirm factor is within allowed values
        if (reserveFactor_ > ONE_HUNDRED_PERCENT || reserveFactor_ < ONE_PERCENT)
            revert Operator_InvalidParams();

        // Set factor
        _config.reserveFactor = reserveFactor_;

        emit ReserveFactorChanged(reserveFactor_);
    }

    /// @inheritdoc IOperator
    function setRegenParams(
        uint32 wait_,
        uint32 threshold_,
        uint32 observe_
    ) external onlyRole("operator_policy") {
        // Confirm regen parameters are within allowed values
        if (
            wait_ < 1 hours ||
            threshold_ > observe_ ||
            observe_ == 0 ||
            threshold_ == 0 ||
            wait_ / PRICE.observationFrequency() < observe_ - threshold_
        ) revert Operator_InvalidParams();

        // Set regen params
        _config.regenWait = wait_;
        _config.regenThreshold = threshold_;
        _config.regenObserve = observe_;

        // Re-initialize regen structs with new values (except for last regen)
        _status.high.count = 0;
        _status.high.nextObservation = 0;
        _status.high.observations = new bool[](observe_);

        _status.low.count = 0;
        _status.low.nextObservation = 0;
        _status.low.observations = new bool[](observe_);

        emit RegenParamsChanged(wait_, threshold_, observe_);
    }

    /// @inheritdoc IOperator
    function setBondContracts(IBondSDA auctioneer_, IBondCallback callback_)
        external
        onlyRole("operator_policy")
    {
        if (address(auctioneer_) == address(0) || address(callback_) == address(0))
            revert Operator_InvalidParams();
        // Set contracts
        auctioneer = auctioneer_;
        callback = callback_;
    }

    /// @inheritdoc IOperator
    function initialize() external onlyRole("operator_admin") {
        // Can only call once
        if (initialized) revert Operator_AlreadyInitialized();

        // Update range prices (wall and cushion)
        _updateRangePrices();

        // Regenerate sides
        _regenerate(true);
        _regenerate(false);

        // Set initialized and active flags
        initialized = true;
        active = true;
    }

    /// @inheritdoc IOperator
    function regenerate(bool high_) external onlyRole("operator_admin") {
        // Regenerate side
        _regenerate(high_);
    }

    /// @inheritdoc IOperator
    function activate() external onlyRole("operator_policy") {
        active = true;
    }

    /// @inheritdoc IOperator
    function deactivate() external onlyRole("operator_policy") {
        active = false;
        // Deactivate cushions
        _deactivate(true);
        _deactivate(false);
    }

    /// @inheritdoc IOperator
    function deactivateCushion(bool high_) external onlyRole("operator_policy") {
        // Manually deactivate a cushion
        _deactivate(high_);
    }

    //============================================================================================//
    //                                       VIEW FUNCTIONS                                       //
    //============================================================================================//

    /// @inheritdoc IOperator
    function getAmountOut(ERC20 tokenIn_, uint256 amountIn_) public view returns (uint256) {
        if (tokenIn_ == ohm) {
            // Calculate amount out
            uint256 amountOut = amountIn_.mulDiv(
                10**reserveDecimals * RANGE.price(true, false),
                10**ohmDecimals * 10**PRICE.decimals()
            );

            // Revert if amount out exceeds capacity
            if (amountOut > RANGE.capacity(false)) revert Operator_InsufficientCapacity();

            return amountOut;
        } else if (tokenIn_ == reserve) {
            // Calculate amount out
            uint256 amountOut = amountIn_.mulDiv(
                10**ohmDecimals * 10**PRICE.decimals(),
                10**reserveDecimals * RANGE.price(true, true)
            );

            // Revert if amount out exceeds capacity
            if (amountOut > RANGE.capacity(true)) revert Operator_InsufficientCapacity();

            return amountOut;
        } else {
            revert Operator_InvalidParams();
        }
    }

    /// @inheritdoc IOperator
    function fullCapacity(bool high_) public view override returns (uint256) {
        uint256 reservesInTreasury = TRSRY.getReserveBalance(reserve);
        uint256 capacity = (reservesInTreasury * _config.reserveFactor) / ONE_HUNDRED_PERCENT;
        if (high_) {
            capacity =
                (capacity.mulDiv(
                    10**ohmDecimals * 10**PRICE.decimals(),
                    10**reserveDecimals * RANGE.price(true, true)
                ) * (ONE_HUNDRED_PERCENT + RANGE.spread(true) * 2)) /
                ONE_HUNDRED_PERCENT;
        }
        return capacity;
    }

    /// @inheritdoc IOperator
    function status() external view override returns (Status memory) {
        return _status;
    }

    /// @inheritdoc IOperator
    function config() external view override returns (Config memory) {
        return _config;
    }
}