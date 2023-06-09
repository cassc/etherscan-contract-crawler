/**
 *Submitted for verification at Etherscan.io on 2019-08-22
*/

/*

    Copyright 2019 The Hydro Protocol Foundation

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

        http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

*/

pragma solidity 0.5.8;
pragma experimental ABIEncoderV2;

contract GlobalStore {
    Store.State state;
}

contract ExternalFunctions is GlobalStore {

    ////////////////////////////
    // Batch Actions Function //
    ////////////////////////////

    function batch(
        BatchActions.Action[] memory actions
    )
        public
        payable
    {
        BatchActions.batch(state, actions, msg.value);
    }

    ////////////////////////
    // Signature Function //
    ////////////////////////

    function isValidSignature(
        bytes32 hash,
        address signerAddress,
        Types.Signature calldata signature
    )
        external
        pure
        returns (bool isValid)
    {
        isValid = Signature.isValidSignature(hash, signerAddress, signature);
    }

    ///////////////////////
    // Markets Functions //
    ///////////////////////

    function getAllMarketsCount()
        external
        view
        returns (uint256 count)
    {
        count = state.marketsCount;
    }

    function getAsset(address assetAddress)
        external
        view returns (Types.Asset memory asset)
    {
        Requires.requireAssetExist(state, assetAddress);
        asset = state.assets[assetAddress];
    }

    function getAssetOraclePrice(address assetAddress)
        external
        view
        returns (uint256 price)
    {
        Requires.requireAssetExist(state, assetAddress);
        price = AssemblyCall.getAssetPriceFromPriceOracle(
            address(state.assets[assetAddress].priceOracle),
            assetAddress
        );
    }

    function getMarket(uint16 marketID)
        external
        view
        returns (Types.Market memory market)
    {
        Requires.requireMarketIDExist(state, marketID);
        market = state.markets[marketID];
    }

    //////////////////////////////////
    // Collateral Account Functions //
    //////////////////////////////////

    function isAccountLiquidatable(
        address user,
        uint16 marketID
    )
        external
        view
        returns (bool isLiquidatable)
    {
        Requires.requireMarketIDExist(state, marketID);
        isLiquidatable = CollateralAccounts.getDetails(state, user, marketID).liquidatable;
    }

    function getAccountDetails(
        address user,
        uint16 marketID
    )
        external
        view
        returns (Types.CollateralAccountDetails memory details)
    {
        Requires.requireMarketIDExist(state, marketID);
        details = CollateralAccounts.getDetails(state, user, marketID);
    }

    function getAuctionsCount()
        external
        view
        returns (uint32 count)
    {
        count = state.auction.auctionsCount;
    }

    function getCurrentAuctions()
        external
        view
        returns (uint32[] memory)
    {
        return state.auction.currentAuctions;
    }

    function getAuctionDetails(uint32 auctionID)
        external
        view
        returns (Types.AuctionDetails memory details)
    {
        Requires.requireAuctionExist(state, auctionID);
        details = Auctions.getAuctionDetails(state, auctionID);
    }

    function fillAuctionWithAmount(
        uint32 auctionID,
        uint256 amount
    )
        external
    {
        Requires.requireAuctionExist(state, auctionID);
        Requires.requireAuctionNotFinished(state, auctionID);
        Auctions.fillAuctionWithAmount(state, auctionID, amount);
    }

    function liquidateAccount(
        address user,
        uint16 marketID
    )
        external
        returns (bool hasAuction, uint32 auctionID)
    {
        Requires.requireMarketIDExist(state, marketID);
        (hasAuction, auctionID) = Auctions.liquidate(state, user, marketID);
    }

    ///////////////////////////
    // LendingPool Functions //
    ///////////////////////////

    function getPoolCashableAmount(address asset)
        external
        view
        returns (uint256 cashableAmount)
    {
        if (asset == Consts.ETHEREUM_TOKEN_ADDRESS()) {
            cashableAmount = address(this).balance - uint256(state.cash[asset]);
        } else {
            cashableAmount = IStandardToken(asset).balanceOf(address(this)) - uint256(state.cash[asset]);
        }
    }

    function getIndex(address asset)
        external
        view
        returns (uint256 supplyIndex, uint256 borrowIndex)
    {
        return LendingPool.getCurrentIndex(state, asset);
    }

    function getTotalBorrow(address asset)
        external
        view
        returns (uint256 amount)
    {
        Requires.requireAssetExist(state, asset);
        amount = LendingPool.getTotalBorrow(state, asset);
    }

    function getTotalSupply(address asset)
        external
        view
        returns (uint256 amount)
    {
        Requires.requireAssetExist(state, asset);
        amount = LendingPool.getTotalSupply(state, asset);
    }

    function getAmountBorrowed(
        address asset,
        address user,
        uint16 marketID
    )
        external
        view
        returns (uint256 amount)
    {
        Requires.requireMarketIDExist(state, marketID);
        Requires.requireMarketIDAndAssetMatch(state, marketID, asset);
        amount = LendingPool.getAmountBorrowed(state, asset, user, marketID);
    }

    function getAmountSupplied(
        address asset,
        address user
    )
        external
        view
        returns (uint256 amount)
    {
        Requires.requireAssetExist(state, asset);
        amount = LendingPool.getAmountSupplied(state, asset, user);
    }

    function getInterestRates(
        address asset,
        uint256 extraBorrowAmount
    )
        external
        view
        returns (uint256 borrowInterestRate, uint256 supplyInterestRate)
    {
        Requires.requireAssetExist(state, asset);
        (borrowInterestRate, supplyInterestRate) = LendingPool.getInterestRates(state, asset, extraBorrowAmount);
    }

    function getInsuranceBalance(address asset)
        external
        view
        returns (uint256 amount)
    {
        Requires.requireAssetExist(state, asset);
        amount = state.pool.insuranceBalances[asset];
    }

    ///////////////////////
    // Relayer Functions //
    ///////////////////////

    function approveDelegate(address delegate)
        external
    {
        Relayer.approveDelegate(state, delegate);
    }

    function revokeDelegate(address delegate)
        external
    {
        Relayer.revokeDelegate(state, delegate);
    }

    function joinIncentiveSystem()
        external
    {
        Relayer.joinIncentiveSystem(state);
    }

    function exitIncentiveSystem()
        external
    {
        Relayer.exitIncentiveSystem(state);
    }

    function canMatchOrdersFrom(address relayer)
        external
        view
        returns (bool canMatch)
    {
        canMatch = Relayer.canMatchOrdersFrom(state, relayer);
    }

    function isParticipant(address relayer)
        external
        view
        returns (bool result)
    {
        result = Relayer.isParticipant(state, relayer);
    }

    ////////////////////////
    // Balances Functions //
    ////////////////////////

    function balanceOf(
        address asset,
        address user
    )
        external
        view
        returns (uint256 balance)
    {
        balance = Transfer.balanceOf(state,  BalancePath.getCommonPath(user), asset);
    }

    function marketBalanceOf(
        uint16 marketID,
        address asset,
        address user
    )
        external
        view
        returns (uint256 balance)
    {
        Requires.requireMarketIDExist(state, marketID);
        Requires.requireMarketIDAndAssetMatch(state, marketID, asset);
        balance = Transfer.balanceOf(state,  BalancePath.getMarketPath(user, marketID), asset);
    }

    function getMarketTransferableAmount(
        uint16 marketID,
        address asset,
        address user
    )
        external
        view
        returns (uint256 amount)
    {
        Requires.requireMarketIDExist(state, marketID);
        Requires.requireMarketIDAndAssetMatch(state, marketID, asset);
        amount = CollateralAccounts.getTransferableAmount(state, marketID, user, asset);
    }

    /** fallback function to allow deposit ether into this contract */
    function ()
        external
        payable
    {
        // deposit ${msg.value} ether for ${msg.sender}
        Transfer.deposit(
            state,
            Consts.ETHEREUM_TOKEN_ADDRESS(),
            msg.value
        );
    }

    ////////////////////////
    // Exchange Functions //
    ////////////////////////

    function cancelOrder(
        Types.Order calldata order
    )
        external
    {
        Exchange.cancelOrder(state, order);
    }

    function isOrderCancelled(
        bytes32 orderHash
    )
        external
        view
        returns(bool isCancelled)
    {
        isCancelled = state.exchange.cancelled[orderHash];
    }

    function matchOrders(
        Types.MatchParams memory params
    )
        public
    {
        Exchange.matchOrders(state, params);
    }

    function getDiscountedRate(
        address user
    )
        external
        view
        returns (uint256 rate)
    {
        rate = Discount.getDiscountedRate(state, user);
    }

    function getHydroTokenAddress()
        external
        view
        returns (address hydroTokenAddress)
    {
        hydroTokenAddress = state.exchange.hotTokenAddress;
    }

    function getOrderFilledAmount(
        bytes32 orderHash
    )
        external
        view
        returns (uint256 amount)
    {
        amount = state.exchange.filled[orderHash];
    }
}

library OperationsComponent {

    function createMarket(
        Store.State storage state,
        Types.Market memory market
    )
        public
    {
        Requires.requireMarketAssetsValid(state, market);
        Requires.requireMarketNotExist(state, market);
        Requires.requireDecimalLessOrEquanThanOne(market.auctionRatioStart);
        Requires.requireDecimalLessOrEquanThanOne(market.auctionRatioPerBlock);
        Requires.requireDecimalGreaterThanOne(market.liquidateRate);
        Requires.requireDecimalGreaterThanOne(market.withdrawRate);
        require(market.withdrawRate > market.liquidateRate, "WITHDARW_RATE_LESS_OR_EQUAL_THAN_LIQUIDATE_RATE");

        state.markets[state.marketsCount++] = market;
        Events.logCreateMarket(market);
    }

    function updateMarket(
        Store.State storage state,
        uint16 marketID,
        uint256 newAuctionRatioStart,
        uint256 newAuctionRatioPerBlock,
        uint256 newLiquidateRate,
        uint256 newWithdrawRate
    )
        external
    {
        Requires.requireMarketIDExist(state, marketID);
        Requires.requireDecimalLessOrEquanThanOne(newAuctionRatioStart);
        Requires.requireDecimalLessOrEquanThanOne(newAuctionRatioPerBlock);
        Requires.requireDecimalGreaterThanOne(newLiquidateRate);
        Requires.requireDecimalGreaterThanOne(newWithdrawRate);
        require(newWithdrawRate > newLiquidateRate, "WITHDARW_RATE_LESS_OR_EQUAL_THAN_LIQUIDATE_RATE");

        state.markets[marketID].auctionRatioStart = newAuctionRatioStart;
        state.markets[marketID].auctionRatioPerBlock = newAuctionRatioPerBlock;
        state.markets[marketID].liquidateRate = newLiquidateRate;
        state.markets[marketID].withdrawRate = newWithdrawRate;

        Events.logUpdateMarket(
            marketID,
            newAuctionRatioStart,
            newAuctionRatioPerBlock,
            newLiquidateRate,
            newWithdrawRate
        );
    }

    function setMarketBorrowUsability(
        Store.State storage state,
        uint16 marketID,
        bool   usability
    )
        external
    {
        Requires.requireMarketIDExist(state, marketID);
        state.markets[marketID].borrowEnable = usability;
        if (usability) {
            Events.logMarketBorrowDisable(
                marketID
            );
        } else {
            Events.logMarketBorrowEnable(
                marketID
            );
        }
    }

    function createAsset(
        Store.State storage state,
        address asset,
        address oracleAddress,
        address interestModelAddress,
        string calldata poolTokenName,
        string calldata poolTokenSymbol,
        uint8 poolTokenDecimals
    )
        external
    {
        Requires.requirePriceOracleAddressValid(oracleAddress);
        Requires.requireAssetNotExist(state, asset);

        LendingPool.initializeAssetLendingPool(state, asset);

        state.assets[asset].priceOracle = IPriceOracle(oracleAddress);
        state.assets[asset].interestModel = IInterestModel(interestModelAddress);
        state.assets[asset].lendingPoolToken = ILendingPoolToken(address(new LendingPoolToken(
            poolTokenName,
            poolTokenSymbol,
            poolTokenDecimals
        )));

        Events.logCreateAsset(
            asset,
            oracleAddress,
            address(state.assets[asset].lendingPoolToken),
            interestModelAddress
        );
    }

    function updateAsset(
        Store.State storage state,
        address asset,
        address oracleAddress,
        address interestModelAddress
    )
        external
    {
        Requires.requirePriceOracleAddressValid(oracleAddress);
        Requires.requireAssetExist(state, asset);

        state.assets[asset].priceOracle = IPriceOracle(oracleAddress);
        state.assets[asset].interestModel = IInterestModel(interestModelAddress);

        Events.logUpdateAsset(
            asset,
            oracleAddress,
            interestModelAddress
        );
    }

    /**
     * @param newConfig A data blob representing the new discount config. Details on format above.
     */
    function updateDiscountConfig(
        Store.State storage state,
        bytes32 newConfig
    )
        external
    {
        state.exchange.discountConfig = newConfig;
        Events.logUpdateDiscountConfig(newConfig);
    }

    function updateAuctionInitiatorRewardRatio(
        Store.State storage state,
        uint256 newInitiatorRewardRatio
    )
        external
    {
        Requires.requireDecimalLessOrEquanThanOne(newInitiatorRewardRatio);

        state.auction.initiatorRewardRatio = newInitiatorRewardRatio;
        Events.logUpdateAuctionInitiatorRewardRatio(newInitiatorRewardRatio);
    }

    function updateInsuranceRatio(
        Store.State storage state,
        uint256 newInsuranceRatio
    )
        external
    {
        Requires.requireDecimalLessOrEquanThanOne(newInsuranceRatio);

        state.pool.insuranceRatio = newInsuranceRatio;
        Events.logUpdateInsuranceRatio(newInsuranceRatio);
    }
}

library Discount {
    using SafeMath for uint256;

    /**
     * Calculate and return the rate at which fees will be charged for an address. The discounted
     * rate depends on how much HOT token is owned by the user. Values returned will be a percentage
     * used to calculate how much of the fee is paid, so a return value of 100 means there is 0
     * discount, and a return value of 70 means a 30% rate reduction.
     *
     * The discountConfig is defined as such:
     * ╔═══════════════════╤════════════════════════════════════════════╗
     * ║                   │ length(bytes)   desc                       ║
     * ╟───────────────────┼────────────────────────────────────────────╢
     * ║ count             │ 1               the count of configs       ║
     * ║ maxDiscountedRate │ 1               the max discounted rate    ║
     * ║ config            │ 5 each                                     ║
     * ╚═══════════════════╧════════════════════════════════════════════╝
     *
     * The default discount structure as defined in code would give the following result:
     *
     * Fee discount table
     * ╔════════════════════╤══════════╗
     * ║     HOT BALANCE    │ DISCOUNT ║
     * ╠════════════════════╪══════════╣
     * ║     0 <= x < 10000 │     0%   ║
     * ╟────────────────────┼──────────╢
     * ║ 10000 <= x < 20000 │    10%   ║
     * ╟────────────────────┼──────────╢
     * ║ 20000 <= x < 30000 │    20%   ║
     * ╟────────────────────┼──────────╢
     * ║ 30000 <= x < 40000 │    30%   ║
     * ╟────────────────────┼──────────╢
     * ║ 40000 <= x         │    40%   ║
     * ╚════════════════════╧══════════╝
     *
     * Breaking down the bytes of 0x043c000027106400004e205a000075305000009c404600000000000000000000
     *
     * 0x  04           3c          0000271064  00004e205a  0000753050  00009c4046  0000000000  0000000000;
     *     ~~           ~~          ~~~~~~~~~~  ~~~~~~~~~~  ~~~~~~~~~~  ~~~~~~~~~~  ~~~~~~~~~~  ~~~~~~~~~~
     *      |            |               |           |           |           |           |           |
     *    count  maxDiscountedRate       1           2           3           4           5           6
     *
     * The first config breaks down as follows:  00002710   64
     *                                           ~~~~~~~~   ~~
     *                                               |      |
     *                                              bar    rate
     *
     * Meaning if a user has less than 10000 (0x00002710) HOT, they will pay 100%(0x64) of the
     * standard fee.
     *
     * @param  user The user address to calculate a fee discount for.
     * @return      The percentage of the regular fee this user will pay.
     */
    function getDiscountedRate(
        Store.State storage state,
        address user
    )
        internal
        view
        returns (uint256 result)
    {
        uint256 hotBalance = AssemblyCall.getHotBalance(
            state.exchange.hotTokenAddress,
            user
        );

        if (hotBalance == 0) {
            return Consts.DISCOUNT_RATE_BASE();
        }

        bytes32 config = state.exchange.discountConfig;
        uint256 count = uint256(uint8(byte(config)));
        uint256 bar;

        // HOT Token has 18 decimals
        hotBalance = hotBalance.div(10**18);

        for (uint256 i = 0; i < count; i++) {
            bar = uint256(uint32(bytes4(config << (2 + i * 5) * 8)));

            if (hotBalance < bar) {
                result = uint256(uint8(byte(config << (2 + i * 5 + 4) * 8)));
                break;
            }
        }

        // If we haven't found a rate in the config yet, use the maximum rate.
        if (result == 0) {
            result = uint256(uint8(config[1]));
        }

        // Make sure our discount algorithm never returns a higher rate than the base.
        require(result <= Consts.DISCOUNT_RATE_BASE(), "DISCOUNT_ERROR");
    }
}

