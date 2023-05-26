// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <=0.8.7;
import "prb-math/contracts/PRBMathUD60x18.sol";
//import "hardhat/console.sol";

// work with limits on the input/output of all accounts
library GlobalLimits {
    using PRBMathUD60x18 for uint256;

    // data structure of global limits
    struct GlobalLimitsData {
        uint256 _MaxFallPercent; // how much can the exchange rate collapse in a time interval in percent 1%=1e16
        uint256 _PriceControlTimeIntervalMinutes; // time interval for price control (after this interval the next price measurement takes place)
        uint256 _ControlTime; // time of the last cost measurement
        uint256 _ControlTimePrice; // the price at the time of the last cost measurement
        uint256 _DefaultMaxFallPercent; // to what size does the limit increase
    }

    // initializes global limits
    function Initialize(
        GlobalLimitsData storage data,
        uint256 maxFallPercent, // how much can the exchange rate collapse in a time interval in percent 1%=1e16
        uint256 priceControlTimeIntervalMinutes, // time interval for price control (after this interval the next price measurement takes place)
        uint256 price // initial cost
    ) public {
        data._MaxFallPercent = maxFallPercent;
        data._DefaultMaxFallPercent = maxFallPercent;
        data._PriceControlTimeIntervalMinutes = priceControlTimeIntervalMinutes;
        data._ControlTime = block.timestamp;
        data._ControlTimePrice = price;
    }

    // updates global limits 
    // result codes: 
    // 0 then account limits are not changed 
    // 1 unsuccessful attempt to increment the sale limit (increase the maximum collapse when selling) 
    // -1 unsuccessful attempt to increment the sale limit but there was a limiter in the current structure, then nothing changed      (decrease maximal collapse when selling) 
    // 2 increment selling limit (increase maximal slump during sale) 
    // -2 decrement of sales limit (decrease maximal drop of sales) // 
    // here are 3 events - price went higher, price went lower, or checkout time expired - then an attempt to increase
    function Update(
        GlobalLimitsData storage data,
        uint256 newPrice // new token price
    ) public returns (int256) {
        // if the new price collapses course by more than a certain percentage, then the limit is changed
        if (
            newPrice < data._ControlTimePrice &&
            PRBMathUD60x18.div(newPrice, data._ControlTimePrice) <
            1e18 - data._MaxFallPercent
        ) {
            // reducing the limit
            uint256 last = data._MaxFallPercent;
            DecrementLimits(data);
            // new reference time
            data._ControlTime = block.timestamp;
            data._ControlTimePrice = newPrice;
            // the local limits should be reduced   
            if (last == data._MaxFallPercent) return -1;
            else return -2;
        }

        // if the new price has gone up by more than a certain percentage, then the limit is changed
        if (
            newPrice > data._ControlTimePrice &&
            PRBMathUD60x18.div(newPrice, data._ControlTimePrice) >
            1e18 + data._MaxFallPercent
        ) {
            // increasing the limit
            uint256 last = data._MaxFallPercent;
            IncrementLimits(data);
            // new reference time
            data._ControlTime = block.timestamp;
            data._ControlTimePrice = newPrice;
            // local limits should be increased
            if (last == data._MaxFallPercent) return 1;
            else return 2;
        }

        // limits should be increased if there were no time change
        if (
            block.timestamp >=
            data._ControlTime +
                data._PriceControlTimeIntervalMinutes *
                1 minutes
        ) {
            // increasing the limit
            uint256 last = data._MaxFallPercent;
            IncrementLimits(data);
            // new reference time
            data._ControlTime = block.timestamp;
            data._ControlTimePrice = newPrice;
            // the local limits should be increased
            if (last == data._MaxFallPercent) return 1;
            else return 2;
        }

        // the local limits have not changed
        return 0;
    }

    function DecrementLimits(GlobalLimitsData storage data) public {
        // reducing the limit
        uint256 newMaxFallPercent = PRBMathUD60x18.div(
            data._MaxFallPercent,
            2e18
        );
        // restriction
        if (newMaxFallPercent < 1) return;
        // set a new limit
        data._MaxFallPercent = newMaxFallPercent;
    }

    // increases the limit, allowing you to make larger transactions
    // doesn't increase more than the default
    function IncrementLimits(GlobalLimitsData storage data) public {
        // increasing the limit
        uint256 newMaxFallPercent = PRBMathUD60x18.mul(
            data._MaxFallPercent,
            2e18
        );
        // if more than the default, then the restriction
        if (newMaxFallPercent > data._DefaultMaxFallPercent)
            newMaxFallPercent = data._DefaultMaxFallPercent;
        // set a new limit
        data._MaxFallPercent = newMaxFallPercent;
    }
}