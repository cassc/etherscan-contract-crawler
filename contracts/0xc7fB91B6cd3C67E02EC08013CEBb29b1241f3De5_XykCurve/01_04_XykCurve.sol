// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import {FixedPointMathLib} from "solmate/utils/FixedPointMathLib.sol";

import {ICurve} from "./ICurve.sol";
import {CurveErrorCodes} from "./CurveErrorCodes.sol";

/**
 * @author 0xacedia
 * @notice Bonding curve logic for an x*y=k curve using virtual reserves.
 * @dev The virtual token reserve is stored in `spotPrice` and the virtual nft reserve is stored in `delta`.
 * An LP can modify the virtual reserves by changing the `spotPrice` (tokens) or `delta` (nfts).
 */
contract XykCurve is ICurve, CurveErrorCodes {
    using FixedPointMathLib for uint256;

    /**
     * @dev See {ICurve-validateDelta}
     */
    function validateDelta(uint128 /*delta*/ ) external pure override returns (bool) {
        // all values are valid
        return true;
    }

    /**
     * @dev See {ICurve-validateSpotPrice}
     */
    function validateSpotPrice(uint128 /*newSpotPrice*/ ) external pure override returns (bool) {
        // all values are valid
        return true;
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
        pure
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
        if (numItems == 0) {
            return (Error.INVALID_NUMITEMS, 0, 0, 0, 0, 0);
        }

        // Get the pair's virtual nft and token reserves
        uint256 nftBalance = delta;

        // If numItems is too large, we will get a divide by zero error
        if (numItems >= nftBalance) {
            return (Error.INVALID_NUMITEMS, 0, 0, 0, 0, 0);
        }

        // Calculate new nft balance
        uint256 newNftBalance;
        unchecked {
            newNftBalance = nftBalance - numItems;
        }

        // Calculate the amount to send in. spotPrice is the virtual reserve.
        uint256 inputValueWithoutFee = (numItems * spotPrice) / newNftBalance;

        // Add the fees to the amount to send in
        protocolFee = inputValueWithoutFee.mulWadUp(protocolFeeMultiplier);
        tradeFee = inputValueWithoutFee.mulWadUp(feeMultiplier);
        inputValue = inputValueWithoutFee + tradeFee + protocolFee;

        // Set the new virtual reserves
        uint256 newSpotPrice_ = spotPrice + inputValueWithoutFee;
        if (newSpotPrice_ > type(uint128).max) {
            return (Error.SPOT_PRICE_OVERFLOW, 0, 0, 0, 0, 0);
        }

        newSpotPrice = uint128(newSpotPrice_); // token reserve

        newDelta = uint128(newNftBalance); // nft reserve

        // If we got all the way here, no math errors happened
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
        pure
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
        if (numItems == 0) {
            return (Error.INVALID_NUMITEMS, 0, 0, 0, 0, 0);
        }

        // Get the pair's virtual nft and eth/erc20 balance
        uint256 tokenBalance = spotPrice;
        uint256 nftBalance = delta;

        // Return early if new nft balance is too high
        uint256 newBalance = nftBalance + numItems;
        if (newBalance > type(uint128).max) {
            return (Error.DELTA_OVERFLOW, 0, 0, 0, 0, 0);
        }

        // Calculate the amount to send out
        uint256 outputValueWithoutFee = (numItems * tokenBalance) / newBalance;

        // Subtract fees from amount to send out
        protocolFee = outputValueWithoutFee.mulWadUp(protocolFeeMultiplier);
        tradeFee = outputValueWithoutFee.mulWadUp(feeMultiplier);
        outputValue = outputValueWithoutFee - tradeFee - protocolFee;

        // Set new nft balance
        newDelta = uint128(newBalance);

        // Set the new virtual reserves
        newSpotPrice = uint128(spotPrice - outputValueWithoutFee); // token reserve

        // If we got all the way here, no math errors happened
        error = Error.OK;
    }
}