library Exchange {
    using SafeMath for uint256;
    using Order for Types.Order;
    using OrderParam for Types.OrderParam;

    uint256 private constant EXCHANGE_FEE_RATE_BASE = 100000;
    uint256 private constant SUPPORTED_ORDER_VERSION = 2;

    /**
     * Calculated data about an order object.
     * Generally the filledAmount is specified in base token units, however in the case of a market
     * buy order the filledAmount is specified in quote token units.
     */
    struct OrderInfo {
        bytes32 orderHash;
        uint256 filledAmount;
        Types.BalancePath balancePath;
    }

    /**
     * Match taker order to a list of maker orders. Common addresses are passed in
     * separately as an Types.OrderAddressSet to reduce call size data and save gas.
     */
    function matchOrders(
        Store.State storage state,
        Types.MatchParams memory params
    )
        internal
    {
        require(Relayer.canMatchOrdersFrom(state, params.orderAddressSet.relayer), "INVALID_SENDER");
        require(!params.takerOrderParam.isMakerOnly(), "MAKER_ONLY_ORDER_CANNOT_BE_TAKER");

        bool isParticipantRelayer = Relayer.isParticipant(state, params.orderAddressSet.relayer);
        uint256 takerFeeRate = getTakerFeeRate(state, params.takerOrderParam, isParticipantRelayer);
        OrderInfo memory takerOrderInfo = getOrderInfo(state, params.takerOrderParam, params.orderAddressSet);

        // Calculate which orders match for settlement.
        Types.MatchResult[] memory results = new Types.MatchResult[](params.makerOrderParams.length);

        for (uint256 i = 0; i < params.makerOrderParams.length; i++) {
            require(!params.makerOrderParams[i].isMarketOrder(), "MAKER_ORDER_CAN_NOT_BE_MARKET_ORDER");
            require(params.takerOrderParam.isSell() != params.makerOrderParams[i].isSell(), "INVALID_SIDE");
            validatePrice(params.takerOrderParam, params.makerOrderParams[i]);

            OrderInfo memory makerOrderInfo = getOrderInfo(state, params.makerOrderParams[i], params.orderAddressSet);

            results[i] = getMatchResult(
                state,
                params.takerOrderParam,
                takerOrderInfo,
                params.makerOrderParams[i],
                makerOrderInfo,
                params.baseAssetFilledAmounts[i],
                takerFeeRate,
                isParticipantRelayer
            );

            // Update amount filled for this maker order.
            state.exchange.filled[makerOrderInfo.orderHash] = makerOrderInfo.filledAmount;
        }

        // Update amount filled for this taker order.
        state.exchange.filled[takerOrderInfo.orderHash] = takerOrderInfo.filledAmount;

        settleResults(state, results, params.takerOrderParam, params.orderAddressSet);
    }

    /**
     * Cancels an order, preventing it from being matched. In practice, matching mode relayers will
     * generally handle cancellation off chain by removing the order from their system, however if
     * the trader wants to ensure the order never goes through, or they no longer trust the relayer,
     * this function may be called to block it from ever matching at the contract level.
     *
     * Emits a Cancel event on success.
     *
     * @param order The order to be cancelled.
     */
    function cancelOrder(
        Store.State storage state,
        Types.Order memory order
    )
        internal
    {
        require(order.trader == msg.sender, "INVALID_TRADER");

        bytes32 orderHash = order.getHash();
        state.exchange.cancelled[orderHash] = true;

        Events.logOrderCancel(orderHash);
    }

    /**
     * Calculates current state of the order. Will revert transaction if this order is not
     * fillable for any reason, or if the order signature is invalid.
     *
     * @param orderParam The Types.OrderParam object containing Order data.
     * @param orderAddressSet An object containing addresses common across each order.
     * @return An OrderInfo object containing the hash and current amount filled
     */
    function getOrderInfo(
        Store.State storage state,
        Types.OrderParam memory orderParam,
        Types.OrderAddressSet memory orderAddressSet
    )
        private
        view
        returns (OrderInfo memory orderInfo)
    {
        require(orderParam.getOrderVersion() == SUPPORTED_ORDER_VERSION, "ORDER_VERSION_NOT_SUPPORTED");

        Types.Order memory order = getOrderFromOrderParam(orderParam, orderAddressSet);
        orderInfo.orderHash = order.getHash();
        orderInfo.filledAmount = state.exchange.filled[orderInfo.orderHash];
        uint8 status = uint8(Types.OrderStatus.FILLABLE);

        if (!orderParam.isMarketBuy() && orderInfo.filledAmount >= order.baseAssetAmount) {
            status = uint8(Types.OrderStatus.FULLY_FILLED);
        } else if (orderParam.isMarketBuy() && orderInfo.filledAmount >= order.quoteAssetAmount) {
            status = uint8(Types.OrderStatus.FULLY_FILLED);
        } else if (block.timestamp >= orderParam.getExpiredAtFromOrderData()) {
            status = uint8(Types.OrderStatus.EXPIRED);
        } else if (state.exchange.cancelled[orderInfo.orderHash]) {
            status = uint8(Types.OrderStatus.CANCELLED);
        }

        require(
            status == uint8(Types.OrderStatus.FILLABLE),
            "ORDER_IS_NOT_FILLABLE"
        );

        require(
            Signature.isValidSignature(orderInfo.orderHash, orderParam.trader, orderParam.signature),
            "INVALID_ORDER_SIGNATURE"
        );

        orderInfo.balancePath = orderParam.getBalancePathFromOrderData();
        Requires.requirePathNormalStatus(state, orderInfo.balancePath);

        return orderInfo;
    }

    /**
     * Reconstruct an Order object from the given Types.OrderParam and Types.OrderAddressSet objects.
     *
     * @param orderParam The Types.OrderParam object containing the Order data.
     * @param orderAddressSet An object containing addresses common across each order.
     * @return The reconstructed Order object.
     */
    function getOrderFromOrderParam(
        Types.OrderParam memory orderParam,
        Types.OrderAddressSet memory orderAddressSet
    )
        private
        pure
        returns (Types.Order memory order)
    {
        order.trader = orderParam.trader;
        order.baseAssetAmount = orderParam.baseAssetAmount;
        order.quoteAssetAmount = orderParam.quoteAssetAmount;
        order.gasTokenAmount = orderParam.gasTokenAmount;
        order.data = orderParam.data;
        order.baseAsset = orderAddressSet.baseAsset;
        order.quoteAsset = orderAddressSet.quoteAsset;
        order.relayer = orderAddressSet.relayer;
    }

    /**
     * Validates that the maker and taker orders can be matched based on the listed prices.
     *
     * If the taker submitted a sell order, the matching maker order must have a price greater than
     * or equal to the price the taker is willing to sell for.
     *
     * Since the price of an order is computed by order.quoteAssetAmount / order.baseAssetAmount
     * we can establish the following formula:
     *
     *    takerOrder.quoteAssetAmount        makerOrder.quoteAssetAmount
     *   -----------------------------  <=  -----------------------------
     *     takerOrder.baseAssetAmount        makerOrder.baseAssetAmount
     *
     * To avoid precision loss from division, we modify the formula to avoid division entirely.
     * In shorthand, this becomes:
     *
     *   takerOrder.quote * makerOrder.base <= takerOrder.base * makerOrder.quote
     *
     * We can apply this same process to buy orders - if the taker submitted a buy order then
     * the matching maker order must have a price less than or equal to the price the taker is
     * willing to pay. This means we can use the same result as above, but simply flip the
     * sign of the comparison operator.
     *
     * The function will revert the transaction if the orders cannot be matched.
     *
     * @param takerOrderParam The Types.OrderParam object representing the taker's order data
     * @param makerOrderParam The Types.OrderParam object representing the maker's order data
     */
    function validatePrice(
        Types.OrderParam memory takerOrderParam,
        Types.OrderParam memory makerOrderParam
    )
        private
        pure
    {
        uint256 left = takerOrderParam.quoteAssetAmount.mul(makerOrderParam.baseAssetAmount);
        uint256 right = takerOrderParam.baseAssetAmount.mul(makerOrderParam.quoteAssetAmount);
        require(takerOrderParam.isSell() ? left <= right : left >= right, "INVALID_MATCH");
    }

    /**
     * Construct a Types.MatchResult from matching taker and maker order data, which will be used when
     * settling the orders and transferring token.
     *
     * @param takerOrderParam The Types.OrderParam object representing the taker's order data
     * @param takerOrderInfo The OrderInfo object representing the current taker order state
     * @param makerOrderParam The Types.OrderParam object representing the maker's order data
     * @param makerOrderInfo The OrderInfo object representing the current maker order state
     * @param takerFeeRate The rate used to calculate the fee charged to the taker
     * @param isParticipantRelayer Whether this relayer is participating in hot discount
     * @return Types.MatchResult object containing data that will be used during order settlement.
     */
    function getMatchResult(
        Store.State storage state,
        Types.OrderParam memory takerOrderParam,
        OrderInfo memory takerOrderInfo,
        Types.OrderParam memory makerOrderParam,
        OrderInfo memory makerOrderInfo,
        uint256 baseAssetFilledAmount,
        uint256 takerFeeRate,
        bool isParticipantRelayer
    )
        private
        view
        returns (Types.MatchResult memory result)
    {
        result.baseAssetFilledAmount = baseAssetFilledAmount;
        result.quoteAssetFilledAmount = convertBaseToQuote(makerOrderParam, baseAssetFilledAmount);

        result.takerBalancePath = takerOrderInfo.balancePath;
        result.makerBalancePath = makerOrderInfo.balancePath;

        // Each order only pays gas once, so only pay gas when nothing has been filled yet.
        if (takerOrderInfo.filledAmount == 0) {
            result.takerGasFee = takerOrderParam.gasTokenAmount;
        }

        if (makerOrderInfo.filledAmount == 0) {
            result.makerGasFee = makerOrderParam.gasTokenAmount;
        }

        if(!takerOrderParam.isMarketBuy()) {
            takerOrderInfo.filledAmount = takerOrderInfo.filledAmount.add(result.baseAssetFilledAmount);
            require(takerOrderInfo.filledAmount <= takerOrderParam.baseAssetAmount, "TAKER_ORDER_OVER_MATCH");
        } else {
            takerOrderInfo.filledAmount = takerOrderInfo.filledAmount.add(result.quoteAssetFilledAmount);
            require(takerOrderInfo.filledAmount <= takerOrderParam.quoteAssetAmount, "TAKER_ORDER_OVER_MATCH");
        }

        makerOrderInfo.filledAmount = makerOrderInfo.filledAmount.add(result.baseAssetFilledAmount);
        require(makerOrderInfo.filledAmount <= makerOrderParam.baseAssetAmount, "MAKER_ORDER_OVER_MATCH");

        result.maker = makerOrderParam.trader;
        result.taker = takerOrderParam.trader;

        if(takerOrderParam.isSell()) {
            result.buyer = result.maker;
        } else {
            result.buyer = result.taker;
        }

        uint256 rebateRate = makerOrderParam.getMakerRebateRateFromOrderData();

        if (rebateRate > 0) {
            // If the rebate rate is not zero, maker pays no fees.
            result.makerFee = 0;

            // RebateRate will never exceed REBATE_RATE_BASE, so rebateFee will never exceed the fees paid by the taker.
            result.makerRebate = result.quoteAssetFilledAmount.mul(takerFeeRate).mul(rebateRate).div(
                EXCHANGE_FEE_RATE_BASE.mul(Consts.DISCOUNT_RATE_BASE()).mul(Consts.REBATE_RATE_BASE())
            );
        } else {
            uint256 makerRawFeeRate = makerOrderParam.getAsMakerFeeRateFromOrderData();
            result.makerRebate = 0;

            // maker fee will be reduced, but still >= 0
            uint256 makerFeeRate = getFinalFeeRate(
                state,
                makerOrderParam.trader,
                makerRawFeeRate,
                isParticipantRelayer
            );

            result.makerFee = result.quoteAssetFilledAmount.mul(makerFeeRate).div(
                EXCHANGE_FEE_RATE_BASE.mul(Consts.DISCOUNT_RATE_BASE())
            );
        }

        result.takerFee = result.quoteAssetFilledAmount.mul(takerFeeRate).div(
            EXCHANGE_FEE_RATE_BASE.mul(Consts.DISCOUNT_RATE_BASE())
        );
    }

    /**
     * Get the rate used to calculate the taker fee.
     *
     * @param orderParam The Types.OrderParam object representing the taker order data.
     * @param isParticipantRelayer Whether this relayer is participating in hot discount.
     * @return The final potentially discounted rate to use for the taker fee.
     */
    function getTakerFeeRate(
        Store.State storage state,
        Types.OrderParam memory orderParam,
        bool isParticipantRelayer
    )
        private
        view
        returns(uint256)
    {
        uint256 rawRate = orderParam.getAsTakerFeeRateFromOrderData();
        return getFinalFeeRate(state, orderParam.trader, rawRate, isParticipantRelayer);
    }

    /**
     * Take a fee rate and calculate the potentially discounted rate for this trader based on
     * HOT token ownership.
     *
     * @param trader The address of the trader who made the order.
     * @param rate The raw rate which we will discount if needed.
     * @param isParticipantRelayer Whether this relayer is participating in hot discount.
     * @return The final potentially discounted rate.
     */
    function getFinalFeeRate(
        Store.State storage state,
        address trader,
        uint256 rate,
        bool isParticipantRelayer
    )
        private
        view
        returns(uint256)
    {
        if (isParticipantRelayer) {
            return rate.mul(Discount.getDiscountedRate(state, trader));
        } else {
            return rate.mul(Consts.DISCOUNT_RATE_BASE());
        }
    }

    /**
     * Take an amount and convert it from base token units to quote token units based on the price
     * in the order param.
     *
     * @param orderParam The Types.OrderParam object containing the Order data.
     * @param amount An amount of base token.
     * @return The converted amount in quote token units.
     */
    function convertBaseToQuote(
        Types.OrderParam memory orderParam,
        uint256 amount
    )
        private
        pure
        returns (uint256)
    {
        return SafeMath.getPartialAmountFloor(
            orderParam.quoteAssetAmount,
            orderParam.baseAssetAmount,
            amount
        );
    }

    /**
     * Take a list of matches and settle them with the taker order, transferring tokens all tokens
     * and paying all fees necessary to complete the transaction.
     *
     * Settles a order given a list of Types.MatchResult objects. A naive approach would be to take
     * each result, have the taker and maker transfer the appropriate tokens, and then have them
     * each send the appropriate fees to the relayer, meaning that for n makers there would be 4n
     * transactions.
     *
     * Instead we do the following:
     *
     * For a match which has a taker as seller:
     *  - Taker transfers the required base token to each maker
     *  - Each maker sends an amount of quote token to the taker equal to:
     *    [Amount owed to taker] + [Maker fee] + [Maker gas cost] - [Maker rebate amount]
     *  - Since the taker has received all the maker fees and gas costs, it can then send them along
     *    with taker fees in a single batch transaction to the relayer, equal to:
     *    [All maker and taker fees] + [All maker and taker gas costs] - [All maker rebates]
     *
     * Thus in the end the taker will have the full amount of quote token, sans the fee and cost of
     * their share of gas. Each maker will have their share of base token, sans the fee and cost of
     * their share of gas, and will keep their rebate in quote token. The relayer will end up with
     * the fees from the taker and each maker (sans rebate), and the gas costs will pay for the
     * transactions.
     *
     * For a match which has a taker as buyer:
     *  - Each maker transfers base tokens to the taker
     *  - The taker sends an amount of quote tokens to each maker equal to:
     *    [Amount owed to maker] + [Maker rebate amount] - [Maker fee] - [Maker gas cost]
     *  - Since the taker saved all the maker fees and gas costs, it can then send them as a single
     *    batch transaction to the relayer, equal to:
     *    [All maker and taker fees] + [All maker and taker gas costs] - [All maker rebates]
     *
     * Thus in the end the taker will have the full amount of base token, sans the fee and cost of
     * their share of gas. Each maker will have their share of quote token, including their rebate,
     * but sans the fee and cost of their share of gas. The relayer will end up with the fees from
     * the taker and each maker (sans rebates), and the gas costs will pay for the transactions.
     *
     * In this scenario, with n makers there will be 2n + 1 transactions, which will be a significant
     * gas savings over the original method.
     *
     * @param results List of Types.MatchResult objects representing each individual trade to settle.
     * @param takerOrderParam The Types.OrderParam object representing the taker order data.
     * @param orderAddressSet An object containing addresses common across each order.
     */
    function settleResults(
        Store.State storage state,
        Types.MatchResult[] memory results,
        Types.OrderParam memory takerOrderParam,
        Types.OrderAddressSet memory orderAddressSet
    )
        private
    {
        bool isTakerSell = takerOrderParam.isSell();

        uint256 totalFee = 0;

        Types.BalancePath memory relayerBalancePath = Types.BalancePath({
            user: orderAddressSet.relayer,
            marketID: 0,
            category: Types.BalanceCategory.Common
        });

        for (uint256 i = 0; i < results.length; i++) {
            Transfer.transfer(
                state,
                orderAddressSet.baseAsset,
                isTakerSell ? results[i].takerBalancePath : results[i].makerBalancePath,
                isTakerSell ? results[i].makerBalancePath : results[i].takerBalancePath,
                results[i].baseAssetFilledAmount
            );

            uint256 transferredQuoteAmount;

            if(isTakerSell) {
                transferredQuoteAmount = results[i].quoteAssetFilledAmount.
                    add(results[i].makerFee).
                    add(results[i].makerGasFee).
                    sub(results[i].makerRebate);
            } else {
                transferredQuoteAmount = results[i].quoteAssetFilledAmount.
                    sub(results[i].makerFee).
                    sub(results[i].makerGasFee).
                    add(results[i].makerRebate);
            }

            Transfer.transfer(
                state,
                orderAddressSet.quoteAsset,
                isTakerSell ? results[i].makerBalancePath : results[i].takerBalancePath,
                isTakerSell ? results[i].takerBalancePath : results[i].makerBalancePath,
                transferredQuoteAmount
            );

            Requires.requireCollateralAccountNotLiquidatable(state, results[i].makerBalancePath);

            totalFee = totalFee.add(results[i].takerFee).add(results[i].makerFee);
            totalFee = totalFee.add(results[i].makerGasFee).add(results[i].takerGasFee);
            totalFee = totalFee.sub(results[i].makerRebate);

            Events.logMatch(results[i], orderAddressSet);
        }

        Transfer.transfer(
            state,
            orderAddressSet.quoteAsset,
            results[0].takerBalancePath,
            relayerBalancePath,
            totalFee
        );

        Requires.requireCollateralAccountNotLiquidatable(state, results[0].takerBalancePath);
    }
}

