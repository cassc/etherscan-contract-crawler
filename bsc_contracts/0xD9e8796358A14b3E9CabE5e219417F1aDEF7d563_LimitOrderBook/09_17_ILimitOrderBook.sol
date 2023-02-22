// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;
pragma experimental ABIEncoderV2;

import {Decimal} from "../utils/Decimal.sol";
import {SignedDecimal} from "../utils/SignedDecimal.sol";

interface ILimitOrderBook {
    /*
     * EVENTS
     */

    event OrderCreated(address indexed trader, uint256 order_id);
    event OrderFilled(
        address indexed trader,
        address indexed operator,
        uint256 order_id,
        bool filledAll,
        int256 exchangedPositionSize,
        uint256 exchangedQuoteSize
    );
    event OrderCancelled(address indexed trader, uint256 order_id);

    /*
     * ENUMS
     */

    /*
     * Order types that the user is able to create.
     * Note that market orders are actually executed instantly on clearing house
     * therefore there should never actually be a market order in the LOB
     */
    enum OrderType {
        MARKET,
        LIMIT,
        STOPLOSS,
        CLOSEPOSITION
    }

    /*
     * STRUCTS
     */

    /*
     * @notice Every order is stored within a limit order struct (regardless of
     *    the type of order)
     * @param asset is the address of the perp AMM for that particular asset
     * @param trader is the user that created the order - note that the order will
     *   actually be executed on their smart wallet (as stored in the factory)
     * @param orderType represents the order type
     * @param reduceOnly whether the order is reduceOnly or not. A reduce only order
     *   will never increase the size of a position and will either reduce the size
     *   or close the position.
     * @param stillValid whether the order can be executed. There are two conditions
     *   where an order is no longer valid: the trader cancels the order, or the
     *   order gets executed (to prevent double spend)
     * @param expiry is the blockTimestamp when this order expires. If this value
     *   is 0 then the order will not expire
     * @param limitPrice is the trigger price for any limit order. a limit BUY can
     *   only be executed below/above this price, whilst a limit SELL is executed above/below
     * @param orderSize is the size of the order (denominated in the base asset)
     * @param collateral is the amount of collateral or margin that will be used
     *   for this order. This amount is guaranteed ie an order with 300 USDC will
     *   always use 300 USDC.
     * @param leverage is the maximum amount of leverage that the trader will accept.
     * @param slippage is the minimum amount of ASSET that the user will accept.
     *   The trader will usually achieve the amount specified by orderSize. This
     *   parameter allows the user to specify their tolerance to price impact / frontrunning
     * @param tipFee is the fee that goes to the keeper for executing the order.
     *   This fee is taken when the order is created, and paid out when executing.
     */
    struct LimitOrder {
        address asset;
        address trader;
        bool reduceOnly;
        bool stillValid;
        OrderType orderType;
        uint256 expiry;
        Decimal.decimal limitPrice;
        SignedDecimal.signedDecimal orderSize;
        Decimal.decimal collateral;
        Decimal.decimal leverage;
        Decimal.decimal slippage;
        Decimal.decimal tipFee;
    }

    struct RemainingOrderInfo {
        SignedDecimal.signedDecimal remainingOrderSize;
        Decimal.decimal remainingCollateral;
        Decimal.decimal remainingTipFee;
    }

    function getLimitOrder(uint256 id)
        external
        view
        returns (LimitOrder memory, RemainingOrderInfo memory);

    function getLimitOrderParams(uint256 id)
        external
        view
        returns (
            address,
            address,
            OrderType,
            bool,
            bool,
            uint256
        );
}