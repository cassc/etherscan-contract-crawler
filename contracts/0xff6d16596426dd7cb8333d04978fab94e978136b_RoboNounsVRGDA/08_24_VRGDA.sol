// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import { unsafeDiv, unsafeWadDiv, unsafeWadMul, wadExp, wadLn, wadMul } from "solmate/src/utils/SignedWadMath.sol";

library VRGDA {
    /// @notice Calculate the price of a token according to the VRGDA formula.
    /// @param timeSinceStart Time passed since the VRGDA began, scaled by 1e18.
    /// @param targetPrice The target price for a token if sold on pace, scaled by 1e18.
    /// @param decayConstant A constant calculated as the natural log of the complement of the price decay percent, scaled by 1e18
    /// @param targetSaleTime The target time the tokens should be sold by, scaled by 1e18, relative to timeSinceStart
    /// @return The price of a token according to VRGDA, scaled by 1e18.
    function getVRGDAPrice(
        int256 timeSinceStart,
        int256 targetPrice,
        int256 decayConstant,
        int256 targetSaleTime
    ) internal pure returns (uint256) {
        unchecked {
            // prettier-ignore
            return uint256(wadMul(targetPrice, wadExp(unsafeWadMul(decayConstant,
                timeSinceStart - targetSaleTime)
            )));
        }
    }

    /// @dev Given a number of tokens sold, return the target time that number of tokens should be sold by using a linear schedule
    /// @param sold A number of tokens sold, scaled by 1e18, to get the corresponding target sale time for.
    /// @param perTimeUnit The number of tokens to target selling in 1 full unit of time, scaled by 1e18.
    /// @return The target time the tokens should be sold by, scaled by 1e18, where the time is
    /// relative, such that 0 means the tokens should be sold immediately when the VRGDA begins.
    function getTargetSaleTimeLinear(int256 sold, int256 perTimeUnit) internal pure returns (int256) {
        return unsafeWadDiv(sold, perTimeUnit);
    }

    /// @dev Given a number of tokens sold, return the target time that number of tokens should be sold by using a logistic schedule
    /// @param sold A number of tokens sold, scaled by 1e18, to get the corresponding target sale time for.
    /// @param timeScale The steepness of the logistic curve, scaled by 1e18.
    /// @param logisticLimit The maximum number of tokens of tokens to sell + 1
    /// @return The target time the tokens should be sold by, scaled by 1e18, where the time is
    /// relative, such that 0 means the tokens should be sold immediately when the VRGDA begins.
    function getTargetSaleTimeLogistic(
        int256 sold,
        int256 logisticLimit,
        int256 timeScale
    ) internal pure returns (int256) {
        unchecked {
            return -unsafeWadDiv(wadLn(unsafeDiv(logisticLimit * 2e18, sold + logisticLimit) - 1e18), timeScale);
        }
    }
}