library Relayer {
    /**
     * Approve an address to match orders on behalf of msg.sender
     */
    function approveDelegate(
        Store.State storage state,
        address delegate
    )
        internal
    {
        state.relayer.relayerDelegates[msg.sender][delegate] = true;
        Events.logRelayerApproveDelegate(msg.sender, delegate);
    }

    /**
     * Revoke an existing delegate
     */
    function revokeDelegate(
        Store.State storage state,
        address delegate
    )
        internal
    {
        state.relayer.relayerDelegates[msg.sender][delegate] = false;
        Events.logRelayerRevokeDelegate(msg.sender, delegate);
    }

    /**
     * @return true if msg.sender is allowed to match orders which belong to relayer
     */
    function canMatchOrdersFrom(
        Store.State storage state,
        address relayer
    )
        internal
        view
        returns(bool)
    {
        return msg.sender == relayer || state.relayer.relayerDelegates[relayer][msg.sender] == true;
    }

    /**
     * Join the Hydro incentive system.
     */
    function joinIncentiveSystem(
        Store.State storage state
    )
        internal
    {
        delete state.relayer.hasExited[msg.sender];
        Events.logRelayerJoin(msg.sender);
    }

    /**
     * Exit the Hydro incentive system.
     * For relayers that choose to opt-out, the Hydro Protocol
     * effective becomes a tokenless protocol.
     */
    function exitIncentiveSystem(
        Store.State storage state
    )
        internal
    {
        state.relayer.hasExited[msg.sender] = true;
        Events.logRelayerExit(msg.sender);
    }

    /**
     * @return true if relayer is participating in the Hydro incentive system.
     */
    function isParticipant(
        Store.State storage state,
        address relayer
    )
        internal
        view
        returns(bool)
    {
        return !state.relayer.hasExited[relayer];
    }
}

library Auctions {
    using SafeMath for uint256;
    using SafeMath for int256;
    using Auction for Types.Auction;

    /**
     * Liquidate a collateral account
     */
    function liquidate(
        Store.State storage state,
        address user,
        uint16 marketID
    )
        external
        returns (bool, uint32)
    {
        // if the account is in liquidate progress, liquidatable will be false
        Types.CollateralAccountDetails memory details = CollateralAccounts.getDetails(
            state,
            user,
            marketID
        );

        require(details.liquidatable, "ACCOUNT_NOT_LIQUIDABLE");

        Types.Market storage market = state.markets[marketID];
        Types.CollateralAccount storage account = state.accounts[user][marketID];

        LendingPool.repay(
            state,
            user,
            marketID,
            market.baseAsset,
            account.balances[market.baseAsset]
        );

        LendingPool.repay(
            state,
            user,
            marketID,
            market.quoteAsset,
            account.balances[market.quoteAsset]
        );

        address collateralAsset;
        address debtAsset;

        uint256 leftBaseAssetDebt = LendingPool.getAmountBorrowed(
            state,
            market.baseAsset,
            user,
            marketID
        );

        uint256 leftQuoteAssetDebt = LendingPool.getAmountBorrowed(
            state,
            market.quoteAsset,
            user,
            marketID
        );

        bool hasAution = !(leftBaseAssetDebt == 0 && leftQuoteAssetDebt == 0);

        Events.logLiquidate(
            user,
            marketID,
            hasAution
        );

        if (!hasAution) {
            // no auction
            return (false, 0);
        }

        account.status = Types.CollateralAccountStatus.Liquid;

        if(account.balances[market.baseAsset] > 0) {
            // quote asset is debt, base asset is collateral
            collateralAsset = market.baseAsset;
            debtAsset = market.quoteAsset;
        } else {
            // base asset is debt, quote asset is collateral
            collateralAsset = market.quoteAsset;
            debtAsset = market.baseAsset;
        }

        uint32 newAuctionID = create(
            state,
            marketID,
            user,
            msg.sender,
            debtAsset,
            collateralAsset
        );

        return (true, newAuctionID);
    }

    function fillHealthyAuction(
        Store.State storage state,
        Types.Auction storage auction,
        uint256 ratio,
        uint256 repayAmount
    )
        private
        returns (uint256, uint256) // bidderRepay collateral
    {
        uint256 leftDebtAmount = LendingPool.getAmountBorrowed(
            state,
            auction.debtAsset,
            auction.borrower,
            auction.marketID
        );

        // get remaining collateral
        uint256 leftCollateralAmount = state.accounts[auction.borrower][auction.marketID].balances[auction.collateralAsset];

        state.accounts[auction.borrower][auction.marketID].balances[auction.debtAsset] = repayAmount;

        // borrower pays back to the lending pool
        uint256 actualRepayAmount = LendingPool.repay(
            state,
            auction.borrower,
            auction.marketID,
            auction.debtAsset,
            repayAmount
        );

        state.accounts[auction.borrower][auction.marketID].balances[auction.debtAsset] = 0;

        // compute how much collateral is divided up amongst the bidder, auction initiator, and borrower
        state.balances[msg.sender][auction.debtAsset] = SafeMath.sub(
            state.balances[msg.sender][auction.debtAsset],
            actualRepayAmount
        );

        uint256 collateralToProcess = leftCollateralAmount.mul(actualRepayAmount).div(leftDebtAmount);
        uint256 collateralForBidder = Decimal.mulFloor(collateralToProcess, ratio);

        uint256 collateralForInitiator = Decimal.mulFloor(collateralToProcess.sub(collateralForBidder), state.auction.initiatorRewardRatio);
        uint256 collateralForBorrower = collateralToProcess.sub(collateralForBidder).sub(collateralForInitiator);

        // update remaining collateral ammount
        state.accounts[auction.borrower][auction.marketID].balances[auction.collateralAsset] = SafeMath.sub(
            state.accounts[auction.borrower][auction.marketID].balances[auction.collateralAsset],
            collateralToProcess
        );

        // send a portion of collateral to the bidder
        state.balances[msg.sender][auction.collateralAsset] = SafeMath.add(
            state.balances[msg.sender][auction.collateralAsset],
            collateralForBidder
        );

        // send a portion of collateral to the initiator
        state.balances[auction.initiator][auction.collateralAsset] = SafeMath.add(
            state.balances[auction.initiator][auction.collateralAsset],
            collateralForInitiator
        );

        // send a portion of collateral to the borrower
        state.balances[auction.borrower][auction.collateralAsset] = SafeMath.add(
            state.balances[auction.borrower][auction.collateralAsset],
            collateralForBorrower
        );

        // withdraw collateralForBorrower to borrower's wallet account
        Transfer.withdraw(
            state,
            auction.borrower,
            auction.collateralAsset,
            collateralForBorrower
        );

        return (actualRepayAmount, collateralForBidder);
    }

    /**
     * Msg.sender only need to afford bidderRepayAmount and get collateralAmount
     * insurance and suppliers will cover the badDebtAmount
     */
    function fillBadAuction(
        Store.State storage state,
        Types.Auction storage auction,
        uint256 ratio,
        uint256 bidderRepayAmount
    )
        private
        returns (uint256, uint256, uint256) // totalRepay bidderRepay collateral
    {

        uint256 leftDebtAmount = LendingPool.getAmountBorrowed(
            state,
            auction.debtAsset,
            auction.borrower,
            auction.marketID
        );

        uint256 leftCollateralAmount = state.accounts[auction.borrower][auction.marketID].balances[auction.collateralAsset];

        uint256 repayAmount = Decimal.mulFloor(bidderRepayAmount, ratio);

        state.accounts[auction.borrower][auction.marketID].balances[auction.debtAsset] = repayAmount;

        uint256 actualRepayAmount = LendingPool.repay(
            state,
            auction.borrower,
            auction.marketID,
            auction.debtAsset,
            repayAmount
        );

        state.accounts[auction.borrower][auction.marketID].balances[auction.debtAsset] = 0; // recover unused principal

        uint256 actualBidderRepay = bidderRepayAmount;

        if (actualRepayAmount < repayAmount) {
            actualBidderRepay = Decimal.divCeil(actualRepayAmount, ratio);
        }

        // gather repay capital
        LendingPool.claimInsurance(state, auction.debtAsset, actualRepayAmount.sub(actualBidderRepay));

        state.balances[msg.sender][auction.debtAsset] = SafeMath.sub(
            state.balances[msg.sender][auction.debtAsset],
            actualBidderRepay
        );

        // update collateralAmount
        uint256 collateralForBidder = leftCollateralAmount.mul(actualRepayAmount).div(leftDebtAmount);

        state.accounts[auction.borrower][auction.marketID].balances[auction.collateralAsset] = SafeMath.sub(
            state.accounts[auction.borrower][auction.marketID].balances[auction.collateralAsset],
            collateralForBidder
        );

        // bidder receive collateral
        state.balances[msg.sender][auction.collateralAsset] = SafeMath.add(
            state.balances[msg.sender][auction.collateralAsset],
            collateralForBidder
        );

        return (actualRepayAmount, actualBidderRepay, collateralForBidder);
    }

    // ensure repay no more than repayAmount
    function fillAuctionWithAmount(
        Store.State storage state,
        uint32 auctionID,
        uint256 repayAmount
    )
        external
    {
        Types.Auction storage auction = state.auction.auctions[auctionID];
        uint256 ratio = auction.ratio(state);

        uint256 actualRepayAmount;
        uint256 actualBidderRepayAmount;
        uint256 collateralForBidder;

        if (ratio <= Decimal.one()) {
            (actualRepayAmount, collateralForBidder) = fillHealthyAuction(state, auction, ratio, repayAmount);
            actualBidderRepayAmount = actualRepayAmount;
        } else {
            (actualRepayAmount, actualBidderRepayAmount, collateralForBidder) = fillBadAuction(state, auction, ratio, repayAmount);
        }

        // reset account state if all debts are paid
        uint256 leftDebtAmount = LendingPool.getAmountBorrowed(
            state,
            auction.debtAsset,
            auction.borrower,
            auction.marketID
        );

        Events.logFillAuction(auction.id, msg.sender, actualRepayAmount, actualBidderRepayAmount, collateralForBidder, leftDebtAmount);

        if (leftDebtAmount == 0) {
            endAuction(state, auction);
        }
    }

    /**
     * Mark an auction as finished.
     * An auction typically ends either when it becomes fully filled, or when it expires and is closed
     */
    function endAuction(
        Store.State storage state,
        Types.Auction storage auction
    )
        private
    {
        auction.status = Types.AuctionStatus.Finished;

        state.accounts[auction.borrower][auction.marketID].status = Types.CollateralAccountStatus.Normal;

        for (uint i = 0; i < state.auction.currentAuctions.length; i++) {
            if (state.auction.currentAuctions[i] == auction.id) {
                state.auction.currentAuctions[i] = state.auction.currentAuctions[state.auction.currentAuctions.length-1];
                state.auction.currentAuctions.length--;
                return;
            }
        }
    }

    /**
     * Create a new auction and save it in global state
     */
    function create(
        Store.State storage state,
        uint16 marketID,
        address borrower,
        address initiator,
        address debtAsset,
        address collateralAsset
    )
        private
        returns (uint32)
    {
        uint32 id = state.auction.auctionsCount++;

        Types.Auction memory auction = Types.Auction({
            id: id,
            status: Types.AuctionStatus.InProgress,
            startBlockNumber: uint32(block.number),
            marketID: marketID,
            borrower: borrower,
            initiator: initiator,
            debtAsset: debtAsset,
            collateralAsset: collateralAsset
        });

        state.auction.auctions[id] = auction;
        state.auction.currentAuctions.push(id);

        Events.logAuctionCreate(id);

        return id;
    }

    // price = debt / collateral / ratio
    function getAuctionDetails(
        Store.State storage state,
        uint32 auctionID
    )
        external
        view
        returns (Types.AuctionDetails memory details)
    {
        Types.Auction memory auction = state.auction.auctions[auctionID];

        details.borrower = auction.borrower;
        details.marketID = auction.marketID;
        details.debtAsset = auction.debtAsset;
        details.collateralAsset = auction.collateralAsset;

        if (state.auction.auctions[auctionID].status == Types.AuctionStatus.Finished){
            details.finished = true;
        } else {
            details.finished = false;
            details.leftDebtAmount = LendingPool.getAmountBorrowed(
                state,
                auction.debtAsset,
                auction.borrower,
                auction.marketID
            );
            details.leftCollateralAmount = state.accounts[auction.borrower][auction.marketID].balances[auction.collateralAsset];

            details.ratio = auction.ratio(state);

            if (details.leftCollateralAmount != 0 && details.ratio != 0) {
                // price = debt/collateral/ratio
                details.price = Decimal.divFloor(Decimal.divFloor(details.leftDebtAmount, details.leftCollateralAmount), details.ratio);
            }
        }
    }
}

