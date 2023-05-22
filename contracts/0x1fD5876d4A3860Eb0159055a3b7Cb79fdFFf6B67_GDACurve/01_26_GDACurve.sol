// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.13;

import {ICurve} from "./ICurve.sol";
import {CurveErrorCodes} from "./CurveErrorCodes.sol";
import {UD60x18, ud, unwrap, uUNIT, UNIT, convert} from "@prb/math/UD60x18.sol";

/**
 * @author 0xmons, boredGenius, 0xCygaar
 * @notice Bonding curve logic for a gradual dutch auction based on https://www.paradigm.xyz/2022/04/gda.
 * @dev Trade pools will result in unexpected behavior due to the time factor always increasing. Buying an NFT
 * and selling it back into the pool will result in a non-zero difference. Therefore it is recommended to only
 * use this curve for single-sided pools.
 */
contract GDACurve is ICurve, CurveErrorCodes {
    uint256 internal constant _SCALE_FACTOR = 1e9;
    uint256 internal constant _TIME_SCALAR = 2 * uUNIT; // Used in place of Euler's number
    uint256 internal constant _MAX_TIME_EXPONENT = 10;

    /**
     * @notice Minimum price to prevent numerical issues
     */
    uint256 public constant MIN_PRICE = 1 gwei;

    /**
     * @dev See {ICurve-validateDelta}
     */
    function validateDelta(uint128 delta) external pure override returns (bool) {
        (UD60x18 alpha,,) = _parseDelta(delta);
        return alpha.gt(UNIT);
    }

    /**
     * @dev See {ICurve-validateSpotPrice}
     */
    function validateSpotPrice(uint128 newSpotPrice) external pure override returns (bool) {
        return newSpotPrice >= MIN_PRICE;
    }

    /**
     * @dev See {ICurve-getBuyInfo}
     */
    function getBuyInfo(
        uint128 spotPrice,
        uint128 delta,
        uint256 numItems,
        uint256 feeMultiplier,
        uint256 protocolFeeMultiplier
    )
        external
        view
        override
        returns (
            Error error,
            uint128 newSpotPrice,
            uint128 newDelta,
            uint256 inputValue,
            uint256 tradeFee,
            uint256 protocolFee
        )
    {
        // NOTE: we assume alpha is > 1, as checked by validateDelta()
        // We only calculate changes for buying 1 or more NFTs
        if (numItems == 0) {
            return (Error.INVALID_NUMITEMS, 0, 0, 0, 0, 0);
        }

        UD60x18 spotPrice_ = ud(spotPrice);
        UD60x18 decayFactor;
        {
            (, uint256 lambda, uint256 prevTime) = _parseDelta(delta);
            UD60x18 exponent = ud((block.timestamp - prevTime) * lambda);
            if (convert(exponent) > _MAX_TIME_EXPONENT) {
                // Cap the max decay factor to 2^20
                exponent = convert(_MAX_TIME_EXPONENT);
            }
            decayFactor = ud(_TIME_SCALAR).pow(exponent);
        }

        (UD60x18 alpha,,) = _parseDelta(delta);
        UD60x18 alphaPowN = alpha.powu(numItems);

        // The new spot price is multiplied by alpha^n and divided by the time decay so future
        // calculations do not need to track number of items sold or the initial time/price. This new spot price
        // implicitly stores the the initial price, total items sold so far, and time elapsed since the start.
        {
            UD60x18 newSpotPrice_ = spotPrice_.mul(alphaPowN);
            newSpotPrice_ = newSpotPrice_.div(decayFactor);
            if (newSpotPrice_.gt(ud(type(uint128).max))) {
                return (Error.SPOT_PRICE_OVERFLOW, 0, 0, 0, 0, 0);
            }
            if (newSpotPrice_.lt(ud(MIN_PRICE))) {
                return (Error.SPOT_PRICE_UNDERFLOW, 0, 0, 0, 0, 0);
            }
            newSpotPrice = uint128(unwrap(newSpotPrice_));
        }

        // If the user buys n items, then the total cost is equal to:
        // buySpotPrice + (alpha * buySpotPrice) + (alpha^2 * buySpotPrice) + ... (alpha^(numItems - 1) * buySpotPrice).
        // This is equal to buySpotPrice * (alpha^n - 1) / (alpha - 1).
        // We then divide the value by scalar^(lambda * timeElapsed) to factor in the exponential decay.
        {
            UD60x18 inputValue_ = spotPrice_.mul(alphaPowN.sub(UNIT)).div(alpha.sub(UNIT)).div(decayFactor);

            // Account for the protocol fee, a flat percentage of the buy amount
            protocolFee = unwrap(inputValue_.mul(ud(protocolFeeMultiplier)));

            // Account for the trade fee, only for Trade pools
            tradeFee = unwrap(inputValue_.mul(ud(feeMultiplier)));

            // Add the protocol and trade fees to the required input amount and unwrap to uint256
            inputValue = unwrap(inputValue_.add(ud(protocolFee)).add(ud(tradeFee)));
        }

        // Update delta with the current timestamp
        newDelta = _getNewDelta(delta);

        // If we got all the way here, no math error happened
        error = Error.OK;
    }

    /**
     * @dev See {ICurve-getSellInfo}
     */
    function getSellInfo(
        uint128 spotPrice,
        uint128 delta,
        uint256 numItems,
        uint256 feeMultiplier,
        uint256 protocolFeeMultiplier
    )
        external
        view
        override
        returns (
            Error error,
            uint128 newSpotPrice,
            uint128 newDelta,
            uint256 outputValue,
            uint256 tradeFee,
            uint256 protocolFee
        )
    {
        // We only calculate changes for buying 1 or more NFTs
        if (numItems == 0) {
            return (Error.INVALID_NUMITEMS, 0, 0, 0, 0, 0);
        }

        UD60x18 spotPrice_ = ud(spotPrice);
        UD60x18 boostFactor;
        {
            (, uint256 lambda, uint256 prevTime) = _parseDelta(delta);
            UD60x18 exponent = ud((block.timestamp - prevTime) * lambda);
            if (convert(exponent) > _MAX_TIME_EXPONENT) {
                // Cap the max boost factor to 2^20
                exponent = convert(_MAX_TIME_EXPONENT);
            }
            boostFactor = ud(_TIME_SCALAR).pow(exponent);
        }

        (UD60x18 alpha,,) = _parseDelta(delta);
        UD60x18 alphaPowN = alpha.powu(numItems);

        // The new spot price is multiplied by the time boost and divided by alpha^n so future
        // calculations do not need to track number of items sold or the initial time/price. This new spot price
        // implicitly stores the the initial price, total items sold so far, and time elapsed since the start.
        {
            UD60x18 newSpotPrice_ = spotPrice_.mul(boostFactor);
            newSpotPrice_ = newSpotPrice_.div(alphaPowN);
            if (newSpotPrice_.gt(ud(type(uint128).max))) {
                return (Error.SPOT_PRICE_OVERFLOW, 0, 0, 0, 0, 0);
            }
            if (newSpotPrice_.lt(ud(MIN_PRICE))) {
                return (Error.SPOT_PRICE_UNDERFLOW, 0, 0, 0, 0, 0);
            }
            newSpotPrice = uint128(unwrap(newSpotPrice_));
        }

        // The expected output for an auction at index n is defined by the formula: p(t) = k * scalar^(lambda * t) / alpha^n
        // where k is the initial price, lambda is the boost constant, t is time elapsed, alpha is the scale factor, and
        // n is the number of items sold. The amount to receive for selling into a pool can thus be written as:
        // k * scalar^(lambda * t) / alpha^(m + q - 1) * (alpha^q - 1) / (alpha - 1) where m is the number of items purchased thus far
        // and q is the number of items to sell.
        // Our spot price implicity embeds the number of items already purchased and the previous time boost, so we just need to
        // do some simple adjustments to get the current scalar^(lambda * t) and alpha^(m + q - 1) values.
        UD60x18 outputValue_ =
            spotPrice_.mul(boostFactor).div(alphaPowN.div(alpha)).mul(alphaPowN.sub(UNIT)).div(alpha.sub(UNIT));

        // Account for the protocol fee, a flat percentage of the sell amount
        protocolFee = unwrap(outputValue_.mul(ud(protocolFeeMultiplier)));

        // Account for the trade fee, only for Trade pools
        tradeFee = unwrap(outputValue_.mul(ud(feeMultiplier)));

        // Remove the protocol and trade fees from the output amount and unwrap to uint256
        outputValue = unwrap(outputValue_.sub(ud(protocolFee)).sub(ud(tradeFee)));

        // Update delta with the current timestamp
        newDelta = _getNewDelta(delta);

        // If we got all the way here, no math error happened
        error = Error.OK;
    }

    function _parseDelta(uint128 delta) internal pure returns (UD60x18 alpha, uint256 lambda, uint256 prevTime) {
        // The highest 40 bits are alpha with 9 decimals of precision.
        // However, because our alpha value needs to be 18 decimals of precision, we multiply by a scaling factor
        alpha = ud(uint40(delta >> 88) * _SCALE_FACTOR);

        // The middle 40 bits are lambda with 9 decimals of precision
        // lambda determines the exponential decay (when buying) or exponential boost (when selling) over time
        // See https://www.paradigm.xyz/2022/04/gda
        // lambda also needs to be 18 decimals of precision so we multiply by a scaling factor
        lambda = uint40(delta >> 48) * _SCALE_FACTOR;

        // The lowest 48 bits are the start timestamp
        // This works because solidity cuts off higher bits when converting from a larger type to a smaller type
        // See https://docs.soliditylang.org/en/latest/types.html#explicit-conversions
        prevTime = uint256(uint48(delta));
    }

    function _getNewDelta(uint128 delta) internal view returns (uint128) {
        // Clear lower 48 bits
        delta = (delta >> 48) << 48;
        // Set lower 48 bits to be the current timestamp
        return delta | uint48(block.timestamp);
    }
}