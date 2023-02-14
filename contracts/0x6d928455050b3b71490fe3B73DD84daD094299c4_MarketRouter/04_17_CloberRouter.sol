// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.0;

import "./CloberOrderKey.sol";

interface CloberRouter {
    /**
     * @notice LimitOrderParams struct contains information about a limit order.
     * @param market The address of the market for this order.
     * @param deadline The deadline for the transaction. Reverts if the block timestamp is greater than this value.
     * @param claimBounty The bounty the user is willing to pay in gwei to delegate claiming.
     * @param user The address of the user placing the order.
     * @param priceIndex The price book index.
     * @param rawAmount The raw quote amount to trade, utilized by bids.
     * @param postOnly Flag indicating if the order should only be placed if it does not fill any existing orders.
     * @param useNative Flag indicating whether the order should use the native token supplied.
     * Only works when the input in the wrapped native token.
     * @param baseAmount The base token amount to trade, utilized by asks.
     */
    struct LimitOrderParams {
        address market;
        uint64 deadline;
        uint32 claimBounty;
        address user;
        uint16 priceIndex;
        uint64 rawAmount;
        bool postOnly;
        bool useNative;
        uint256 baseAmount;
    }

    /**
     * @notice Places a limit order on the bid side.
     * @param params The limit order parameters.
     * @return The order index. If an order is not made `type(uint256).max` is returned instead.
     */
    function limitBid(LimitOrderParams calldata params) external payable returns (uint256);

    /**
     * @notice Places a limit order on the ask side.
     * @param params The limit order parameters.
     * @return The order index. If an order is not made `type(uint256).max` is returned instead.
     */
    function limitAsk(LimitOrderParams calldata params) external payable returns (uint256);

    /**
     * @notice MarketOrderParams struct contains information about a market order.
     * @param market The address of the market for this order.
     * @param deadline The deadline for the transaction. Reverts if the block timestamp is greater than this value.
     * @param user The address of the user placing the order.
     * @param limitPriceIndex Index of the price at which to limit the order.
     * @param rawAmount The raw amount to trade.
     * This value is used as the maximum input amount by bids and minimum output amount by asks.
     * @param expendInput Flag indicating whether the order should spend all of the user's
     * input tokens (true) or just until the desired output amount is met (false).
     * @param useNative Flag indicating whether the order should use the native token supplied.
     * Only works when the input in the wrapped native token.
     * @param baseAmount The base token amount to trade.
     * This value is used as the maximum input amount by asks and minimum output amount by bids.
     */
    struct MarketOrderParams {
        address market;
        uint64 deadline;
        address user;
        uint16 limitPriceIndex;
        uint64 rawAmount;
        bool expendInput;
        bool useNative;
        uint256 baseAmount;
    }

    /**
     * @notice Place a market order on the bid side.
     * @param params The market order parameters.
     */
    function marketBid(MarketOrderParams calldata params) external payable;

    /**
     * @notice Place a market order on the ask side.
     * @param params The market order parameters.
     */
    function marketAsk(MarketOrderParams calldata params) external payable;

    /**
     * @notice Struct for passing parameters to the function that claims orders.
     * @param market The market address of the orders to claim from.
     * @param orderKeys An array of OrderKey structs representing the keys of the orders being claimed.
     */
    struct ClaimOrderParams {
        address market;
        OrderKey[] orderKeys;
    }

    /**
     * @notice Claims orders across markets.
     * @param deadline The deadline for the transaction. Reverts if the block timestamp is greater than this value.
     * @param paramsList The list of ClaimOrderParams
     */
    function claim(uint64 deadline, ClaimOrderParams[] calldata paramsList) external;

    /**
     * @notice Submits a limit bid order to the order book after claiming a list of orders.
     * @param claimParamsList Array of ClaimOrderParams: The list of orders to be claimed.
     * @param limitOrderParams LimitOrderParams: The parameters for the limit order.
     * @return The order index. If an order is not made `type(uint256).max` is returned instead.
     */
    function limitBidAfterClaim(ClaimOrderParams[] calldata claimParamsList, LimitOrderParams calldata limitOrderParams)
        external
        payable
        returns (uint256);

    /**
     * @notice Submits a limit ask order to the order book after claiming a list of orders.
     * @param claimParamsList Array of ClaimOrderParams: The list of orders to be claimed.
     * @param limitOrderParams LimitOrderParams: The parameters for the limit order.
     * @return The order index. If an order is not made `type(uint256).max` is returned instead.
     */
    function limitAskAfterClaim(ClaimOrderParams[] calldata claimParamsList, LimitOrderParams calldata limitOrderParams)
        external
        payable
        returns (uint256);

    /**
     * @notice Submits a market bid order to the order book after claiming a list of orders.
     * @param claimParamsList Array of ClaimOrderParams: The list of orders to be claimed.
     * @param marketOrderParams MarketOrderParams: The parameters for the market order.
     */
    function marketBidAfterClaim(
        ClaimOrderParams[] calldata claimParamsList,
        MarketOrderParams calldata marketOrderParams
    ) external payable;

    /**
     * @notice Submits a market ask order to the order book after claiming a list of orders.
     * @param claimParamsList Array of ClaimOrderParams: The list of orders to be claimed.
     * @param marketOrderParams MarketOrderParams: The parameters for the market order.
     */
    function marketAskAfterClaim(
        ClaimOrderParams[] calldata claimParamsList,
        MarketOrderParams calldata marketOrderParams
    ) external payable;
}