library BatchActions {
    using SafeMath for uint256;
    /**
     * All allowed actions types
     */
    enum ActionType {
        Deposit,   // Move asset from your wallet to tradeable balance
        Withdraw,  // Move asset from your tradeable balance to wallet
        Transfer,  // Move asset between tradeable balance and margin account
        Borrow,    // Borrow asset from pool
        Repay,     // Repay asset to pool
        Supply,    // Move asset from tradeable balance to pool to earn interest
        Unsupply   // Move asset from pool back to tradeable balance
    }

    /**
     * Uniform parameter for an action
     */
    struct Action {
        ActionType actionType;  // The action type
        bytes encodedParams;    // Encoded params, it's different for each action
    }

    /**
     * Batch actions entrance
     * @param actions List of actions
     */
    function batch(
        Store.State storage state,
        Action[] memory actions,
        uint256 msgValue
    )
        public
    {
        uint256 totalDepositedEtherAmount = 0;

        for (uint256 i = 0; i < actions.length; i++) {
            Action memory action = actions[i];
            ActionType actionType = action.actionType;

            if (actionType == ActionType.Deposit) {
                uint256 depositedEtherAmount = deposit(state, action);
                totalDepositedEtherAmount = totalDepositedEtherAmount.add(depositedEtherAmount);
            } else if (actionType == ActionType.Withdraw) {
                withdraw(state, action);
            } else if (actionType == ActionType.Transfer) {
                transfer(state, action);
            } else if (actionType == ActionType.Borrow) {
                borrow(state, action);
            } else if (actionType == ActionType.Repay) {
                repay(state, action);
            } else if (actionType == ActionType.Supply) {
                supply(state, action);
            } else if (actionType == ActionType.Unsupply) {
                unsupply(state, action);
            }
        }

        require(totalDepositedEtherAmount == msgValue, "MSG_VALUE_AND_AMOUNT_MISMATCH");
    }

    function deposit(
        Store.State storage state,
        Action memory action
    )
        private
        returns (uint256)
    {
        (
            address asset,
            uint256 amount
        ) = abi.decode(
            action.encodedParams,
            (
                address,
                uint256
            )
        );

        return Transfer.deposit(
            state,
            asset,
            amount
        );
    }

    function withdraw(
        Store.State storage state,
        Action memory action
    )
        private
    {
        (
            address asset,
            uint256 amount
        ) = abi.decode(
            action.encodedParams,
            (
                address,
                uint256
            )
        );

        Transfer.withdraw(
            state,
            msg.sender,
            asset,
            amount
        );
    }

    function transfer(
        Store.State storage state,
        Action memory action
    )
        private
    {
        (
            address asset,
            Types.BalancePath memory fromBalancePath,
            Types.BalancePath memory toBalancePath,
            uint256 amount
        ) = abi.decode(
            action.encodedParams,
            (
                address,
                Types.BalancePath,
                Types.BalancePath,
                uint256
            )
        );

        require(fromBalancePath.user == msg.sender, "CAN_NOT_MOVE_OTHER_USER_ASSET");
        require(toBalancePath.user == msg.sender, "CAN_NOT_MOVE_ASSET_TO_OTHER_USER");

        Requires.requirePathNormalStatus(state, fromBalancePath);
        Requires.requirePathNormalStatus(state, toBalancePath);

        // The below two requires will be checked in Transfer.transfer
        // Requires.requirePathMarketIDAssetMatch(state, fromBalancePath, asset);
        // Requires.requirePathMarketIDAssetMatch(state, toBalancePath, asset);

        if (fromBalancePath.category == Types.BalanceCategory.CollateralAccount) {
            require(
                CollateralAccounts.getTransferableAmount(state, fromBalancePath.marketID, fromBalancePath.user, asset) >= amount,
                "COLLATERAL_ACCOUNT_TRANSFERABLE_AMOUNT_NOT_ENOUGH"
            );
        }

        Transfer.transfer(
            state,
            asset,
            fromBalancePath,
            toBalancePath,
            amount
        );

        if (toBalancePath.category == Types.BalanceCategory.CollateralAccount) {
            Events.logIncreaseCollateral(msg.sender, toBalancePath.marketID, asset, amount);
        }
        if (fromBalancePath.category == Types.BalanceCategory.CollateralAccount) {
            Events.logDecreaseCollateral(msg.sender, fromBalancePath.marketID, asset, amount);
        }
    }

    function borrow(
        Store.State storage state,
        Action memory action
    )
        private
    {
        (
            uint16 marketID,
            address asset,
            uint256 amount
        ) = abi.decode(
            action.encodedParams,
            (
                uint16,
                address,
                uint256
            )
        );

        Requires.requireMarketIDExist(state, marketID);
        Requires.requireMarketBorrowEnabled(state, marketID);
        Requires.requireMarketIDAndAssetMatch(state, marketID, asset);
        Requires.requireAccountNormal(state, marketID, msg.sender);
        LendingPool.borrow(
            state,
            msg.sender,
            marketID,
            asset,
            amount
        );
    }

    function repay(
        Store.State storage state,
        Action memory action
    )
        private
    {
        (
            uint16 marketID,
            address asset,
            uint256 amount
        ) = abi.decode(
            action.encodedParams,
            (
                uint16,
                address,
                uint256
            )
        );

        Requires.requireMarketIDExist(state, marketID);
        Requires.requireMarketIDAndAssetMatch(state, marketID, asset);

        LendingPool.repay(
            state,
            msg.sender,
            marketID,
            asset,
            amount
        );
    }

    function supply(
        Store.State storage state,
        Action memory action
    )
        private
    {
        (
            address asset,
            uint256 amount
        ) = abi.decode(
            action.encodedParams,
            (
                address,
                uint256
            )
        );

        Requires.requireAssetExist(state, asset);
        LendingPool.supply(
            state,
            asset,
            amount,
            msg.sender
        );
    }

    function unsupply(
        Store.State storage state,
        Action memory action
    )
        private
    {
        (
            address asset,
            uint256 amount
        ) = abi.decode(
            action.encodedParams,
            (
                address,
                uint256
            )
        );

        Requires.requireAssetExist(state, asset);
        LendingPool.unsupply(
            state,
            asset,
            amount,
            msg.sender
        );
    }
}

library CollateralAccounts {
    using SafeMath for uint256;

    function getDetails(
        Store.State storage state,
        address user,
        uint16 marketID
    )
        internal
        view
        returns (Types.CollateralAccountDetails memory details)
    {
        Types.CollateralAccount storage account = state.accounts[user][marketID];
        Types.Market storage market = state.markets[marketID];

        details.status = account.status;

        address baseAsset = market.baseAsset;
        address quoteAsset = market.quoteAsset;

        uint256 baseUSDPrice = AssemblyCall.getAssetPriceFromPriceOracle(
            address(state.assets[baseAsset].priceOracle),
            baseAsset
        );
        uint256 quoteUSDPrice = AssemblyCall.getAssetPriceFromPriceOracle(
            address(state.assets[quoteAsset].priceOracle),
            quoteAsset
        );

        uint256 baseBorrowOf = LendingPool.getAmountBorrowed(state, baseAsset, user, marketID);
        uint256 quoteBorrowOf = LendingPool.getAmountBorrowed(state, quoteAsset, user, marketID);

        details.debtsTotalUSDValue = SafeMath.add(
            baseBorrowOf.mul(baseUSDPrice),
            quoteBorrowOf.mul(quoteUSDPrice)
        ) / Decimal.one();

        details.balancesTotalUSDValue = SafeMath.add(
            account.balances[baseAsset].mul(baseUSDPrice),
            account.balances[quoteAsset].mul(quoteUSDPrice)
        ) / Decimal.one();

        if (details.status == Types.CollateralAccountStatus.Normal) {
            details.liquidatable = details.balancesTotalUSDValue < Decimal.mulCeil(details.debtsTotalUSDValue, market.liquidateRate);
        } else {
            details.liquidatable = false;
        }
    }

    /**
     * Get the amount that is avaliable to transfer out of the collateral account.
     *
     * If there are no open loans, this is just the total asset balance.
     *
     * If there are open loans, then this is the maximum amount that can be withdrawn
     *   without falling below the withdraw collateral ratio
     */
    function getTransferableAmount(
        Store.State storage state,
        uint16 marketID,
        address user,
        address asset
    )
        internal
        view
        returns (uint256)
    {
        Types.CollateralAccountDetails memory details = getDetails(state, user, marketID);

        // already checked at batch operation
        // liquidating or liquidatable account can't move asset

        uint256 assetBalance = state.accounts[user][marketID].balances[asset];

        // If and only if balance USD value is larger than transferableUSDValueBar, the user is able to withdraw some assets
        uint256 transferableThresholdUSDValue = Decimal.mulCeil(
            details.debtsTotalUSDValue,
            state.markets[marketID].withdrawRate
        );

        if(transferableThresholdUSDValue > details.balancesTotalUSDValue) {
            return 0;
        } else {
            uint256 transferableUSD = details.balancesTotalUSDValue - transferableThresholdUSDValue;
            uint256 assetUSDPrice = state.assets[asset].priceOracle.getPrice(asset);
            uint256 transferableAmount = Decimal.divFloor(transferableUSD, assetUSDPrice);
            if (transferableAmount > assetBalance) {
                return assetBalance;
            } else {
                return transferableAmount;
            }
        }
    }
}

