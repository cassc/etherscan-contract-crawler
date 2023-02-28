// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.9;

import "./Convert.sol";
import "@positionex/matching-engine/contracts/interfaces/IMatchingEngineAMM.sol";
import "@positionex/matching-engine/contracts/libraries/amm/LiquidityMath.sol";
import "@positionex/matching-engine/contracts/libraries/helper/Math.sol";

library LiquidityHelper {
    /// @notice calculate quote virtual from base real
    /// @param baseReal the amount base real
    /// @param sqrtCurrentPrice the sqrt of current price
    /// @param sqrtPriceMin the sqrt of min price
    /// @param sqrtBasicPoint the sqrt of basisPoint
    function calculateQuoteVirtualFromBaseReal(
        uint128 baseReal,
        uint128 sqrtCurrentPrice,
        uint128 sqrtPriceMin,
        uint256 sqrtBasicPoint
    ) internal pure returns (uint128) {
        return
            uint128(
                (uint256(baseReal) *
                    uint256(sqrtCurrentPrice / sqrtBasicPoint) *
                    (uint256(sqrtCurrentPrice / sqrtBasicPoint) -
                        uint256(sqrtPriceMin / sqrtBasicPoint))) / 10**18
            );
    }

    /// @notice calculate base virtual from quote real
    /// @param quoteReal the amount quote real
    /// @param sqrtCurrentPrice the sqrt of current price
    /// @param sqrtPriceMax the sqrt of max price
    function calculateBaseVirtualFromQuoteReal(
        uint128 quoteReal,
        uint128 sqrtCurrentPrice,
        uint128 sqrtPriceMax
    ) internal pure returns (uint128) {
        return
            uint128(
                (uint256(quoteReal) *
                    10**18 *
                    (uint256(sqrtPriceMax) - uint256(sqrtCurrentPrice))) /
                    (uint256(sqrtCurrentPrice**2 * sqrtPriceMax))
            );
    }
}