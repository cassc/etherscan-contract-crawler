pragma solidity ^0.5.16;

// Inheritance
import "../FuturesMarketBase.sol";

/**
 Mixin that implements OCO stop-loss / take-profit orders mechanism for the futures market.
 */
contract MixinFuturesOCOOrders is FuturesMarketBase {
    // oco order storage
    struct OCOOrder {
        int128 sizeDelta; // difference in position to pass to modifyPosition
        uint128 lowerPrice; // price for which the order is executed if the price falls
        uint128 upperPrice; // price for which the order is executed if the price climbs
        bool reduceOnly; // will prevent the system from increasing the position
        uint128 keeperDeposit; // the keeperDeposit paid upon submitting that needs to be paid / refunded on tx confirmation
        bytes32 trackingCode; // tracking code to emit on execution for volume source fee sharing
    }

    /// @dev Holds a mapping of accounts to orders. Only one order per account is supported
    mapping(address => OCOOrder) public ocoOrders;

    ///// Mutative methods

    /**
     * @notice submits a hybrid order to be filled at stop-loss / take-profit prices.
     * Reverts if a previous order still exists (wasn't executed or cancelled).
     * @param sizeDelta size in baseAsset (notional terms) of the order, similar to `modifyPosition` interface
     * @param lowerPrice must be less than the current price, marks the stop-loss / take-profit price for negative / positive sizeDelta
     * @param upperPrice must be greater than the current price, marks the take-profit / stop-loss price for negative / positive sizeDelta
     */
    function submitOCOOrder(int sizeDelta, uint lowerPrice, uint upperPrice, bool reduceOnly, bool simulate) external {
        _submitOCOOrder(sizeDelta, lowerPrice, upperPrice, reduceOnly, simulate, bytes32(0));
    }

    /// same as submitOCOOrder but emits an event with the tracking code
    /// to allow volume source fee sharing for integrations
    function submitOCOOrderWithTracking(int sizeDelta, uint lowerPrice, uint upperPrice, bool reduceOnly, bool simulate, bytes32 trackingCode) external {
        _submitOCOOrder(sizeDelta, lowerPrice, upperPrice, reduceOnly, simulate, trackingCode);
    }

    function _submitOCOOrder(int sizeDelta, uint lowerPrice, uint upperPrice, bool reduceOnly, bool simulate, bytes32 trackingCode) internal {
	require(lowerPrice < upperPrice && upperPrice <= uint128(-1) && (lowerPrice > 0 || upperPrice < uint128(-1)), "invalid price range");

        // check that a previous order doesn't exist
        require(ocoOrders[msg.sender].sizeDelta == 0, "previous order exists");

        // storage position as it's going to be modified to deduct keeperFee
        Position storage position = positions[msg.sender];

        uint price = _assetPriceRequireSystemChecks();
        require(lowerPrice < price && price < upperPrice, "price out of range");
        uint fundingIndex = _recomputeFunding(price);

        if (simulate) {
            // simulate the order with lower price and current market and check that the order doesn't revert
            if (lowerPrice > 0) {
                TradeParams memory params =
                    TradeParams({
                        sizeDelta: sizeDelta,
                        price: lowerPrice,
                        takerFee: _takerFee(marketKey),
                        makerFee: _makerFee(marketKey),
                        trackingCode: trackingCode
                    });
                (, , Status status) = _postTradeDetails(position, params);
                _revertIfError(status);
            }
            // simulate the order with upper price and current market and check that the order doesn't revert
            if (upperPrice < uint128(-1)) {
                TradeParams memory params =
                    TradeParams({
                        sizeDelta: sizeDelta,
                        price: upperPrice,
                        takerFee: _takerFee(marketKey),
                        makerFee: _makerFee(marketKey),
                        trackingCode: trackingCode
                    });
                (, , Status status) = _postTradeDetails(position, params);
                _revertIfError(status);
            }
        }

        // deduct fees from margin
        uint keeperDeposit = _minKeeperFee();
        _updatePositionMargin(position, price, -int(keeperDeposit));
        // emit event for modifying the position (subtracting the fees from margin)
        emit PositionModified(position.id, msg.sender, position.margin, position.size, 0, price, fundingIndex, 0);

        // create order
        OCOOrder memory order =
            OCOOrder({
                sizeDelta: int128(sizeDelta),
                lowerPrice: uint128(lowerPrice),
                upperPrice: uint128(upperPrice),
                reduceOnly: reduceOnly,
                keeperDeposit: uint128(keeperDeposit),
                trackingCode: trackingCode
            });
        // emit event
        emit OCOOrderSubmitted(
            msg.sender,
            order.sizeDelta,
            order.lowerPrice,
            order.upperPrice,
            order.reduceOnly,
            order.keeperDeposit,
            order.trackingCode
        );
        // store order
        ocoOrders[msg.sender] = order;
    }

    /**
     * @notice Cancels an existing OCO order.
     * Cancelling the order:
     * - Removes the stored order.
     * - keeperFee (deducted during submission) is refunded into margin.
     */
    function cancelOCOOrder() external {
        OCOOrder memory order = ocoOrders[msg.sender];
        // check that a previous order exists
        require(order.sizeDelta != 0, "no previous order");

        // refund keeper fee to margin
        Position storage position = positions[msg.sender];
        uint price = _assetPriceRequireSystemChecks();
        uint fundingIndex = _recomputeFunding(price);
        _updatePositionMargin(position, price, int(order.keeperDeposit));

        // emit event for modifying the position (add the fee to margin)
        emit PositionModified(position.id, msg.sender, position.margin, position.size, 0, price, fundingIndex, 0);

        // remove stored order
        delete ocoOrders[msg.sender];
        // emit event
        emit OCOOrderRemoved(
            msg.sender,
            order.sizeDelta,
            order.lowerPrice,
            order.upperPrice,
            order.reduceOnly,
            order.keeperDeposit,
            order.trackingCode
        );
    }

    /**
     * @notice Tries to execute a previously submitted OCO order.
     * Reverts if:
     * - There is no order
     * - Order fails for accounting reason (e.g. margin was removed, leverage exceeded, etc)
     * If order reverts, it has to be removed by calling cancelOCOOrder().
     * Anyone can call this method for any account.
     * If this is called by the account holder - the keeperFee is refunded into margin,
     *  otherwise it sent to the msg.sender.
     * @param account address of the account for which to try to execute a OCO order
     */
    function executeOCOOrder(address account) external {
        // important!: order  of the account, not the sender!
        OCOOrder memory order = ocoOrders[account];
        // check that a previous order exists
        require(order.sizeDelta != 0, "no previous order");

        // handle the fees and refunds according to the mechanism rules
        uint toRefund = 0;

        // refund keeperFee to margin if it's the account holder
        if (msg.sender == account) {
            toRefund += order.keeperDeposit;
        } else {
            _manager().issueSUSD(msg.sender, order.keeperDeposit);
        }

        Position storage position = positions[account];
        uint currentPrice = _assetPriceRequireSystemChecks();
        uint fundingIndex = _recomputeFunding(currentPrice);
        // possibly refund the keeperFee to the margin before executing the order
        // if the order later fails this is reverted of course
        _updatePositionMargin(position, currentPrice, int(toRefund));
        // emit event for modifying the position (refunding fee/s)
        emit PositionModified(position.id, account, position.margin, position.size, 0, currentPrice, fundingIndex, 0);

        // the correct price for condition
        uint executionPrice;
        if (currentPrice <= order.lowerPrice) {
            executionPrice = order.sizeDelta < 0 ? currentPrice : order.lowerPrice;
        } else if (currentPrice >= order.upperPrice) {
            executionPrice = order.sizeDelta > 0 ? currentPrice : order.upperPrice;
        } else {
            revert("price within order range");
        }
        // the correct size for condition
        int executionSize = order.sizeDelta;
        if (order.reduceOnly) {
            if (position.size > 0) {
                if (executionSize > 0) {
                    executionSize = 0;
                } else if (executionSize < -position.size) {
                    executionSize = -position.size;
                }
            } else if (position.size < 0) {
                if (executionSize < 0) {
                    executionSize = 0;
                } else if (executionSize > -position.size) {
                    executionSize = -position.size;
                }
            } else {
                executionSize = 0;
            }
        }
        // execute or revert
        if (executionSize != 0) {
            _trade(
                account,
                TradeParams({
                    sizeDelta: executionSize, // using the executionPrice from the range boundary
                    price: executionPrice, // the funding is applied only from order confirmation time
                    takerFee: _takerFee(marketKey),
                    makerFee: _makerFee(marketKey),
                    trackingCode: order.trackingCode
                })
            );
        }

        // remove stored order
        delete ocoOrders[account];
        // emit event
        emit OCOOrderRemoved(
            account,
            order.sizeDelta,
            order.lowerPrice,
            order.upperPrice,
            order.reduceOnly,
            order.keeperDeposit,
            order.trackingCode
        );
    }

    ///// Events
    event OCOOrderSubmitted(
        address indexed account,
        int sizeDelta,
        uint lowerPrice,
        uint upperPrice,
        bool reduceOnly,
        uint keeperDeposit,
        bytes32 trackingCode
    );

    event OCOOrderRemoved(
        address indexed account,
        int sizeDelta,
        uint lowerPrice,
        uint upperPrice,
        bool reduceOnly,
        uint keeperDeposit,
        bytes32 trackingCode
    );
}