library LendingPool {
    using SafeMath for uint256;
    using SafeMath for int256;

    uint256 private constant SECONDS_OF_YEAR = 31536000;

    // create new pool
    function initializeAssetLendingPool(
        Store.State storage state,
        address asset
    )
        internal
    {
        // indexes starts at 1 for easy computation
        state.pool.borrowIndex[asset] = Decimal.one();
        state.pool.supplyIndex[asset] = Decimal.one();

        // record starting time for the pool
        state.pool.indexStartTime[asset] = block.timestamp;
    }

    /**
     * Supply asset into the pool. Supplied asset in the pool gains interest.
     */
    function supply(
        Store.State storage state,
        address asset,
        uint256 amount,
        address user
    )
        internal
    {
        // update value of index at this moment in time
        updateIndex(state, asset);

        // transfer asset from user's balance account
        Transfer.transferOut(state, asset, BalancePath.getCommonPath(user), amount);

        // compute the normalized value of 'amount'
        // round floor
        uint256 normalizedAmount = Decimal.divFloor(amount, state.pool.supplyIndex[asset]);

        // mint normalizedAmount of pool token for user
        state.assets[asset].lendingPoolToken.mint(user, normalizedAmount);

        // update interest rate based on latest state
        updateInterestRate(state, asset);

        Events.logSupply(user, asset, amount);
    }

    /**
     * unsupply asset from the pool, up to initial asset supplied plus interest
     */
    function unsupply(
        Store.State storage state,
        address asset,
        uint256 amount,
        address user
    )
        internal
        returns (uint256)
    {
        // update value of index at this moment in time
        updateIndex(state, asset);

        // compute the normalized value of 'amount'
        // round ceiling
        uint256 normalizedAmount = Decimal.divCeil(amount, state.pool.supplyIndex[asset]);

        uint256 unsupplyAmount = amount;

        // check and cap the amount so user can't overdraw
        if (getNormalizedSupplyOf(state, asset, user) <= normalizedAmount) {
            normalizedAmount = getNormalizedSupplyOf(state, asset, user);
            unsupplyAmount = Decimal.mulFloor(normalizedAmount, state.pool.supplyIndex[asset]);
        }

        // transfer asset to user's balance account
        Transfer.transferIn(state, asset, BalancePath.getCommonPath(user), unsupplyAmount);
        Requires.requireCashLessThanOrEqualContractBalance(state, asset);

        // subtract normalizedAmount from the pool
        state.assets[asset].lendingPoolToken.burn(user, normalizedAmount);

        // update interest rate based on latest state
        updateInterestRate(state, asset);

        Events.logUnsupply(user, asset, unsupplyAmount);

        return unsupplyAmount;
    }

    /**
     * Borrow money from the lending pool.
     */
    function borrow(
        Store.State storage state,
        address user,
        uint16 marketID,
        address asset,
        uint256 amount
    )
        internal
    {
        // update value of index at this moment in time
        updateIndex(state, asset);

        // compute the normalized value of 'amount'
        uint256 normalizedAmount = Decimal.divCeil(amount, state.pool.borrowIndex[asset]);

        // transfer assets to user's balance account
        Transfer.transferIn(state, asset, BalancePath.getMarketPath(user, marketID), amount);
        Requires.requireCashLessThanOrEqualContractBalance(state, asset);

        // update normalized amount borrowed by user
        state.pool.normalizedBorrow[user][marketID][asset] = state.pool.normalizedBorrow[user][marketID][asset].add(normalizedAmount);

        // update normalized amount borrowed from the pool
        state.pool.normalizedTotalBorrow[asset] = state.pool.normalizedTotalBorrow[asset].add(normalizedAmount);

        // update interest rate based on latest state
        updateInterestRate(state, asset);

        Requires.requireCollateralAccountNotLiquidatable(state, user, marketID);

        Events.logBorrow(user, marketID, asset, amount);
    }

    /**
     * repay money borrowed money from the pool.
     */
    function repay(
        Store.State storage state,
        address user,
        uint16 marketID,
        address asset,
        uint256 amount
    )
        internal
        returns (uint256)
    {
        // update value of index at this moment in time
        updateIndex(state, asset);

        // get normalized value of amount to be repaid, which in effect take into account interest
        // (ex: if you borrowed 10, with index at 1.1, amount repaid needs to be 11 to make 11/1.1 = 10)
        uint256 normalizedAmount = Decimal.divFloor(amount, state.pool.borrowIndex[asset]);

        uint256 repayAmount = amount;

        // make sure user cannot repay more than amount owed
        if (state.pool.normalizedBorrow[user][marketID][asset] <= normalizedAmount) {
            normalizedAmount = state.pool.normalizedBorrow[user][marketID][asset];
            // repayAmount <= amount
            // because ⌈⌊a/b⌋*b⌉ <= a
            repayAmount = Decimal.mulCeil(normalizedAmount, state.pool.borrowIndex[asset]);
        }

        // transfer assets from user's balance account
        Transfer.transferOut(state, asset, BalancePath.getMarketPath(user, marketID), repayAmount);

        // update amount(normalized) borrowed by user
        state.pool.normalizedBorrow[user][marketID][asset] = state.pool.normalizedBorrow[user][marketID][asset].sub(normalizedAmount);

        // update total amount(normalized) borrowed from pool
        state.pool.normalizedTotalBorrow[asset] = state.pool.normalizedTotalBorrow[asset].sub(normalizedAmount);

        // update interest rate
        updateInterestRate(state, asset);

        Events.logRepay(user, marketID, asset, repayAmount);

        return repayAmount;
    }

    /**
     * This method is called if a loan could not be paid back by the borrower, auction, or insurance,
     * in which case the generalized loss is recognized across all lenders.
     */
    function recognizeLoss(
        Store.State storage state,
        address asset,
        uint256 amount
    )
        internal
    {
        uint256 totalnormalizedSupply = getTotalNormalizedSupply(
            state,
            asset
        );

        uint256 actualSupply = getTotalSupply(
            state,
            asset
        ).sub(amount);

        state.pool.supplyIndex[asset] = Decimal.divFloor(
            actualSupply,
            totalnormalizedSupply
        );

        updateIndex(state, asset);

        Events.logLoss(asset, amount);
    }

    /**
     * Claim an amount from the insurance pool, in return for all the collateral.
     * Only called if an auction expired without being filled.
     */
    function claimInsurance(
        Store.State storage state,
        address asset,
        uint256 amount
    )
        internal
    {
        uint256 insuranceBalance = state.pool.insuranceBalances[asset];

        uint256 compensationAmount = SafeMath.min(amount, insuranceBalance);

        state.cash[asset] = state.cash[asset].add(amount);

        // remove compensationAmount from insurance balances
        state.pool.insuranceBalances[asset] = SafeMath.sub(
            state.pool.insuranceBalances[asset],
            compensationAmount
        );

        // all suppliers pay debt if insurance not enough
        if (compensationAmount < amount) {
            recognizeLoss(
                state,
                asset,
                amount.sub(compensationAmount)
            );
        }

        Events.logInsuranceCompensation(
            asset,
            compensationAmount
        );

    }

    function updateInterestRate(
        Store.State storage state,
        address asset
    )
        private
    {
        (uint256 borrowInterestRate, uint256 supplyInterestRate) = getInterestRates(state, asset, 0);
        state.pool.borrowAnnualInterestRate[asset] = borrowInterestRate;
        state.pool.supplyAnnualInterestRate[asset] = supplyInterestRate;
    }

    // get interestRate
    function getInterestRates(
        Store.State storage state,
        address asset,
        uint256 extraBorrowAmount
    )
        internal
        view
        returns (uint256 borrowInterestRate, uint256 supplyInterestRate)
    {
        (uint256 currentSupplyIndex, uint256 currentBorrowIndex) = getCurrentIndex(state, asset);

        uint256 _supply = getTotalSupplyWithIndex(state, asset, currentSupplyIndex);

        if (_supply == 0) {
            return (0, 0);
        }

        uint256 _borrow = getTotalBorrowWithIndex(state, asset, currentBorrowIndex).add(extraBorrowAmount);

        uint256 borrowRatio = _borrow.mul(Decimal.one()).div(_supply);

        borrowInterestRate = AssemblyCall.getBorrowInterestRate(
            address(state.assets[asset].interestModel),
            borrowRatio
        );
        require(borrowInterestRate <= 3 * Decimal.one(), "BORROW_INTEREST_RATE_EXCEED_300%");

        uint256 borrowInterest = Decimal.mulCeil(_borrow, borrowInterestRate);
        uint256 supplyInterest = Decimal.mulFloor(borrowInterest, Decimal.one().sub(state.pool.insuranceRatio));

        supplyInterestRate = Decimal.divFloor(supplyInterest, _supply);
    }

    /**
     * update the index value
     */
    function updateIndex(
        Store.State storage state,
        address asset
    )
        private
    {
        if (state.pool.indexStartTime[asset] == block.timestamp) {
            return;
        }

        (uint256 currentSupplyIndex, uint256 currentBorrowIndex) = getCurrentIndex(state, asset);

        // get the total equity value
        uint256 normalizedBorrow = state.pool.normalizedTotalBorrow[asset];
        uint256 normalizedSupply = getTotalNormalizedSupply(state, asset);

        // interest = equity value * (current index value - starting index value)
        uint256 recentBorrowInterest = Decimal.mulCeil(
            normalizedBorrow,
            currentBorrowIndex.sub(state.pool.borrowIndex[asset])
        );

        uint256 recentSupplyInterest = Decimal.mulFloor(
            normalizedSupply,
            currentSupplyIndex.sub(state.pool.supplyIndex[asset])
        );

        // the interest rate spread goes into the insurance pool
        state.pool.insuranceBalances[asset] = state.pool.insuranceBalances[asset].add(recentBorrowInterest.sub(recentSupplyInterest));

        // update the indexes
        Events.logUpdateIndex(
            asset,
            state.pool.borrowIndex[asset],
            currentBorrowIndex,
            state.pool.supplyIndex[asset],
            currentSupplyIndex
        );

        state.pool.supplyIndex[asset] = currentSupplyIndex;
        state.pool.borrowIndex[asset] = currentBorrowIndex;
        state.pool.indexStartTime[asset] = block.timestamp;

    }

    function getAmountSupplied(
        Store.State storage state,
        address asset,
        address user
    )
        internal
        view
        returns (uint256)
    {
        (uint256 currentSupplyIndex, ) = getCurrentIndex(state, asset);
        return Decimal.mulFloor(getNormalizedSupplyOf(state, asset, user), currentSupplyIndex);
    }

    function getAmountBorrowed(
        Store.State storage state,
        address asset,
        address user,
        uint16 marketID
    )
        internal
        view
        returns (uint256)
    {
        // the actual amount borrowed = normalizedAmount * poolIndex
        (, uint256 currentBorrowIndex) = getCurrentIndex(state, asset);
        return Decimal.mulCeil(state.pool.normalizedBorrow[user][marketID][asset], currentBorrowIndex);
    }

    function getTotalSupply(
        Store.State storage state,
        address asset
    )
        internal
        view
        returns (uint256)
    {
        (uint256 currentSupplyIndex, ) = getCurrentIndex(state, asset);
        return getTotalSupplyWithIndex(state, asset, currentSupplyIndex);
    }

    function getTotalBorrow(
        Store.State storage state,
        address asset
    )
        internal
        view
        returns (uint256)
    {
        (, uint256 currentBorrowIndex) = getCurrentIndex(state, asset);
        return getTotalBorrowWithIndex(state, asset, currentBorrowIndex);
    }

    function getTotalSupplyWithIndex(
        Store.State storage state,
        address asset,
        uint256 currentSupplyIndex
    )
        private
        view
        returns (uint256)
    {
        return Decimal.mulFloor(getTotalNormalizedSupply(state, asset), currentSupplyIndex);
    }

    function getTotalBorrowWithIndex(
        Store.State storage state,
        address asset,
        uint256 currentBorrowIndex
    )
        private
        view
        returns (uint256)
    {
        return Decimal.mulCeil(state.pool.normalizedTotalBorrow[asset], currentBorrowIndex);
    }

    /**
     * Compute the current value of poolIndex based on the time elapsed and the interest rate
     */
    function getCurrentIndex(
        Store.State storage state,
        address asset
    )
        internal
        view
        returns (uint256 currentSupplyIndex, uint256 currentBorrowIndex)
    {
        uint256 timeDelta = block.timestamp.sub(state.pool.indexStartTime[asset]);

        uint256 borrowInterestRate = state.pool.borrowAnnualInterestRate[asset]
            .mul(timeDelta).divCeil(SECONDS_OF_YEAR); // Ceil Ensure asset greater than liability

        uint256 supplyInterestRate = state.pool.supplyAnnualInterestRate[asset]
            .mul(timeDelta).div(SECONDS_OF_YEAR);

        currentBorrowIndex = Decimal.mulCeil(state.pool.borrowIndex[asset], Decimal.onePlus(borrowInterestRate));
        currentSupplyIndex = Decimal.mulFloor(state.pool.supplyIndex[asset], Decimal.onePlus(supplyInterestRate));

        return (currentSupplyIndex, currentBorrowIndex);
    }

    function getNormalizedSupplyOf(
        Store.State storage state,
        address asset,
        address user
    )
        private
        view
        returns (uint256)
    {
        return state.assets[asset].lendingPoolToken.balanceOf(user);
    }

    function getTotalNormalizedSupply(
        Store.State storage state,
        address asset
    )
        private
        view
        returns (uint256)
    {
        return state.assets[asset].lendingPoolToken.totalSupply();
    }
}

contract StandardToken {
    using SafeMath for uint256;

    mapping(address => uint256) balances;
    mapping (address => mapping (address => uint256)) internal allowed;

    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /**
    * @dev transfer token for a specified address
    * @param to The address to transfer to.
    * @param amount The amount to be transferred.
    */
    function transfer(
        address to,
        uint256 amount
    )
        public
        returns (bool)
    {
        require(to != address(0), "TO_ADDRESS_IS_EMPTY");
        require(amount <= balances[msg.sender], "BALANCE_NOT_ENOUGH");

        balances[msg.sender] = balances[msg.sender].sub(amount);
        balances[to] = balances[to].add(amount);
        emit Transfer(msg.sender, to, amount);
        return true;
    }

    /**
    * @dev Gets the balance of the specified address.
    * @param owner The address to query the the balance of.
    * @return An uint256 representing the amount owned by the passed address.
    */
    function balanceOf(address owner) public view returns (uint256 balance) {
        return balances[owner];
    }

    /**
    * @dev Transfer tokens from one address to another
    * @param from address The address which you want to send tokens from
    * @param to address The address which you want to transfer to
    * @param amount uint256 the amount of tokens to be transferred
    */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    )
        public
        returns (bool)
    {
        require(to != address(0), "TO_ADDRESS_IS_EMPTY");
        require(amount <= balances[from], "BALANCE_NOT_ENOUGH");
        require(amount <= allowed[from][msg.sender], "ALLOWANCE_NOT_ENOUGH");

        balances[from] = balances[from].sub(amount);
        balances[to] = balances[to].add(amount);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(amount);
        emit Transfer(from, to, amount);
        return true;
    }

    /**
    * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
    * @param spender The address which will spend the funds.
    * @param amount The amount of tokens to be spent.
    */
    function approve(
        address spender,
        uint256 amount
    )
        public
        returns (bool)
    {
        allowed[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    /**
    * @dev Function to check the amount of tokens that an owner allowed to a spender.
    * @param owner address The address which owns the funds.
    * @param spender address The address which will spend the funds.
    * @return A uint256 specifying the amount of tokens still available for the spender.
    */
    function allowance(
        address owner,
        address spender
    )
        public
        view
        returns (uint256)
    {
        return allowed[owner][spender];
    }
}

interface IInterestModel {
    function polynomialInterestModel(
        uint256 borrowRatio
    )
        external
        pure
        returns(uint256);
}

interface ILendingPoolToken {
    function mint(
        address user,
        uint256 value
    )
        external;

    function burn(
        address user,
        uint256 value
    )
        external;

    function balanceOf(
        address user
    )
        external
        view
        returns (uint256);

    function totalSupply()
        external
        view
        returns (uint256);
}

interface IPriceOracle {
    /** return USD price of token */
    function getPrice(
        address asset
    )
        external
        view
        returns (uint256);
}

interface IStandardToken {
    function transfer(
        address _to,
        uint256 _amount
    )
        external
        returns (bool);

    function balanceOf(
        address _owner)
        external
        view
        returns (uint256 balance);

    function transferFrom(
        address _from,
        address _to,
        uint256 _amount
    )
        external
        returns (bool);

    function approve(
        address _spender,
        uint256 _amount
    )
        external
        returns (bool);

    function allowance(
        address _owner,
        address _spender
    )
        external
        view
        returns (uint256);
}

library AssemblyCall {
    function getAssetPriceFromPriceOracle(
        address oracleAddress,
        address asset
    )
        internal
        view
        returns (uint256)
    {
        // saves about 1200 gas.
        // return state.assets[asset].priceOracle.getPrice(asset);

        // keccak256('getPrice(address)') & 0xFFFFFFFF00000000000000000000000000000000000000000000000000000000
        bytes32 functionSelector = 0x41976e0900000000000000000000000000000000000000000000000000000000;

        (uint256 result, bool success) = callWith32BytesReturnsUint256(
            oracleAddress,
            functionSelector,
            bytes32(uint256(uint160(asset)))
        );

        if (!success) {
            revert("ASSEMBLY_CALL_GET_ASSET_PRICE_FAILED");
        }

        return result;
    }

    /**
     * Get the HOT token balance of an address.
     *
     * @param owner The address to check.
     * @return The HOT balance for the owner address.
     */
    function getHotBalance(
        address hotToken,
        address owner
    )
        internal
        view
        returns (uint256)
    {
        // saves about 1200 gas.
        // return HydroToken(hotToken).balanceOf(owner);

        // keccak256('balanceOf(address)') bitmasked to 4 bytes
        bytes32 functionSelector = 0x70a0823100000000000000000000000000000000000000000000000000000000;

        (uint256 result, bool success) = callWith32BytesReturnsUint256(
            hotToken,
            functionSelector,
            bytes32(uint256(uint160(owner)))
        );

        if (!success) {
            revert("ASSEMBLY_CALL_GET_HOT_BALANCE_FAILED");
        }

        return result;
    }

    function getBorrowInterestRate(
        address interestModel,
        uint256 borrowRatio
    )
        internal
        view
        returns (uint256)
    {
        // saves about 1200 gas.
        // return IInterestModel(interestModel).polynomialInterestModel(borrowRatio);

        // keccak256('polynomialInterestModel(uint256)') & 0xFFFFFFFF00000000000000000000000000000000000000000000000000000000
        bytes32 functionSelector = 0x69e8a15f00000000000000000000000000000000000000000000000000000000;

        (uint256 result, bool success) = callWith32BytesReturnsUint256(
            interestModel,
            functionSelector,
            bytes32(borrowRatio)
        );

        if (!success) {
            revert("ASSEMBLY_CALL_GET_BORROW_INTEREST_RATE_FAILED");
        }

        return result;
    }

    function callWith32BytesReturnsUint256(
        address to,
        bytes32 functionSelector,
        bytes32 param1
    )
        private
        view
        returns (uint256 result, bool success)
    {
        assembly {
            let freePtr := mload(0x40)
            let tmp1 := mload(freePtr)
            let tmp2 := mload(add(freePtr, 4))

            mstore(freePtr, functionSelector)
            mstore(add(freePtr, 4), param1)

            // call ERC20 Token contract transfer function
            success := staticcall(
                gas,           // Forward all gas
                to,            // Interest Model Address
                freePtr,       // Pointer to start of calldata
                36,            // Length of calldata
                freePtr,       // Overwrite calldata with output
                32             // Expecting uint256 output
            )

            result := mload(freePtr)

            mstore(freePtr, tmp1)
            mstore(add(freePtr, 4), tmp2)
        }
    }
}

library Consts {
    function ETHEREUM_TOKEN_ADDRESS()
        internal
        pure
        returns (address)
    {
        return 0x000000000000000000000000000000000000000E;
    }

    // The base discounted rate is 100% of the current rate, or no discount.
    function DISCOUNT_RATE_BASE()
        internal
        pure
        returns (uint256)
    {
        return 100;
    }

    function REBATE_RATE_BASE()
        internal
        pure
        returns (uint256)
    {
        return 100;
    }
}

library Decimal {
    using SafeMath for uint256;

    uint256 constant BASE = 10**18;

    function one()
        internal
        pure
        returns (uint256)
    {
        return BASE;
    }

    function onePlus(
        uint256 d
    )
        internal
        pure
        returns (uint256)
    {
        return d.add(BASE);
    }

    function mulFloor(
        uint256 target,
        uint256 d
    )
        internal
        pure
        returns (uint256)
    {
        return target.mul(d) / BASE;
    }

    function mulCeil(
        uint256 target,
        uint256 d
    )
        internal
        pure
        returns (uint256)
    {
        return target.mul(d).divCeil(BASE);
    }

    function divFloor(
        uint256 target,
        uint256 d
    )
        internal
        pure
        returns (uint256)
    {
        return target.mul(BASE).div(d);
    }

    function divCeil(
        uint256 target,
        uint256 d
    )
        internal
        pure
        returns (uint256)
    {
        return target.mul(BASE).divCeil(d);
    }
}

library EIP712 {
    string private constant DOMAIN_NAME = "Hydro Protocol";

    /**
     * Hash of the EIP712 Domain Separator Schema
     */
    bytes32 private constant EIP712_DOMAIN_TYPEHASH = keccak256(
        abi.encodePacked("EIP712Domain(string name)")
    );

    bytes32 private constant DOMAIN_SEPARATOR = keccak256(
        abi.encodePacked(
            EIP712_DOMAIN_TYPEHASH,
            keccak256(bytes(DOMAIN_NAME))
        )
    );

    /**
     * Calculates EIP712 encoding for a hash struct in this EIP712 Domain.
     *
     * @param eip712hash The EIP712 hash struct.
     * @return EIP712 hash applied to this EIP712 Domain.
     */
    function hashMessage(
        bytes32 eip712hash
    )
        internal
        pure
        returns (bytes32)
    {
        return keccak256(abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR, eip712hash));
    }
}

