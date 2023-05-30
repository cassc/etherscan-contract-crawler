// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.15;

import {ERC20} from "solmate/tokens/ERC20.sol";
import "src/Kernel.sol";

abstract contract RANGEv1 is Module {
    // =========  EVENTS ========= //

    event WallUp(bool high_, uint256 timestamp_, uint256 capacity_);
    event WallDown(bool high_, uint256 timestamp_, uint256 capacity_);
    event CushionUp(bool high_, uint256 timestamp_, uint256 capacity_);
    event CushionDown(bool high_, uint256 timestamp_);
    event PricesChanged(
        uint256 wallLowPrice_,
        uint256 cushionLowPrice_,
        uint256 cushionHighPrice_,
        uint256 wallHighPrice_
    );
    event SpreadsChanged(uint256 cushionSpread_, uint256 wallSpread_);
    event ThresholdFactorChanged(uint256 thresholdFactor_);

    // =========  ERRORS ========= //

    error RANGE_InvalidParams();

    // =========  STATE ========= //

    struct Line {
        uint256 price; // Price for the specified level
    }

    struct Band {
        Line high; // Price of the high side of the band
        Line low; // Price of the low side of the band
        uint256 spread; // Spread of the band (increase/decrease from the moving average to set the band prices), percent with 2 decimal places (i.e. 1000 = 10% spread)
    }

    struct Side {
        bool active; // Whether or not the side is active (i.e. the Operator is performing market operations on this side, true = active, false = inactive)
        uint48 lastActive; // Unix timestamp when the side was last active (in seconds)
        uint256 capacity; // Amount of tokens that can be used to defend the side of the range. Specified in OHM tokens on the high side and Reserve tokens on the low side.
        uint256 threshold; // Minimum number of tokens required in capacity to maintain an active side. Specified in OHM tokens on the high side and Reserve tokens on the low side.
        uint256 market; // Market ID of the cushion bond market for the side. If no market is active, the market ID is set to max uint256 value.
    }

    struct Range {
        Side low; // Data specific to the low side of the range
        Side high; // Data specific to the high side of the range
        Band cushion; // Data relevant to cushions on both sides of the range
        Band wall; // Data relevant to walls on both sides of the range
    }

    // Range data singleton. See range().
    Range internal _range;

    /// @notice Threshold factor for the change, a percent in 2 decimals (i.e. 1000 = 10%). Determines how much of the capacity must be spent before the side is taken down.
    /// @dev    A threshold is required so that a wall is not "active" with a capacity near zero, but unable to be depleted practically (dust).
    uint256 public thresholdFactor;

    /// @notice OHM token contract address
    ERC20 public ohm;

    /// @notice Reserve token contract address
    ERC20 public reserve;

    // =========  FUNCTIONS ========= //

    /// @notice Update the capacity for a side of the range.
    /// @notice Access restricted to activated policies.
    /// @param  high_ - Specifies the side of the range to update capacity for (true = high side, false = low side).
    /// @param  capacity_ - Amount to set the capacity to (OHM tokens for high side, Reserve tokens for low side).
    function updateCapacity(bool high_, uint256 capacity_) external virtual;

    /// @notice Update the prices for the low and high sides.
    /// @notice Access restricted to activated policies.
    /// @param  movingAverage_ - Current moving average price to set range prices from.
    function updatePrices(uint256 movingAverage_) external virtual;

    /// @notice Regenerate a side of the range to a specific capacity.
    /// @notice Access restricted to activated policies.
    /// @param  high_ - Specifies the side of the range to regenerate (true = high side, false = low side).
    /// @param  capacity_ - Amount to set the capacity to (OHM tokens for high side, Reserve tokens for low side).
    function regenerate(bool high_, uint256 capacity_) external virtual;

    /// @notice Update the market ID (cushion) for a side of the range.
    /// @notice Access restricted to activated policies.
    /// @param  high_ - Specifies the side of the range to update market for (true = high side, false = low side).
    /// @param  market_ - Market ID to set for the side.
    /// @param  marketCapacity_ - Amount to set the last market capacity to (OHM tokens for high side, Reserve tokens for low side).
    function updateMarket(
        bool high_,
        uint256 market_,
        uint256 marketCapacity_
    ) external virtual;

    /// @notice Set the wall and cushion spreads.
    /// @notice Access restricted to activated policies.
    /// @param  cushionSpread_ - Percent spread to set the cushions at above/below the moving average, assumes 2 decimals (i.e. 1000 = 10%).
    /// @param  wallSpread_ - Percent spread to set the walls at above/below the moving average, assumes 2 decimals (i.e. 1000 = 10%).
    /// @dev    The new spreads will not go into effect until the next time updatePrices() is called.
    function setSpreads(uint256 cushionSpread_, uint256 wallSpread_) external virtual;

    /// @notice Set the threshold factor for when a wall is considered "down".
    /// @notice Access restricted to activated policies.
    /// @param  thresholdFactor_ - Percent of capacity that the wall should close below, assumes 2 decimals (i.e. 1000 = 10%).
    /// @dev    The new threshold factor will not go into effect until the next time regenerate() is called for each side of the wall.
    function setThresholdFactor(uint256 thresholdFactor_) external virtual;

    /// @notice Get the full Range data in a struct.
    function range() external view virtual returns (Range memory);

    /// @notice Get the capacity for a side of the range.
    /// @param  high_ - Specifies the side of the range to get capacity for (true = high side, false = low side).
    function capacity(bool high_) external view virtual returns (uint256);

    /// @notice Get the status of a side of the range (whether it is active or not).
    /// @param  high_ - Specifies the side of the range to get status for (true = high side, false = low side).
    function active(bool high_) external view virtual returns (bool);

    /// @notice Get the price for the wall or cushion for a side of the range.
    /// @param  wall_ - Specifies the band to get the price for (true = wall, false = cushion).
    /// @param  high_ - Specifies the side of the range to get the price for (true = high side, false = low side).
    function price(bool wall_, bool high_) external view virtual returns (uint256);

    /// @notice Get the spread for the wall or cushion band.
    /// @param  wall_ - Specifies the band to get the spread for (true = wall, false = cushion).
    function spread(bool wall_) external view virtual returns (uint256);

    /// @notice Get the market ID for a side of the range.
    /// @param  high_ - Specifies the side of the range to get market for (true = high side, false = low side).
    function market(bool high_) external view virtual returns (uint256);

    /// @notice Get the timestamp when the range was last active.
    /// @param  high_ - Specifies the side of the range to get timestamp for (true = high side, false = low side).
    function lastActive(bool high_) external view virtual returns (uint256);
}