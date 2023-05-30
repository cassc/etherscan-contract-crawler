// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import {CurveErrorCodes} from "./CurveErrorCodes.sol";

interface ICurve {
    /**
     * @param spotPrice The current selling spot price of the pool, in tokens
     * @param delta The delta parameter of the pool, what it means depends on the curve
     * @param props The properties of the pool, what it means depends on the curve
     * @param state The state of the pool, what it means depends on the curve
     */
    struct Params {
        uint128 spotPrice;
        uint128 delta;
        bytes props;
        bytes state;
    }

    /**
     * @param trade The amount of fee to send to the pool, in tokens
     * @param protocol The amount of fee to send to the protocol, in tokens
     * @param royalties The amount to pay for each item in the order they
     * are purchased. Always has length `numItems`.
     */
    struct Fees {
        uint256 trade;
        uint256 protocol;
        uint256[] royalties;
    }

    /**
     * @param feeMultiplier Determines how much fee the LP takes from this trade, 18 decimals
     * @param fees.protocolMultiplier Determines how much fee the protocol takes from this trade, 18 decimals
     * @param royaltyNumerator Determines how much of the trade value is awarded as royalties. 5 decimals
     * @param carryFeeMultiplier Determines how much carry fee the protocol takes from this trade, 18 decimals
     */
    struct FeeMultipliers {
        uint24 trade;
        uint24 protocol;
        uint24 royaltyNumerator;
        uint24 carry;
    }

    /**
     * @notice Validates if a delta value is valid for the curve. The criteria for
     * validity can be different for each type of curve, for instance ExponentialCurve
     * requires delta to be greater than 1.
     * @param delta The delta value to be validated
     * @return valid True if delta is valid, false otherwise
     */
    function validateDelta(uint128 delta) external pure returns (bool valid);

    /**
     * @notice Validates if a new spot price is valid for the curve. Spot price is generally assumed to be the immediate sell price of 1 NFT to the pool, in units of the pool's pooled token.
     * @param newSpotPrice The new spot price to be set
     * @return valid True if the new spot price is valid, false otherwise
     */
    function validateSpotPrice(uint128 newSpotPrice) external view returns (bool valid);

    /**
     * @notice Validates if a props value is valid for the curve. The criteria for validity can be different for each type of curve.
     * @param props The props value to be validated
     * @return valid True if props is valid, false otherwise
     */
    function validateProps(bytes calldata props) external view returns (bool valid);

    /**
     * @notice Validates if a state value is valid for the curve. The criteria for validity can be different for each type of curve.
     * @param state The state value to be validated
     * @return valid True if state is valid, false otherwise
     */
    function validateState(bytes calldata state) external view returns (bool valid);

    /**
     * @notice Validates given delta, spot price, props value and state value for the curve. The criteria for validity can be different for each type of curve.
     * @param delta The delta value to be validated
     * @param newSpotPrice The new spot price to be set
     * @param props The props value to be validated
     * @param state The state value to be validated
     * @return valid True if all parameters are valid, false otherwise
     */
    function validate(uint128 delta, uint128 newSpotPrice, bytes calldata props, bytes calldata state)
        external
        view
        returns (bool valid);

    /**
     * @notice Given the current state of the pool and the trade, computes how much the user
     * should pay to purchase an NFT from the pool, the new spot price, and other values.
     * @dev Do not try to optimize the length of fees.royalties; compiler
     * ^0.8.0 throws a YulException if you try to use an if-guard in the sigmoid
     * calculation loop due to stack depth
     * @param params Parameters of the pool that affect the bonding curve.
     * @param numItems The number of NFTs the user is buying from the pool
     * @param feeMultipliers Determines how much fee is taken from this trade.
     * @return newParams The updated parameters of the pool that affect the bonding curve.
     * @return inputValue The amount that the user should pay, in tokens
     * @return fees The amount of fees
     * @return lastSwapPrice The swap price of the last NFT traded with fees applied
     */
    function getBuyInfo(ICurve.Params calldata params, uint256 numItems, ICurve.FeeMultipliers calldata feeMultipliers)
        external
        view
        returns (ICurve.Params calldata newParams, uint256 inputValue, ICurve.Fees calldata fees, uint256 lastSwapPrice);

    /**
     * @notice Given the current state of the pool and the trade, computes how much the user
     * should receive when selling NFTs to the pool, the new spot price, and other values.
     * @dev Do not try to optimize the length of fees.royalties; compiler
     * ^0.8.0 throws a YulException if you try to use an if-guard in the sigmoid
     * calculation loop due to stack depth
     * @param params Parameters of the pool that affect the bonding curve.
     * @param numItems The number of NFTs the user is selling to the pool
     * @param feeMultipliers Determines how much fee is taken from this trade.
     * @return newParams The updated parameters of the pool that affect the bonding curve.
     * @return outputValue The amount that the user should receive, in tokens
     * @return fees The amount of fees
     * @return lastSwapPrice The swap price of the last NFT traded with fees applied
     */
    function getSellInfo(ICurve.Params calldata params, uint256 numItems, ICurve.FeeMultipliers calldata feeMultipliers)
        external
        view
        returns (
            ICurve.Params calldata newParams,
            uint256 outputValue,
            ICurve.Fees calldata fees,
            uint256 lastSwapPrice
        );
}