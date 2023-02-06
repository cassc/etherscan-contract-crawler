//SPDX-License-Identifier: Unlicense
pragma solidity =0.7.6;
pragma abicoder v2;

import "@uniswap/v3-core/contracts/libraries/TickMath.sol";
import "@uniswap/v3-periphery/contracts/libraries/LiquidityAmounts.sol";

library TidePoolMath {

    int24 internal constant MAX_TICK = 887272;
    int24 internal constant MIN_TICK = -MAX_TICK;

    // calculates how much of the tick window is above vs below
    function calculateWindow(int24 tick, int24 spacing, int24 window, uint8 bias) public pure returns (int24 upper, int24 lower) {
        require(bias >= 0 && bias <= 100,"BB");
        if(window < 2 ) window = 2;
        
        int24 windowSize = window * spacing;

        upper = (tick + windowSize * bias / 100);
        lower = (tick - windowSize * (100-bias) / 100);

        // fix some corner cases
        if(upper < tick) upper = tick;
        if(lower > tick) lower = tick;
        if(upper > MAX_TICK) upper = (MAX_TICK / spacing - 1) * spacing;
        if(lower < MIN_TICK) lower = (MIN_TICK / spacing + 1) * spacing;

        // make sure these are valid ticks
        upper = upper / spacing * spacing;
        lower = lower / spacing * spacing;
    }

    // find the greater ratio: a:b or c:d. From 0 - 100.
    function zeroIsLessUsed(uint256 a, uint256 b, uint256 c, uint256 d) public pure returns (bool) {
        require(a <= b && c <= d,"Illegal inputs");
        uint256 first = a > 0 ? a * 100 / b : 0;
        uint256 second = c > 0 ? c * 100 / d : 0;
        return  first <= second ? true : false;
    }

    // window size grows by 4 ticks every rebalance, but shrinks 1 tick per day if it stays within the range.
    function getWindowSize(int24 _previous, uint256 _lastRebalance, bool _outOfRange) public view returns (int24) {
        int24 diff = int24((block.timestamp - _lastRebalance) / 1 days);
        int24 window = _outOfRange ? _previous + 4 : _previous - diff;
        return window < 2 ? 2 : window;
    }
}