library Events {
    //////////////////
    // Funds moving //
    //////////////////

    // some assets move into contract
    event Deposit(
        address indexed user,
        address indexed asset,
        uint256 amount
    );

    function logDeposit(
        address user,
        address asset,
        uint256 amount
    )
        internal
    {
        emit Deposit(
            user,
            asset,
            amount
        );
    }

    // some assets move out of contract
    event Withdraw(
        address indexed user,
        address indexed asset,
        uint256 amount
    );

    function logWithdraw(
        address user,
        address asset,
        uint256 amount
    )
        internal
    {
        emit Withdraw(
            user,
            asset,
            amount
        );
    }

    // transfer from balance to collateral account
    event IncreaseCollateral (
        address indexed user,
        uint16 indexed marketID,
        address indexed asset,
        uint256 amount
    );

    function logIncreaseCollateral(
        address user,
        uint16 marketID,
        address asset,
        uint256 amount
    )
        internal
    {
        emit IncreaseCollateral(
            user,
            marketID,
            asset,
            amount
        );
    }

    // transfer from collateral account to balance
    event DecreaseCollateral (
        address indexed user,
        uint16 indexed marketID,
        address indexed asset,
        uint256 amount
    );

    function logDecreaseCollateral(
        address user,
        uint16 marketID,
        address asset,
        uint256 amount
    )
        internal
    {
        emit DecreaseCollateral(
            user,
            marketID,
            asset,
            amount
        );
    }

    //////////////////
    // Lending Pool //
    //////////////////

    event UpdateIndex(
        address indexed asset,
        uint256 oldBorrowIndex,
        uint256 newBorrowIndex,
        uint256 oldSupplyIndex,
        uint256 newSupplyIndex
    );

    function logUpdateIndex(
        address asset,
        uint256 oldBorrowIndex,
        uint256 newBorrowIndex,
        uint256 oldSupplyIndex,
        uint256 newSupplyIndex
    )
        internal
    {
        emit UpdateIndex(
            asset,
            oldBorrowIndex,
            newBorrowIndex,
            oldSupplyIndex,
            newSupplyIndex
        );
    }

    event Borrow(
        address indexed user,
        uint16 indexed marketID,
        address indexed asset,
        uint256 amount
    );

    function logBorrow(
        address user,
        uint16 marketID,
        address asset,
        uint256 amount
    )
        internal
    {
        emit Borrow(
            user,
            marketID,
            asset,
            amount
        );
    }

    event Repay(
        address indexed user,
        uint16 indexed marketID,
        address indexed asset,
        uint256 amount
    );

    function logRepay(
        address user,
        uint16 marketID,
        address asset,
        uint256 amount
    )
        internal
    {
        emit Repay(
            user,
            marketID,
            asset,
            amount
        );
    }

    event Supply(
        address indexed user,
        address indexed asset,
        uint256 amount
    );

    function logSupply(
        address user,
        address asset,
        uint256 amount
    )
        internal
    {
        emit Supply(
            user,
            asset,
            amount
        );
    }

    event Unsupply(
        address indexed user,
        address indexed asset,
        uint256 amount
    );

    function logUnsupply(
        address user,
        address asset,
        uint256 amount
    )
        internal
    {
        emit Unsupply(
            user,
            asset,
            amount
        );
    }

    event Loss(
        address indexed asset,
        uint256 amount
    );

    function logLoss(
        address asset,
        uint256 amount
    )
        internal
    {
        emit Loss(
            asset,
            amount
        );
    }

    event InsuranceCompensation(
        address indexed asset,
        uint256 amount
    );

    function logInsuranceCompensation(
        address asset,
        uint256 amount
    )
        internal
    {
        emit InsuranceCompensation(
            asset,
            amount
        );
    }

    ///////////////////
    // Admin Actions //
    ///////////////////

    event CreateMarket(Types.Market market);

    function logCreateMarket(
        Types.Market memory market
    )
        internal
    {
        emit CreateMarket(market);
    }

    event UpdateMarket(
        uint16 indexed marketID,
        uint256 newAuctionRatioStart,
        uint256 newAuctionRatioPerBlock,
        uint256 newLiquidateRate,
        uint256 newWithdrawRate
    );

    function logUpdateMarket(
        uint16 marketID,
        uint256 newAuctionRatioStart,
        uint256 newAuctionRatioPerBlock,
        uint256 newLiquidateRate,
        uint256 newWithdrawRate
    )
        internal
    {
        emit UpdateMarket(
            marketID,
            newAuctionRatioStart,
            newAuctionRatioPerBlock,
            newLiquidateRate,
            newWithdrawRate
        );
    }

    event MarketBorrowDisable(
        uint16 indexed marketID
    );

    function logMarketBorrowDisable(
        uint16 marketID
    )
        internal
    {
        emit MarketBorrowDisable(
            marketID
        );
    }

    event MarketBorrowEnable(
        uint16 indexed marketID
    );

    function logMarketBorrowEnable(
        uint16 marketID
    )
        internal
    {
        emit MarketBorrowEnable(
            marketID
        );
    }

    event UpdateDiscountConfig(bytes32 newConfig);

    function logUpdateDiscountConfig(
        bytes32 newConfig
    )
        internal
    {
        emit UpdateDiscountConfig(newConfig);
    }

    event CreateAsset(
        address asset,
        address oracleAddress,
        address poolTokenAddress,
        address interestModelAddress
    );

    function logCreateAsset(
        address asset,
        address oracleAddress,
        address poolTokenAddress,
        address interestModelAddress
    )
        internal
    {
        emit CreateAsset(
            asset,
            oracleAddress,
            poolTokenAddress,
            interestModelAddress
        );
    }

    event UpdateAsset(
        address indexed asset,
        address oracleAddress,
        address interestModelAddress
    );

    function logUpdateAsset(
        address asset,
        address oracleAddress,
        address interestModelAddress
    )
        internal
    {
        emit UpdateAsset(
            asset,
            oracleAddress,
            interestModelAddress
        );
    }

    event UpdateAuctionInitiatorRewardRatio(
        uint256 newInitiatorRewardRatio
    );

    function logUpdateAuctionInitiatorRewardRatio(
        uint256 newInitiatorRewardRatio
    )
        internal
    {
        emit UpdateAuctionInitiatorRewardRatio(
            newInitiatorRewardRatio
        );
    }

    event UpdateInsuranceRatio(
        uint256 newInsuranceRatio
    );

    function logUpdateInsuranceRatio(
        uint256 newInsuranceRatio
    )
        internal
    {
        emit UpdateInsuranceRatio(newInsuranceRatio);
    }

    /////////////
    // Auction //
    /////////////

    event Liquidate(
        address indexed user,
        uint16 indexed marketID,
        bool indexed hasAuction
    );

    function logLiquidate(
        address user,
        uint16 marketID,
        bool hasAuction
    )
        internal
    {
        emit Liquidate(
            user,
            marketID,
            hasAuction
        );
    }

    // an auction is created
    event AuctionCreate(
        uint256 auctionID
    );

    function logAuctionCreate(
        uint256 auctionID
    )
        internal
    {
        emit AuctionCreate(auctionID);
    }

    // a user filled an acution
    event FillAuction(
        uint256 indexed auctionID,
        address bidder,
        uint256 repayDebt,
        uint256 bidderRepayDebt,
        uint256 bidderCollateral,
        uint256 leftDebt
    );

    function logFillAuction(
        uint256 auctionID,
        address bidder,
        uint256 repayDebt,
        uint256 bidderRepayDebt,
        uint256 bidderCollateral,
        uint256 leftDebt
    )
        internal
    {
        emit FillAuction(
            auctionID,
            bidder,
            repayDebt,
            bidderRepayDebt,
            bidderCollateral,
            leftDebt
        );
    }

    /////////////
    // Relayer //
    /////////////

    event RelayerApproveDelegate(
        address indexed relayer,
        address indexed delegate
    );

    function logRelayerApproveDelegate(
        address relayer,
        address delegate
    )
        internal
    {
        emit RelayerApproveDelegate(
            relayer,
            delegate
        );
    }

    event RelayerRevokeDelegate(
        address indexed relayer,
        address indexed delegate
    );

    function logRelayerRevokeDelegate(
        address relayer,
        address delegate
    )
        internal
    {
        emit RelayerRevokeDelegate(
            relayer,
            delegate
        );
    }

    event RelayerExit(
        address indexed relayer
    );

    function logRelayerExit(
        address relayer
    )
        internal
    {
        emit RelayerExit(relayer);
    }

    event RelayerJoin(
        address indexed relayer
    );

    function logRelayerJoin(
        address relayer
    )
        internal
    {
        emit RelayerJoin(relayer);
    }

    //////////////
    // Exchange //
    //////////////

    event Match(
        Types.OrderAddressSet addressSet,
        address maker,
        address taker,
        address buyer,
        uint256 makerFee,
        uint256 makerRebate,
        uint256 takerFee,
        uint256 makerGasFee,
        uint256 takerGasFee,
        uint256 baseAssetFilledAmount,
        uint256 quoteAssetFilledAmount

    );

    function logMatch(
        Types.MatchResult memory result,
        Types.OrderAddressSet memory addressSet
    )
        internal
    {
        emit Match(
            addressSet,
            result.maker,
            result.taker,
            result.buyer,
            result.makerFee,
            result.makerRebate,
            result.takerFee,
            result.makerGasFee,
            result.takerGasFee,
            result.baseAssetFilledAmount,
            result.quoteAssetFilledAmount
        );
    }

    event OrderCancel(
        bytes32 indexed orderHash
    );

    function logOrderCancel(
        bytes32 orderHash
    )
        internal
    {
        emit OrderCancel(orderHash);
    }
}

