// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.13;

import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {Constants} from "./../Constants.sol";
import {Initializable} from "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import {IVoltSystemOracle} from "./IVoltSystemOracle.sol";

/// @notice contract that receives a fixed interest rate upon construction,
/// and then linearly interpolates that rate over a 30.42 day period into the VOLT price
/// after the oracle start time.
/// Interest can compound annually. Assumption is that this oracle will only be used until
/// Volt 2.0 ships. Maximum amount of compounding periods on this contract at 2% APR
/// is 6192 years, which is more than enough for this use case.
/// @author Elliot Friedman
contract VoltSystemOracle is IVoltSystemOracle {
    /// ---------- Mutable Variables ----------

    /// @notice acts as an accumulator for interest earned in previous periods
    /// returns the oracle price from the end of the last period
    uint256 public oraclePrice;

    /// @notice start time at which point interest will start accruing, and the
    /// current ScalingPriceOracle price will be snapshotted and saved
    uint256 public periodStartTime;

    /// ---------- Immutable Variables ----------

    /// @notice current amount that oracle price is inflating by monthly in basis points
    uint256 public immutable monthlyChangeRateBasisPoints;

    /// @notice the time frame over which all changes in the APR are applied
    /// one month was chosen because this is a temporary oracle
    uint256 public constant TIMEFRAME = 30.42 days;

    /// @param _monthlyChangeRateBasisPoints monthly change rate in the Volt price
    /// @param _periodStartTime start time at which oracle starts interpolating prices
    /// @param _oraclePrice starting oracle price
    constructor(
        uint256 _monthlyChangeRateBasisPoints,
        uint256 _periodStartTime,
        uint256 _oraclePrice
    ) {
        monthlyChangeRateBasisPoints = _monthlyChangeRateBasisPoints;
        periodStartTime = _periodStartTime;
        oraclePrice = _oraclePrice;
    }

    // ----------- Getter -----------

    /// @notice get the current scaled oracle price
    /// applies the change rate smoothly over a 30.42 day period
    /// scaled by 18 decimals
    // prettier-ignore
    function getCurrentOraclePrice() public view override returns (uint256) {
        uint256 cachedStartTime = periodStartTime; /// save a single warm SLOAD if condition is false
        if (cachedStartTime >= block.timestamp) { /// only accrue interest after start time
            return oraclePrice;
        }

        uint256 cachedOraclePrice = oraclePrice; /// save a single warm SLOAD by using the stack
        uint256 timeDelta = Math.min(block.timestamp - cachedStartTime, TIMEFRAME);
        uint256 pricePercentageChange = cachedOraclePrice * monthlyChangeRateBasisPoints / Constants.BASIS_POINTS_GRANULARITY;
        uint256 priceDelta = pricePercentageChange * timeDelta / TIMEFRAME;

        return cachedOraclePrice + priceDelta;
    }

    /// ------------- Public State Changing API -------------

    /// @notice public function that allows compounding of interest after duration has passed
    /// Sets accumulator to the current accrued interest, and then resets the timer.
    function compoundInterest() external override {
        uint256 periodEndTime = periodStartTime + TIMEFRAME; /// save a single warm SLOAD when writing to periodStartTime
        require(
            block.timestamp >= periodEndTime,
            "VoltSystemOracle: not past end time"
        );

        /// first set Oracle Price to interpolated value
        oraclePrice = getCurrentOraclePrice();

        /// set periodStartTime to periodStartTime + timeframe,
        /// this is equivalent to init timed, which wipes out all unaccumulated compounded interest
        /// and cleanly sets the start time.
        periodStartTime = periodEndTime;

        emit InterestCompounded(periodStartTime, oraclePrice);
    }
}