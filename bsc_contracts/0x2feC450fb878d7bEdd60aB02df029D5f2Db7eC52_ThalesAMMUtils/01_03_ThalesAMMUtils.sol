// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@prb/math/contracts/PRBMathUD60x18.sol";

/// @title An AMM using BlackScholes odds algorithm to provide liqudidity for traders of UP or DOWN positions
contract ThalesAMMUtils {
    using PRBMathUD60x18 for uint256;

    uint private constant ONE = 1e18;
    uint private constant ONE_PERCENT = 1e16;

    /// @notice get the algorithmic odds of market being in the money, taken from JS code https://gist.github.com/aasmith/524788/208694a9c74bb7dfcb3295d7b5fa1ecd1d662311
    /// @param _price current price of the asset
    /// @param strike price of the asset
    /// @param timeLeftInDays when does the market mature
    /// @param volatility implied yearly volatility of the asset
    /// @return odds of market being in the money
    function calculateOdds(
        uint _price,
        uint strike,
        uint timeLeftInDays,
        uint volatility
    ) public view returns (uint) {
        uint vt = ((volatility / (100)) * (sqrt(timeLeftInDays / (365)))) / (1e9);
        bool direction = strike >= _price;
        uint lnBase = strike >= _price ? (strike * (ONE)) / (_price) : (_price * (ONE)) / (strike);
        uint d1 = (PRBMathUD60x18.ln(lnBase) * (ONE)) / (vt);
        uint y = (ONE * (ONE)) / (ONE + ((d1 * (2316419)) / (1e7)));
        uint d2 = (d1 * (d1)) / (2) / (ONE);
        uint z = (_expneg(d2) * (3989423)) / (1e7);

        uint y5 = (powerInt(y, 5) * (1330274)) / (1e6);
        uint y4 = (powerInt(y, 4) * (1821256)) / (1e6);
        uint y3 = (powerInt(y, 3) * (1781478)) / (1e6);
        uint y2 = (powerInt(y, 2) * (356538)) / (1e6);
        uint y1 = (y * (3193815)) / (1e7);
        uint x1 = y5 + (y3) + (y1) - (y4) - (y2);
        uint x = ONE - ((z * (x1)) / (ONE));
        uint result = ONE * (1e2) - (x * (1e2));
        if (direction) {
            return result;
        } else {
            return ONE * (1e2) - result;
        }
    }

    function _expneg(uint x) internal view returns (uint result) {
        result = (ONE * ONE) / _expNegPow(x);
    }

    function _expNegPow(uint x) internal view returns (uint result) {
        uint e = 2718280000000000000;
        result = PRBMathUD60x18.pow(e, x);
    }

    function powerInt(uint A, int8 B) internal pure returns (uint result) {
        result = ONE;
        for (int8 i = 0; i < B; i++) {
            result = (result * (A)) / (ONE);
        }
    }

    function sqrt(uint y) internal pure returns (uint z) {
        if (y > 3) {
            z = y;
            uint x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}