contract Ownable {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /** @dev The Ownable constructor sets the original `owner` of the contract to the sender account. */
    constructor()
        internal
    {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    /** @return the address of the owner. */
    function owner()
        public
        view
        returns(address)
    {
        return _owner;
    }

    /** @dev Throws if called by any account other than the owner. */
    modifier onlyOwner() {
        require(isOwner(), "NOT_OWNER");
        _;
    }

    /** @return true if `msg.sender` is the owner of the contract. */
    function isOwner()
        public
        view
        returns(bool)
    {
        return msg.sender == _owner;
    }

    /** @dev Allows the current owner to relinquish control of the contract.
     * @notice Renouncing to ownership will leave the contract without an owner.
     * It will not be possible to call the functions with the `onlyOwner`
     * modifier anymore.
     */
    function renounceOwnership()
        public
        onlyOwner
    {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /** @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(
        address newOwner
    )
        public
        onlyOwner
    {
        require(newOwner != address(0), "INVALID_OWNER");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract Operations is Ownable, GlobalStore {

    function createMarket(
        Types.Market memory market
    )
        public
        onlyOwner
    {
        OperationsComponent.createMarket(state, market);
    }

    function updateMarket(
        uint16 marketID,
        uint256 newAuctionRatioStart,
        uint256 newAuctionRatioPerBlock,
        uint256 newLiquidateRate,
        uint256 newWithdrawRate
    )
        external
        onlyOwner
    {
        OperationsComponent.updateMarket(
            state,
            marketID,
            newAuctionRatioStart,
            newAuctionRatioPerBlock,
            newLiquidateRate,
            newWithdrawRate
        );
    }

    function setMarketBorrowUsability(
        uint16 marketID,
        bool   usability
    )
        external
        onlyOwner
    {
        OperationsComponent.setMarketBorrowUsability(
            state,
            marketID,
            usability
        );
    }

    function createAsset(
        address asset,
        address oracleAddress,
        address interestModelAddress,
        string calldata poolTokenName,
        string calldata poolTokenSymbol,
        uint8 poolTokenDecimals
    )
        external
        onlyOwner
    {
        OperationsComponent.createAsset(
            state,
            asset,
            oracleAddress,
            interestModelAddress,
            poolTokenName,
            poolTokenSymbol,
            poolTokenDecimals
        );
    }

    function updateAsset(
        address asset,
        address oracleAddress,
        address interestModelAddress
    )
        external
        onlyOwner
    {
        OperationsComponent.updateAsset(
            state,
            asset,
            oracleAddress,
            interestModelAddress
        );
    }

    /**
     * @param newConfig A data blob representing the new discount config. Details on format above.
     */
    function updateDiscountConfig(
        bytes32 newConfig
    )
        external
        onlyOwner
    {
        OperationsComponent.updateDiscountConfig(
            state,
            newConfig
        );
    }

    function updateAuctionInitiatorRewardRatio(
        uint256 newInitiatorRewardRatio
    )
        external
        onlyOwner
    {
        OperationsComponent.updateAuctionInitiatorRewardRatio(
            state,
            newInitiatorRewardRatio
        );
    }

    function updateInsuranceRatio(
        uint256 newInsuranceRatio
    )
        external
        onlyOwner
    {
        OperationsComponent.updateInsuranceRatio(
            state,
            newInsuranceRatio
        );
    }
}

contract Hydro is GlobalStore, ExternalFunctions, Operations {
    constructor(
        address _hotTokenAddress
    )
        public
    {
        state.exchange.hotTokenAddress = _hotTokenAddress;
        state.exchange.discountConfig = 0x043c000027106400004e205a000075305000009c404600000000000000000000;
    }
}

contract LendingPoolToken is StandardToken, Ownable {
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;

    event Mint(address indexed user, uint256 value);
    event Burn(address indexed user, uint256 value);

    constructor (
        string memory tokenName,
        string memory tokenSymbol,
        uint8 tokenDecimals
    )
        public
    {
        name = tokenName;
        symbol = tokenSymbol;
        decimals = tokenDecimals;
    }

    function mint(
        address user,
        uint256 value
    )
        external
        onlyOwner
    {
        balances[user] = balances[user].add(value);
        totalSupply = totalSupply.add(value);
        emit Mint(user, value);
    }

    function burn(
        address user,
        uint256 value
    )
        external
        onlyOwner
    {
        balances[user] = balances[user].sub(value);
        totalSupply = totalSupply.sub(value);
        emit Burn(user, value);
    }

}

library Requires {
    function requireAssetExist(
        Store.State storage state,
        address asset
    )
        internal
        view
    {
        require(isAssetExist(state, asset), "ASSET_NOT_EXIST");
    }

    function requireAssetNotExist(
        Store.State storage state,
        address asset
    )
        internal
        view
    {
        require(!isAssetExist(state, asset), "ASSET_ALREADY_EXIST");
    }

    function requireMarketIDAndAssetMatch(
        Store.State storage state,
        uint16 marketID,
        address asset
    )
        internal
        view
    {
        require(
            asset == state.markets[marketID].baseAsset || asset == state.markets[marketID].quoteAsset,
            "ASSET_NOT_BELONGS_TO_MARKET"
        );
    }

    function requireMarketNotExist(
        Store.State storage state,
        Types.Market memory market
    )
        internal
        view
    {
        require(!isMarketExist(state, market), "MARKET_ALREADY_EXIST");
    }

    function requireMarketAssetsValid(
        Store.State storage state,
        Types.Market memory market
    )
        internal
        view
    {
        require(market.baseAsset != market.quoteAsset, "BASE_QUOTE_DUPLICATED");
        require(isAssetExist(state, market.baseAsset), "MARKET_BASE_ASSET_NOT_EXIST");
        require(isAssetExist(state, market.quoteAsset), "MARKET_QUOTE_ASSET_NOT_EXIST");
    }

    function requireCashLessThanOrEqualContractBalance(
        Store.State storage state,
        address asset
    )
        internal
        view
    {
        if (asset == Consts.ETHEREUM_TOKEN_ADDRESS()) {
            if (state.cash[asset] > 0) {
                require(uint256(state.cash[asset]) <= address(this).balance, "CONTRACT_BALANCE_NOT_ENOUGH");
            }
        } else {
            if (state.cash[asset] > 0) {
                require(uint256(state.cash[asset]) <= IStandardToken(asset).balanceOf(address(this)), "CONTRACT_BALANCE_NOT_ENOUGH");
            }
        }
    }

    function requirePriceOracleAddressValid(
        address oracleAddress
    )
        internal
        pure
    {
        require(oracleAddress != address(0), "ORACLE_ADDRESS_NOT_VALID");
    }

    function requireDecimalLessOrEquanThanOne(
        uint256 decimal
    )
        internal
        pure
    {
        require(decimal <= Decimal.one(), "DECIMAL_GREATER_THAN_ONE");
    }

    function requireDecimalGreaterThanOne(
        uint256 decimal
    )
        internal
        pure
    {
        require(decimal > Decimal.one(), "DECIMAL_LESS_OR_EQUAL_THAN_ONE");
    }

    function requireMarketIDExist(
        Store.State storage state,
        uint16 marketID
    )
        internal
        view
    {
        require(marketID < state.marketsCount, "MARKET_NOT_EXIST");
    }

    function requireMarketBorrowEnabled(
        Store.State storage state,
        uint16 marketID
    )
        internal
        view
    {
        require(state.markets[marketID].borrowEnable, "MARKET_BORROW_DISABLED");
    }

    function requirePathNormalStatus(
        Store.State storage state,
        Types.BalancePath memory path
    )
        internal
        view
    {
        if (path.category == Types.BalanceCategory.CollateralAccount) {
            requireAccountNormal(state, path.marketID, path.user);
        }
    }

    function requireAccountNormal(
        Store.State storage state,
        uint16 marketID,
        address user
    )
        internal
        view
    {
        require(
            state.accounts[user][marketID].status == Types.CollateralAccountStatus.Normal,
            "CAN_NOT_OPERATE_LIQUIDATING_COLLATERAL_ACCOUNT"
        );
    }

    function requirePathMarketIDAssetMatch(
        Store.State storage state,
        Types.BalancePath memory path,
        address asset
    )
        internal
        view
    {
        if (path.category == Types.BalanceCategory.CollateralAccount) {
            requireMarketIDExist(state, path.marketID);
            requireMarketIDAndAssetMatch(state, path.marketID, asset);
        }
    }

    function requireCollateralAccountNotLiquidatable(
        Store.State storage state,
        Types.BalancePath memory path
    )
        internal
        view
    {
        if (path.category == Types.BalanceCategory.CollateralAccount) {
            requireCollateralAccountNotLiquidatable(state, path.user, path.marketID);
        }
    }

    function requireCollateralAccountNotLiquidatable(
        Store.State storage state,
        address user,
        uint16 marketID
    )
        internal
        view
    {
        require(
            !CollateralAccounts.getDetails(state, user, marketID).liquidatable,
            "COLLATERAL_ACCOUNT_LIQUIDATABLE"
        );
    }

    function requireAuctionNotFinished(
        Store.State storage state,
        uint32 auctionID
    )
        internal
        view
    {
        require(
            state.auction.auctions[auctionID].status == Types.AuctionStatus.InProgress,
            "AUCTION_ALREADY_FINISHED"
        );
    }

    function requireAuctionExist(
        Store.State storage state,
        uint32 auctionID
    )
        internal
        view
    {
        require(
            auctionID < state.auction.auctionsCount,
            "AUCTION_NOT_EXIST"
        );
    }

    function isAssetExist(
        Store.State storage state,
        address asset
    )
        private
        view
        returns (bool)
    {
        return state.assets[asset].priceOracle != IPriceOracle(address(0));
    }

    function isMarketExist(
        Store.State storage state,
        Types.Market memory market
    )
        private
        view
        returns (bool)
    {
        for(uint16 i = 0; i < state.marketsCount; i++) {
            if (state.markets[i].baseAsset == market.baseAsset && state.markets[i].quoteAsset == market.quoteAsset) {
                return true;
            }
        }

        return false;
    }

}

library SafeERC20 {
    function safeTransfer(
        address token,
        address to,
        uint256 amount
    )
        internal
    {
        bool result;

        assembly {
            let tmp1 := mload(0)
            let tmp2 := mload(4)
            let tmp3 := mload(36)

            // keccak256('transfer(address,uint256)') & 0xFFFFFFFF00000000000000000000000000000000000000000000000000000000
            mstore(0, 0xa9059cbb00000000000000000000000000000000000000000000000000000000)
            mstore(4, to)
            mstore(36, amount)

            // call ERC20 Token contract transfer function
            let callResult := call(gas, token, 0, 0, 68, 0, 32)
            let returnValue := mload(0)

            mstore(0, tmp1)
            mstore(4, tmp2)
            mstore(36, tmp3)

            // result check
            result := and (
                eq(callResult, 1),
                or(eq(returndatasize, 0), and(eq(returndatasize, 32), gt(returnValue, 0)))
            )
        }

        if (!result) {
            revert("TOKEN_TRANSFER_ERROR");
        }
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 amount
    )
        internal
    {
        bool result;

        assembly {
            let tmp1 := mload(0)
            let tmp2 := mload(4)
            let tmp3 := mload(36)
            let tmp4 := mload(68)

            // keccak256('transferFrom(address,address,uint256)') & 0xFFFFFFFF00000000000000000000000000000000000000000000000000000000
            mstore(0, 0x23b872dd00000000000000000000000000000000000000000000000000000000)
            mstore(4, from)
            mstore(36, to)
            mstore(68, amount)

            // call ERC20 Token contract transferFrom function
            let callResult := call(gas, token, 0, 0, 100, 0, 32)
            let returnValue := mload(0)

            mstore(0, tmp1)
            mstore(4, tmp2)
            mstore(36, tmp3)
            mstore(68, tmp4)

            // result check
            result := and (
                eq(callResult, 1),
                or(eq(returndatasize, 0), and(eq(returndatasize, 32), gt(returnValue, 0)))
            )
        }

        if (!result) {
            revert("TOKEN_TRANSFER_FROM_ERROR");
        }
    }
}

library SafeMath {

    // Multiplies two numbers, reverts on overflow.
    function mul(
        uint256 a,
        uint256 b
    )
        internal
        pure
        returns (uint256)
    {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "MUL_ERROR");

        return c;
    }

    // Integer division of two numbers truncating the quotient, reverts on division by zero.
    function div(
        uint256 a,
        uint256 b
    )
        internal
        pure
        returns (uint256)
    {
        require(b > 0, "DIVIDING_ERROR");
        return a / b;
    }

    function divCeil(
        uint256 a,
        uint256 b
    )
        internal
        pure
        returns (uint256)
    {
        uint256 quotient = div(a, b);
        uint256 remainder = a - quotient * b;
        if (remainder > 0) {
            return quotient + 1;
        } else {
            return quotient;
        }
    }

    // Subtracts two numbers, reverts on overflow (i.e. if subtrahend is greater than minuend).
    function sub(
        uint256 a,
        uint256 b
    )
        internal
        pure
        returns (uint256)
    {
        require(b <= a, "SUB_ERROR");
        return a - b;
    }

    function sub(
        int256 a,
        uint256 b
    )
        internal
        pure
        returns (int256)
    {
        require(b <= 2**255-1, "INT256_SUB_ERROR");
        int256 c = a - int256(b);
        require(c <= a, "INT256_SUB_ERROR");
        return c;
    }

    // Adds two numbers, reverts on overflow.
    function add(
        uint256 a,
        uint256 b
    )
        internal
        pure
        returns (uint256)
    {
        uint256 c = a + b;
        require(c >= a, "ADD_ERROR");
        return c;
    }

    function add(
        int256 a,
        uint256 b
    )
        internal
        pure
        returns (int256)
    {
        require(b <= 2**255 - 1, "INT256_ADD_ERROR");
        int256 c = a + int256(b);
        require(c >= a, "INT256_ADD_ERROR");
        return c;
    }

    // Divides two numbers and returns the remainder (unsigned integer modulo), reverts when dividing by zero.
    function mod(
        uint256 a,
        uint256 b
    )
        internal
        pure
        returns (uint256)
    {
        require(b != 0, "MOD_ERROR");
        return a % b;
    }

    /**
     * Check the amount of precision lost by calculating multiple * (numerator / denominator). To
     * do this, we check the remainder and make sure it's proportionally less than 0.1%. So we have:
     *
     *     ((numerator * multiple) % denominator)     1
     *     -------------------------------------- < ----
     *              numerator * multiple            1000
     *
     * To avoid further division, we can move the denominators to the other sides and we get:
     *
     *     ((numerator * multiple) % denominator) * 1000 < numerator * multiple
     *
     * Since we want to return true if there IS a rounding error, we simply flip the sign and our
     * final equation becomes:
     *
     *     ((numerator * multiple) % denominator) * 1000 >= numerator * multiple
     *
     * @param numerator The numerator of the proportion
     * @param denominator The denominator of the proportion
     * @param multiple The amount we want a proportion of
     * @return Boolean indicating if there is a rounding error when calculating the proportion
     */
    function isRoundingError(
        uint256 numerator,
        uint256 denominator,
        uint256 multiple
    )
        internal
        pure
        returns (bool)
    {
        // numerator.mul(multiple).mod(denominator).mul(1000) >= numerator.mul(multiple)
        return mul(mod(mul(numerator, multiple), denominator), 1000) >= mul(numerator, multiple);
    }

    /**
     * Takes an amount (multiple) and calculates a proportion of it given a numerator/denominator
     * pair of values. The final value will be rounded down to the nearest integer value.
     *
     * This function will revert the transaction if rounding the final value down would lose more
     * than 0.1% precision.
     *
     * @param numerator The numerator of the proportion
     * @param denominator The denominator of the proportion
     * @param multiple The amount we want a proportion of
     * @return The final proportion of multiple rounded down
     */
    function getPartialAmountFloor(
        uint256 numerator,
        uint256 denominator,
        uint256 multiple
    )
        internal
        pure
        returns (uint256)
    {
        require(!isRoundingError(numerator, denominator, multiple), "ROUNDING_ERROR");
        // numerator.mul(multiple).div(denominator)
        return div(mul(numerator, multiple), denominator);
    }

    /**
     * Returns the smaller integer of the two passed in.
     *
     * @param a Unsigned integer
     * @param b Unsigned integer
     * @return The smaller of the two integers
     */
    function min(
        uint256 a,
        uint256 b
    )
        internal
        pure
        returns (uint256)
    {
        return a < b ? a : b;
    }
}

library Signature {

    enum SignatureMethod {
        EthSign,
        EIP712
    }

    /**
     * Validate a signature given a hash calculated from the order data, the signer, and the
     * signature data passed in with the order.
     *
     * This function will revert the transaction if the signature method is invalid.
     *
     * @param hash Hash bytes calculated by taking the EIP712 hash of the passed order data
     * @param signerAddress The address of the signer
     * @param signature The signature data passed along with the order to validate against
     * @return True if the calculated signature matches the order signature data, false otherwise.
     */
    function isValidSignature(
        bytes32 hash,
        address signerAddress,
        Types.Signature memory signature
    )
        internal
        pure
        returns (bool)
    {
        uint8 method = uint8(signature.config[1]);
        address recovered;
        uint8 v = uint8(signature.config[0]);

        if (method == uint8(SignatureMethod.EthSign)) {
            recovered = ecrecover(
                keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)),
                v,
                signature.r,
                signature.s
            );
        } else if (method == uint8(SignatureMethod.EIP712)) {
            recovered = ecrecover(hash, v, signature.r, signature.s);
        } else {
            revert("INVALID_SIGN_METHOD");
        }

        return signerAddress == recovered;
    }
}

library Store {

    struct RelayerState {
        /**
        * Mapping of relayerAddress => delegateAddress
        */
        mapping (address => mapping (address => bool)) relayerDelegates;

        /**
        * Mapping of relayerAddress => whether relayer is opted out of the liquidity incentive system
        */
        mapping (address => bool) hasExited;
    }

    struct ExchangeState {

        /**
        * Calculate and return the rate at which fees will be charged for an address. The discounted
        * rate depends on how much HOT token is owned by the user. Values returned will be a percentage
        * used to calculate how much of the fee is paid, so a return value of 100 means there is 0
        * discount, and a return value of 70 means a 30% rate reduction.
        *
        * The discountConfig is defined as such:
        * ╔═══════════════════╤════════════════════════════════════════════╗
        * ║                   │ length(bytes)   desc                       ║
        * ╟───────────────────┼────────────────────────────────────────────╢
        * ║ count             │ 1               the count of configs       ║
        * ║ maxDiscountedRate │ 1               the max discounted rate    ║
        * ║ config            │ 5 each                                     ║
        * ╚═══════════════════╧════════════════════════════════════════════╝
        *
        * The default discount structure as defined in code would give the following result:
        *
        * Fee discount table
        * ╔════════════════════╤══════════╗
        * ║     HOT BALANCE    │ DISCOUNT ║
        * ╠════════════════════╪══════════╣
        * ║     0 <= x < 10000 │     0%   ║
        * ╟────────────────────┼──────────╢
        * ║ 10000 <= x < 20000 │    10%   ║
        * ╟────────────────────┼──────────╢
        * ║ 20000 <= x < 30000 │    20%   ║
        * ╟────────────────────┼──────────╢
        * ║ 30000 <= x < 40000 │    30%   ║
        * ╟────────────────────┼──────────╢
        * ║ 40000 <= x         │    40%   ║
        * ╚════════════════════╧══════════╝
        *
        * Breaking down the bytes of 0x043c000027106400004e205a000075305000009c404600000000000000000000
        *
        * 0x  04           3c          0000271064  00004e205a  0000753050  00009c4046  0000000000  0000000000;
        *     ~~           ~~          ~~~~~~~~~~  ~~~~~~~~~~  ~~~~~~~~~~  ~~~~~~~~~~  ~~~~~~~~~~  ~~~~~~~~~~
        *      |            |               |           |           |           |           |           |
        *    count  maxDiscountedRate       1           2           3           4           5           6
        *
        * The first config breaks down as follows:  00002710   64
        *                                           ~~~~~~~~   ~~
        *                                               |      |
        *                                              bar    rate
        *
        * Meaning if a user has less than 10000 (0x00002710) HOT, they will pay 100%(0x64) of the
        * standard fee.
        *
        */
        bytes32 discountConfig;

        /**
        * Mapping of orderHash => amount
        * Generally the amount will be specified in base token units, however in the case of a market
        * buy order the amount is specified in quote token units.
        */
        mapping (bytes32 => uint256) filled;

        /**
        * Mapping of orderHash => whether order has been cancelled.
        */
        mapping (bytes32 => bool) cancelled;

        address hotTokenAddress;
    }

    struct LendingPoolState {
        uint256 insuranceRatio;

        // insurance balances
        mapping(address => uint256) insuranceBalances;

        mapping (address => uint256) borrowIndex; // decimal
        mapping (address => uint256) supplyIndex; // decimal
        mapping (address => uint256) indexStartTime; // timestamp

        mapping (address => uint256) borrowAnnualInterestRate; // decimal
        mapping (address => uint256) supplyAnnualInterestRate; // decimal

        // total borrow
        mapping(address => uint256) normalizedTotalBorrow;

        // user => marketID => balances
        mapping (address => mapping (uint16 => mapping(address => uint256))) normalizedBorrow;
    }

    struct AuctionState {

        // count of auctions
        uint32 auctionsCount;

        // all auctions
        mapping(uint32 => Types.Auction) auctions;

        // current auctions
        uint32[] currentAuctions;

        // auction initiator reward ratio
        uint256 initiatorRewardRatio;
    }

    struct State {

        uint16 marketsCount;

        mapping(address => Types.Asset) assets;
        mapping(address => int256) cash;

        // user => marketID => account
        mapping(address => mapping(uint16 => Types.CollateralAccount)) accounts;

        // all markets
        mapping(uint16 => Types.Market) markets;

        // user balances
        mapping(address => mapping(address => uint256)) balances;

        LendingPoolState pool;

        ExchangeState exchange;

        RelayerState relayer;

        AuctionState auction;
    }
}

library Transfer {
    using SafeMath for uint256;
    using SafeMath for int256;
    using BalancePath for Types.BalancePath;

    // Transfer asset into current contract
    function deposit(
        Store.State storage state,
        address asset,
        uint256 amount
    )
        internal
        returns (uint256)
    {
        uint256 depositedEtherAmount = 0;

        if (asset == Consts.ETHEREUM_TOKEN_ADDRESS()) {
            // Since this method is able to be called in batch,
            // there is a chance that a batch contains multi deposit ether calls.
            // To make sure the the msg.value is equal to the total deposit ethers,
            // each ether deposit function needs to return the actual deposited ether amount.
            depositedEtherAmount = amount;
        } else {
            SafeERC20.safeTransferFrom(asset, msg.sender, address(this), amount);
        }

        transferIn(state, asset, BalancePath.getCommonPath(msg.sender), amount);
        Events.logDeposit(msg.sender, asset, amount);

        return depositedEtherAmount;
    }

    // Transfer asset out of current contract
    function withdraw(
        Store.State storage state,
        address user,
        address asset,
        uint256 amount
    )
        internal
    {
        require(state.balances[user][asset] >= amount, "BALANCE_NOT_ENOUGH");

        if (asset == Consts.ETHEREUM_TOKEN_ADDRESS()) {
            address payable payableUser = address(uint160(user));
            payableUser.transfer(amount);
        } else {
            SafeERC20.safeTransfer(asset, user, amount);
        }

        transferOut(state, asset, BalancePath.getCommonPath(user), amount);

        Events.logWithdraw(user, asset, amount);
    }

    // Get a user's asset balance
    function balanceOf(
        Store.State storage state,
        Types.BalancePath memory balancePath,
        address asset
    )
        internal
        view
        returns (uint256)
    {
        mapping(address => uint256) storage balances = balancePath.getBalances(state);
        return balances[asset];
    }

    // Move asset from a balances map to another
    function transfer(
        Store.State storage state,
        address asset,
        Types.BalancePath memory fromBalancePath,
        Types.BalancePath memory toBalancePath,
        uint256 amount
    )
        internal
    {

        Requires.requirePathMarketIDAssetMatch(state, fromBalancePath, asset);
        Requires.requirePathMarketIDAssetMatch(state, toBalancePath, asset);

        mapping(address => uint256) storage fromBalances = fromBalancePath.getBalances(state);
        mapping(address => uint256) storage toBalances = toBalancePath.getBalances(state);

        require(fromBalances[asset] >= amount, "TRANSFER_BALANCE_NOT_ENOUGH");

        fromBalances[asset] = fromBalances[asset] - amount;
        toBalances[asset] = toBalances[asset].add(amount);
    }

    function transferIn(
        Store.State storage state,
        address asset,
        Types.BalancePath memory path,
        uint256 amount
    )
        internal
    {
        mapping(address => uint256) storage balances = path.getBalances(state);
        balances[asset] = balances[asset].add(amount);
        state.cash[asset] = state.cash[asset].add(amount);
    }

    function transferOut(
        Store.State storage state,
        address asset,
        Types.BalancePath memory path,
        uint256 amount
    )
        internal
    {
        mapping(address => uint256) storage balances = path.getBalances(state);
        balances[asset] = balances[asset].sub(amount);
        state.cash[asset] = state.cash[asset].sub(amount);
    }
}

library Types {
    enum AuctionStatus {
        InProgress,
        Finished
    }

    enum CollateralAccountStatus {
        Normal,
        Liquid
    }

    enum OrderStatus {
        EXPIRED,
        CANCELLED,
        FILLABLE,
        FULLY_FILLED
    }

    /**
     * Signature struct contains typical signature data as v, r, and s with the signature
     * method encoded in as well.
     */
    struct Signature {
        /**
         * Config contains the following values packed into 32 bytes
         * ╔════════════════════╤═══════════════════════════════════════════════════════════╗
         * ║                    │ length(bytes)   desc                                      ║
         * ╟────────────────────┼───────────────────────────────────────────────────────────╢
         * ║ v                  │ 1               the v parameter of a signature            ║
         * ║ signatureMethod    │ 1               SignatureMethod enum value                ║
         * ╚════════════════════╧═══════════════════════════════════════════════════════════╝
         */
        bytes32 config;
        bytes32 r;
        bytes32 s;
    }

    enum BalanceCategory {
        Common,
        CollateralAccount
    }

    struct BalancePath {
        BalanceCategory category;
        uint16          marketID;
        address         user;
    }

    struct Asset {
        ILendingPoolToken  lendingPoolToken;
        IPriceOracle      priceOracle;
        IInterestModel    interestModel;
    }

    struct Market {
        address baseAsset;
        address quoteAsset;

        // If the collateralRate is below this rate, the account will be liquidated
        uint256 liquidateRate;

        // If the collateralRate is above this rate, the account asset balance can be withdrawed
        uint256 withdrawRate;

        uint256 auctionRatioStart;
        uint256 auctionRatioPerBlock;

        bool borrowEnable;
    }

    struct CollateralAccount {
        uint32 id;
        uint16 marketID;
        CollateralAccountStatus status;
        address owner;

        mapping(address => uint256) balances;
    }

    // memory only
    struct CollateralAccountDetails {
        bool       liquidatable;
        CollateralAccountStatus status;
        uint256    debtsTotalUSDValue;
        uint256    balancesTotalUSDValue;
    }

    struct Auction {
        uint32 id;
        AuctionStatus status;

        // To calculate the ratio
        uint32 startBlockNumber;

        uint16 marketID;

        address borrower;
        address initiator;

        address debtAsset;
        address collateralAsset;
    }

    struct AuctionDetails {
        address borrower;
        uint16  marketID;
        address debtAsset;
        address collateralAsset;
        uint256 leftDebtAmount;
        uint256 leftCollateralAmount;
        uint256 ratio;
        uint256 price;
        bool    finished;
    }

    struct Order {
        address trader;
        address relayer;
        address baseAsset;
        address quoteAsset;
        uint256 baseAssetAmount;
        uint256 quoteAssetAmount;
        uint256 gasTokenAmount;

        /**
         * Data contains the following values packed into 32 bytes
         * ╔════════════════════╤═══════════════════════════════════════════════════════════╗
         * ║                    │ length(bytes)   desc                                      ║
         * ╟────────────────────┼───────────────────────────────────────────────────────────╢
         * ║ version            │ 1               order version                             ║
         * ║ side               │ 1               0: buy, 1: sell                           ║
         * ║ isMarketOrder      │ 1               0: limitOrder, 1: marketOrder             ║
         * ║ expiredAt          │ 5               order expiration time in seconds          ║
         * ║ asMakerFeeRate     │ 2               maker fee rate (base 100,000)             ║
         * ║ asTakerFeeRate     │ 2               taker fee rate (base 100,000)             ║
         * ║ makerRebateRate    │ 2               rebate rate for maker (base 100)          ║
         * ║ salt               │ 8               salt                                      ║
         * ║ isMakerOnly        │ 1               is maker only                             ║
         * ║ balancesType       │ 1               0: common, 1: collateralAccount           ║
         * ║ marketID           │ 2               marketID                                  ║
         * ║                    │ 6               reserved                                  ║
         * ╚════════════════════╧═══════════════════════════════════════════════════════════╝
         */
        bytes32 data;
    }

        /**
     * When orders are being matched, they will always contain the exact same base token,
     * quote token, and relayer. Since excessive call data is very expensive, we choose
     * to create a stripped down OrderParam struct containing only data that may vary between
     * Order objects, and separate out the common elements into a set of addresses that will
     * be shared among all of the OrderParam items. This is meant to eliminate redundancy in
     * the call data, reducing it's size, and hence saving gas.
     */
    struct OrderParam {
        address trader;
        uint256 baseAssetAmount;
        uint256 quoteAssetAmount;
        uint256 gasTokenAmount;
        bytes32 data;
        Signature signature;
    }


    struct OrderAddressSet {
        address baseAsset;
        address quoteAsset;
        address relayer;
    }

    struct MatchResult {
        address maker;
        address taker;
        address buyer;
        uint256 makerFee;
        uint256 makerRebate;
        uint256 takerFee;
        uint256 makerGasFee;
        uint256 takerGasFee;
        uint256 baseAssetFilledAmount;
        uint256 quoteAssetFilledAmount;
        BalancePath makerBalancePath;
        BalancePath takerBalancePath;
    }
    /**
     * @param takerOrderParam A Types.OrderParam object representing the order from the taker.
     * @param makerOrderParams An array of Types.OrderParam objects representing orders from a list of makers.
     * @param orderAddressSet An object containing addresses common across each order.
     */
    struct MatchParams {
        OrderParam       takerOrderParam;
        OrderParam[]     makerOrderParams;
        uint256[]        baseAssetFilledAmounts;
        OrderAddressSet  orderAddressSet;
    }
}

library Auction {
    using SafeMath for uint256;

    function ratio(
        Types.Auction memory auction,
        Store.State storage state
    )
        internal
        view
        returns (uint256)
    {
        uint256 increasedRatio = (block.number - auction.startBlockNumber).mul(state.markets[auction.marketID].auctionRatioPerBlock);
        uint256 initRatio = state.markets[auction.marketID].auctionRatioStart;
        uint256 totalRatio = initRatio.add(increasedRatio);
        return totalRatio;
    }
}

library BalancePath {

    function getBalances(
        Types.BalancePath memory path,
        Store.State storage state
    )
        internal
        view
        returns (mapping(address => uint256) storage)
    {
        if (path.category == Types.BalanceCategory.Common) {
            return state.balances[path.user];
        } else {
            return state.accounts[path.user][path.marketID].balances;
        }
    }

    function getCommonPath(
        address user
    )
        internal
        pure
        returns (Types.BalancePath memory)
    {
        return Types.BalancePath({
            user: user,
            category: Types.BalanceCategory.Common,
            marketID: 0
        });
    }

    function getMarketPath(
        address user,
        uint16 marketID
    )
        internal
        pure
        returns (Types.BalancePath memory)
    {
        return Types.BalancePath({
            user: user,
            category: Types.BalanceCategory.CollateralAccount,
            marketID: marketID
        });
    }
}

library Order {

    bytes32 public constant EIP712_ORDER_TYPE = keccak256(
        abi.encodePacked(
            "Order(address trader,address relayer,address baseAsset,address quoteAsset,uint256 baseAssetAmount,uint256 quoteAssetAmount,uint256 gasTokenAmount,bytes32 data)"
        )
    );

    /**
     * Calculates the Keccak-256 EIP712 hash of the order using the Hydro Protocol domain.
     *
     * @param order The order data struct.
     * @return Fully qualified EIP712 hash of the order in the Hydro Protocol domain.
     */
    function getHash(
        Types.Order memory order
    )
        internal
        pure
        returns (bytes32 orderHash)
    {
        orderHash = EIP712.hashMessage(_hashContent(order));
        return orderHash;
    }

    /**
     * Calculates the EIP712 hash of the order.
     *
     * @param order The order data struct.
     * @return Hash of the order.
     */
    function _hashContent(
        Types.Order memory order
    )
        internal
        pure
        returns (bytes32 result)
    {
        /**
         * Calculate the following hash in solidity assembly to save gas.
         *
         * keccak256(
         *     abi.encodePacked(
         *         EIP712_ORDER_TYPE,
         *         bytes32(order.trader),
         *         bytes32(order.relayer),
         *         bytes32(order.baseAsset),
         *         bytes32(order.quoteAsset),
         *         order.baseAssetAmount,
         *         order.quoteAssetAmount,
         *         order.gasTokenAmount,
         *         order.data
         *     )
         * );
         */

        bytes32 orderType = EIP712_ORDER_TYPE;

        assembly {
            let start := sub(order, 32)
            let tmp := mload(start)

            // 288 = (1 + 8) * 32
            //
            // [0...32)   bytes: EIP712_ORDER_TYPE
            // [32...288) bytes: order
            mstore(start, orderType)
            result := keccak256(start, 288)

            mstore(start, tmp)
        }

        return result;
    }
}

library OrderParam {
    /* Functions to extract info from data bytes in Order struct */

    function getOrderVersion(
        Types.OrderParam memory order
    )
        internal
        pure
        returns (uint256)
    {
        return uint256(uint8(byte(order.data)));
    }

    function getExpiredAtFromOrderData(
        Types.OrderParam memory order
    )
        internal
        pure
        returns (uint256)
    {
        return uint256(uint40(bytes5(order.data << (8*3))));
    }

    function isSell(
        Types.OrderParam memory order
    )
        internal
        pure
        returns (bool)
    {
        return uint8(order.data[1]) == 1;
    }

    function isMarketOrder(
        Types.OrderParam memory order
    )
        internal
        pure
        returns (bool)
    {
        return uint8(order.data[2]) == 1;
    }

    function isMakerOnly(
        Types.OrderParam memory order
    )
        internal
        pure
        returns (bool)
    {
        return uint8(order.data[22]) == 1;
    }

    function isMarketBuy(
        Types.OrderParam memory order
    )
        internal
        pure
        returns (bool)
    {
        return !isSell(order) && isMarketOrder(order);
    }

    function getAsMakerFeeRateFromOrderData(
        Types.OrderParam memory order
    )
        internal
        pure
        returns (uint256)
    {
        return uint256(uint16(bytes2(order.data << (8*8))));
    }

    function getAsTakerFeeRateFromOrderData(
        Types.OrderParam memory order
    )
        internal
        pure
        returns (uint256)
    {
        return uint256(uint16(bytes2(order.data << (8*10))));
    }

    function getMakerRebateRateFromOrderData(
        Types.OrderParam memory order
    )
        internal
        pure
        returns (uint256)
    {
        uint256 makerRebate = uint256(uint16(bytes2(order.data << (8*12))));

        // make sure makerRebate will never be larger than REBATE_RATE_BASE, which is 100
        return SafeMath.min(makerRebate, Consts.REBATE_RATE_BASE());
    }

    function getBalancePathFromOrderData(
        Types.OrderParam memory order
    )
        internal
        pure
        returns (Types.BalancePath memory)
    {
        Types.BalanceCategory category;
        uint16 marketID;

        if (byte(order.data << (8*23)) == "\x01") {
            category = Types.BalanceCategory.CollateralAccount;
            marketID = uint16(bytes2(order.data << (8*24)));
        } else {
            category = Types.BalanceCategory.Common;
            marketID = 0;
        }

        return Types.BalancePath({
            user: order.trader,
            category: category,
            marketID: marketID
        });
    }
}