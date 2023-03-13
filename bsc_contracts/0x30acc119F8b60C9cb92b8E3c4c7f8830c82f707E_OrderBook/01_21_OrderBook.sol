// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.10;

import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "../libraries/LibSubAccount.sol";
import "../libraries/LibMath.sol";
import "../libraries/LibOrderBook.sol";
import "../interfaces/IReferralManager.sol";
import "./Types.sol";
import "./Admin.sol";

contract OrderBook is Storage, Admin {
    using LibSubAccount for bytes32;
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using LibOrder for LibOrder.OrderList;
    using LibOrder for bytes32[3];
    using LibOrder for PositionOrder;
    using LibOrder for LiquidityOrder;
    using LibOrder for WithdrawalOrder;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.UintSet;

    event NewPositionOrder(
        bytes32 indexed subAccountId,
        uint64 indexed orderId,
        uint96 collateral, // erc20.decimals
        uint96 size, // 1e18
        uint96 price, // 1e18
        uint8 profitTokenId,
        uint8 flags,
        uint32 deadline // 1e0. 0 if market order. > 0 if limit order
    );
    event NewLiquidityOrder(
        address indexed account,
        uint64 indexed orderId,
        uint8 assetId,
        uint96 rawAmount, // erc20.decimals
        bool isAdding
    );
    event NewWithdrawalOrder(
        bytes32 indexed subAccountId,
        uint64 indexed orderId,
        uint96 rawAmount, // erc20.decimals
        uint8 profitTokenId,
        bool isProfit
    );
    event NewRebalanceOrder(
        address indexed rebalancer,
        uint64 indexed orderId,
        uint8 tokenId0,
        uint8 tokenId1,
        uint96 rawAmount0,
        uint96 maxRawAmount1,
        bytes32 userData
    );
    event FillOrder(uint64 orderId, OrderType orderType, bytes32[3] orderData);
    event CancelOrder(uint64 orderId, OrderType orderType, bytes32[3] orderData);
    event NewPositionOrderExtra(
        bytes32 indexed subAccountId,
        uint64 indexed orderId,
        uint96 collateral, // erc20.decimals
        uint96 size, // 1e18
        uint96 price, // 1e18
        uint8 profitTokenId,
        uint8 flags,
        uint32 deadline, // 1e0. 0 if market order. > 0 if limit order
        PositionOrderExtra extra
    );

    function initialize(address pool, address mlp, address weth, address nativeUnwrapper) external initializer {
        __SafeOwnable_init();

        _pool = ILiquidityPool(pool);
        _mlp = IERC20Upgradeable(mlp);
        _weth = IWETH(weth);
        _nativeUnwrapper = INativeUnwrapper(nativeUnwrapper);
        maintainer = owner();
    }

    function getOrderCount() external view returns (uint256) {
        return _orders.length();
    }

    /**
     * @notice Get an Order by orderId.
     */
    function getOrder(uint64 orderId) external view returns (bytes32[3] memory, bool) {
        return (_orders.get(orderId), _orders.contains(orderId));
    }

    function getOrders(
        uint256 begin,
        uint256 end
    ) external view returns (bytes32[3][] memory orderArray, uint256 totalCount) {
        totalCount = _orders.length();
        if (begin >= end || begin >= totalCount) {
            return (orderArray, totalCount);
        }
        end = end <= totalCount ? end : totalCount;
        uint256 size = end - begin;
        orderArray = new bytes32[3][](size);
        for (uint256 i = 0; i < size; i++) {
            orderArray[i] = _orders.at(i + begin);
        }
    }

    // A deprecated interface that will be removed in the next release.
    function placePositionOrder2(
        bytes32 subAccountId,
        uint96 collateralAmount, // erc20.decimals
        uint96 size, // 1e18
        uint96 price, // 1e18
        uint8 profitTokenId,
        uint8 flags,
        uint32 deadline, // 1e0
        bytes32 referralCode
    ) public payable {
        PositionOrderExtra memory extra;
        placePositionOrder3(
            subAccountId,
            collateralAmount,
            size,
            price,
            profitTokenId,
            flags,
            deadline,
            referralCode,
            extra
        );
    }

    /**
     * @notice Open/close position. called by Trader.
     *
     *         Market order will expire after marketOrderTimeout seconds.
     *         Limit/Trigger order will expire after deadline.
     * @param  subAccountId       sub account id. see LibSubAccount.decodeSubAccountId.
     * @param  collateralAmount   deposit collateral before open; or withdraw collateral after close. decimals = erc20.decimals.
     * @param  size               position size. decimals = 18.
     * @param  price              limit price. decimals = 18.
     * @param  profitTokenId      specify the profitable asset.id when closing a position and making a profit.
     *                            take no effect when opening a position or loss.
     * @param  flags              a bitset of LibOrder.POSITION_*.
     *                            POSITION_OPEN                     this flag means openPosition; otherwise closePosition
     *                            POSITION_MARKET_ORDER             this flag means ignore limitPrice
     *                            POSITION_WITHDRAW_ALL_IF_EMPTY    this flag means auto withdraw all collateral if position.size == 0
     *                            POSITION_TRIGGER_ORDER            this flag means this is a trigger order (ex: stop-loss order). otherwise this is a limit order (ex: take-profit order)
     *                            POSITION_TPSL_STRATEGY            for open-position-order, this flag auto place take-profit and stop-loss orders when open-position-order fills.
     *                                                              for close-position-order, this flag means ignore limitPrice and profitTokenId, and use extra.tpPrice, extra.slPrice, extra.tpslProfitTokenId instead.
     * @param  deadline           a unix timestamp after which the limit/trigger order MUST NOT be filled. fill 0 for market order.
     * @param  referralCode       set referral code of the trading account.
     * @param  extra              more strategy like tp/sl.
     */
    function placePositionOrder3(
        bytes32 subAccountId,
        uint96 collateralAmount, // erc20.decimals
        uint96 size, // 1e18
        uint96 price, // 1e18
        uint8 profitTokenId,
        uint8 flags,
        uint32 deadline, // 1e0
        bytes32 referralCode,
        PositionOrderExtra memory extra
    ) public payable {
        address accountOwner = subAccountId.getSubAccountOwner();
        require(accountOwner == _msgSender(), "SND"); // SeNDer is not authorized
        require(size != 0, "S=0"); // order Size Is Zero
        if ((flags & LibOrder.POSITION_MARKET_ORDER) != 0) {
            require(price == 0, "P!0"); // market order does not need a limit Price
            require(deadline == 0, "D!0"); // market order does not need a deadline
        } else {
            require(deadline > _blockTimestamp(), "D<0"); // Deadline is earlier than now
        }
        if (profitTokenId > 0) {
            // note: profitTokenId == 0 is also valid, this only partially protects the function from misuse
            require((flags & LibOrder.POSITION_OPEN) == 0, "T!0"); // opening position does not need a profit Token id
        }
        if (referralCode != bytes32(0) && referralManager != address(0)) {
            IReferralManager(referralManager).setReferrerCodeFor(accountOwner, referralCode);
        }
        if ((flags & LibOrder.POSITION_OPEN) != 0) {
            _placeOpenPositionOrder(subAccountId, collateralAmount, size, price, flags, deadline, extra);
        } else {
            _placeClosePositionOrder(
                subAccountId,
                collateralAmount,
                size,
                price,
                profitTokenId,
                flags,
                deadline,
                extra
            );
        }
    }

    function _placePositionOrder(
        bytes32 subAccountId,
        uint96 collateralAmount, // erc20.decimals
        uint96 size, // 1e18
        uint96 price, // 1e18
        uint8 profitTokenId,
        uint8 flags,
        uint32 deadline // 1e0. NOTE: deadline should be 0 for market order; > _blockTimestamp() for limit/trigger order
    ) internal returns (uint64 orderId) {
        uint32 expire10s;
        if (deadline > 0) {
            expire10s = (deadline - _blockTimestamp()) / 10;
            require(expire10s <= type(uint24).max, "DTL"); // Deadline is Too Large
        }
        orderId = nextOrderId++;
        bytes32[3] memory data = LibOrder.encodePositionOrder(
            orderId,
            subAccountId,
            collateralAmount,
            size,
            price,
            profitTokenId,
            flags,
            _blockTimestamp(),
            uint24(expire10s)
        );
        _orders.add(orderId, data);
        emit NewPositionOrder(subAccountId, orderId, collateralAmount, size, price, profitTokenId, flags, deadline);
    }

    function _placeOpenPositionOrder(
        bytes32 subAccountId,
        uint96 collateralAmount, // erc20.decimals
        uint96 size, // 1e18
        uint96 price, // 1e18
        uint8 flags,
        uint32 deadline, // 1e0
        PositionOrderExtra memory extra
    ) internal {
        // add order
        uint64 orderId = _placePositionOrder(
            subAccountId,
            collateralAmount,
            size,
            price,
            0 /* profitTokenId */,
            flags,
            deadline
        );
        // fetch collateral
        if (collateralAmount > 0) {
            uint8 collateralId = subAccountId.getSubAccountCollateralId();
            address collateralAddress = _pool.getAssetAddress(collateralId);
            LibOrderBook._transferIn(_weth, _msgSender(), collateralAddress, address(this), collateralAmount);
        }
        if ((flags & LibOrder.POSITION_TPSL_STRATEGY) != 0) {
            // tp/sl strategy
            require((extra.tpPrice > 0 || extra.slPrice > 0), "TPSL"); // TP/SL strategy need tpPrice and/or slPrice
            require(extra.tpslDeadline > _blockTimestamp(), "D<0"); // Deadline is earlier than now
            require((extra.tpslDeadline - _blockTimestamp()) / 10 <= type(uint24).max, "DTL"); // Deadline is Too Large
            positionOrderExtras[orderId] = extra;
            emit NewPositionOrderExtra(
                subAccountId,
                orderId,
                collateralAmount,
                size,
                price,
                0 /* profitTokenId */,
                flags,
                deadline,
                extra
            );
        }
    }

    function _placeClosePositionOrder(
        bytes32 subAccountId,
        uint96 collateralAmount, // erc20.decimals
        uint96 size, // 1e18
        uint96 price, // 1e18
        uint8 profitTokenId,
        uint8 flags,
        uint32 deadline, // 1e0
        PositionOrderExtra memory extra
    ) internal {
        if ((flags & LibOrder.POSITION_TPSL_STRATEGY) != 0) {
            // tp/sl strategy
            require(price == 0, "P!0"); // use extra.tpPrice and extra.slPrice instead
            require(collateralAmount == 0, "C!0"); // tp/sl strategy only supports POSITION_WITHDRAW_ALL_IF_EMPTY
            require(profitTokenId == 0, "T!0"); // use extra.tpProfitTokenId instead
            require((flags & LibOrder.POSITION_MARKET_ORDER) == 0, "MKT"); // tp/sl strategy does not support MarKeT order
            require(extra.tpPrice > 0 && extra.slPrice > 0, "TPSL"); // tp/sl strategy need tpPrice and slPrice. otherwise use POSITION_TRIGGER_ORDER instead
            require(extra.tpslDeadline > _blockTimestamp(), "D<0"); // Deadline is earlier than now
            require((extra.tpslDeadline - _blockTimestamp()) / 10 <= type(uint24).max, "DTL"); // Deadline is Too Large
            _placeTpslOrdersWhenClose(subAccountId, size, extra);
        } else {
            // normal
            _placePositionOrder(subAccountId, collateralAmount, size, price, profitTokenId, flags, deadline);
        }
    }

    /**
     * @notice Add/remove liquidity. called by Liquidity Provider.
     *
     *         Can be filled after liquidityLockPeriod seconds.
     * @param  assetId   asset.id that added/removed to.
     * @param  rawAmount asset token amount. decimals = erc20.decimals.
     * @param  isAdding  true for add liquidity, false for remove liquidity.
     */
    function placeLiquidityOrder(
        uint8 assetId,
        uint96 rawAmount, // erc20.decimals
        bool isAdding
    ) external payable {
        require(rawAmount != 0, "A=0"); // Amount Is Zero
        address account = _msgSender();
        if (isAdding) {
            address collateralAddress = _pool.getAssetAddress(assetId);
            LibOrderBook._transferIn(_weth, _msgSender(), collateralAddress, address(this), rawAmount);
        } else {
            _mlp.safeTransferFrom(_msgSender(), address(this), rawAmount);
        }
        uint64 orderId = nextOrderId++;
        bytes32[3] memory data = LibOrder.encodeLiquidityOrder(
            orderId,
            account,
            assetId,
            rawAmount,
            isAdding,
            _blockTimestamp()
        );
        _orders.add(orderId, data);

        emit NewLiquidityOrder(account, orderId, assetId, rawAmount, isAdding);
    }

    /**
     * @notice Withdraw collateral/profit. called by Trader.
     *
     *         This order will expire after marketOrderTimeout seconds.
     * @param  subAccountId       sub account id. see LibSubAccount.decodeSubAccountId.
     * @param  rawAmount          collateral or profit asset amount. decimals = erc20.decimals.
     * @param  profitTokenId      specify the profitable asset.id.
     * @param  isProfit           true for withdraw profit. false for withdraw collateral.
     */
    function placeWithdrawalOrder(
        bytes32 subAccountId,
        uint96 rawAmount, // erc20.decimals
        uint8 profitTokenId,
        bool isProfit
    ) external {
        address trader = subAccountId.getSubAccountOwner();
        require(trader == _msgSender(), "SND"); // SeNDer is not authorized
        require(rawAmount != 0, "A=0"); // Amount Is Zero

        uint64 orderId = nextOrderId++;
        bytes32[3] memory data = LibOrder.encodeWithdrawalOrder(
            orderId,
            subAccountId,
            rawAmount,
            profitTokenId,
            isProfit,
            _blockTimestamp()
        );
        _orders.add(orderId, data);

        emit NewWithdrawalOrder(subAccountId, orderId, rawAmount, profitTokenId, isProfit);
    }

    /**
     * @notice Rebalance pool liquidity. Swap token 0 for token 1.
     *
     *         msg.sender must implement IMuxRebalancerCallback.
     * @param  tokenId0      asset.id to be swapped out of the pool.
     * @param  tokenId1      asset.id to be swapped into the pool.
     * @param  rawAmount0    token 0 amount. decimals = erc20.decimals.
     * @param  maxRawAmount1 max token 1 that rebalancer is willing to pay. decimals = erc20.decimals.
     * @param  userData      any user defined data.
     */
    function placeRebalanceOrder(
        uint8 tokenId0,
        uint8 tokenId1,
        uint96 rawAmount0, // erc20.decimals
        uint96 maxRawAmount1, // erc20.decimals
        bytes32 userData
    ) external onlyRebalancer {
        require(rawAmount0 != 0, "A=0"); // Amount Is Zero
        address rebalancer = _msgSender();
        uint64 orderId = nextOrderId++;
        bytes32[3] memory data = LibOrder.encodeRebalanceOrder(
            orderId,
            rebalancer,
            tokenId0,
            tokenId1,
            rawAmount0,
            maxRawAmount1,
            userData
        );
        _orders.add(orderId, data);
        emit NewRebalanceOrder(rebalancer, orderId, tokenId0, tokenId1, rawAmount0, maxRawAmount1, userData);
    }

    /**
     * @dev   Open/close a position. called by Broker.
     *
     * @param orderId           order id.
     * @param collateralPrice   collateral price. decimals = 18.
     * @param assetPrice        asset price. decimals = 18.
     * @param profitAssetPrice  profit asset price. decimals = 18.
     */
    function fillPositionOrder(
        uint64 orderId,
        uint96 collateralPrice,
        uint96 assetPrice,
        uint96 profitAssetPrice // only used when !isLong
    ) external onlyBroker whenPositionOrderEnabled {
        require(_orders.contains(orderId), "OID"); // can not find this OrderID
        bytes32[3] memory orderData = _orders.get(orderId);
        _orders.remove(orderId);
        OrderType orderType = LibOrder.getOrderType(orderData);
        require(orderType == OrderType.PositionOrder, "TYP"); // order TYPe mismatch

        PositionOrder memory order = orderData.decodePositionOrder();
        require(_blockTimestamp() <= _positionOrderDeadline(order), "EXP"); // EXPired
        uint96 tradingPrice;
        if (order.isOpenPosition()) {
            tradingPrice = _fillOpenPositionOrder(orderId, collateralPrice, assetPrice, order);
        } else {
            tradingPrice = _fillClosePositionOrder(orderId, collateralPrice, assetPrice, profitAssetPrice, order);
        }
        // price check
        if (!order.isMarketOrder()) {
            // open,long      0,0   0,1   1,1   1,0
            // limitOrder     <=    >=    <=    >=
            // triggerOrder   >=    <=    >=    <=
            bool isLess = (order.subAccountId.isLong() == order.isOpenPosition());
            if (order.isTriggerOrder()) {
                isLess = !isLess;
            }
            if (isLess) {
                require(tradingPrice <= order.price, "LMT"); // LiMiTed by limitPrice
            } else {
                require(tradingPrice >= order.price, "LMT"); // LiMiTed by limitPrice
            }
        }

        emit FillOrder(orderId, orderType, orderData);
    }

    function _fillOpenPositionOrder(
        uint64 orderId,
        uint96 collateralPrice,
        uint96 assetPrice,
        PositionOrder memory order
    ) internal returns (uint96 tradingPrice) {
        // auto deposit
        uint96 collateralAmount = order.collateral;
        if (collateralAmount > 0) {
            IERC20Upgradeable collateral = IERC20Upgradeable(
                _pool.getAssetAddress(order.subAccountId.getSubAccountCollateralId())
            );
            collateral.safeTransfer(address(_pool), collateralAmount);
            _pool.depositCollateral(order.subAccountId, collateralAmount);
        }
        // open
        tradingPrice = _pool.openPosition(order.subAccountId, order.size, collateralPrice, assetPrice);
        // tp/sl strategy
        if (order.isTpslStrategy()) {
            PositionOrderExtra memory extra = positionOrderExtras[orderId];
            delete positionOrderExtras[orderId];
            _placeTpslOrdersWhenOpen(order, extra);
        }
    }

    function _fillClosePositionOrder(
        uint64 orderId,
        uint96 collateralPrice,
        uint96 assetPrice,
        uint96 profitAssetPrice, // only used when !isLong
        PositionOrder memory order
    ) internal returns (uint96 tradingPrice) {
        // close
        tradingPrice = _pool.closePosition(
            order.subAccountId,
            order.size,
            order.profitTokenId,
            collateralPrice,
            assetPrice,
            profitAssetPrice
        );
        // auto withdraw
        uint96 collateralAmount = order.collateral;
        if (collateralAmount > 0) {
            _pool.withdrawCollateral(order.subAccountId, collateralAmount, collateralPrice, assetPrice);
        }
        // tp/sl strategy
        _activatedTpslOrders[order.subAccountId].remove(uint256(orderId));
        // is the position completely closed
        (uint96 collateral, uint96 size, , , ) = _pool.getSubAccount(order.subAccountId);
        if (size == 0) {
            // auto withdraw
            if (order.isWithdrawIfEmpty() && collateral > 0) {
                _pool.withdrawAllCollateral(order.subAccountId);
            }

            // cancel activated tp/sl orders
            LibOrderBook.cancelActivatedTpslOrders(_orders, _activatedTpslOrders, order.subAccountId);
        }
    }

    /**
     * @dev   Add/remove liquidity. called by Broker.
     *
     *        Check _getLiquidityFeeRate in Liquidity.sol on how to calculate liquidity fee.
     * @param orderId           order id.
     * @param assetPrice        token price that added/removed to. decimals = 18.
     * @param mlpPrice          mlp price. decimals = 18.
     * @param currentAssetValue liquidity USD value of a single asset in all chains (even if tokenId is a stable asset). decimals = 18.
     * @param targetAssetValue  weight / Σ weight * total liquidity USD value in all chains. decimals = 18.
     */
    function fillLiquidityOrder(
        uint64 orderId,
        uint96 assetPrice,
        uint96 mlpPrice,
        uint96 currentAssetValue,
        uint96 targetAssetValue
    ) external onlyBroker whenLiquidityOrderEnabled {
        require(_orders.contains(orderId), "OID"); // can not find this OrderID
        bytes32[3] memory orderData = _orders.get(orderId);
        _orders.remove(orderId);
        OrderType orderType = LibOrder.getOrderType(orderData);
        require(orderType == OrderType.LiquidityOrder, "TYP"); // order TYPe mismatch
        LibOrderBook.fillLiquidityOrder(
            _pool,
            _mlp,
            liquidityLockPeriod,
            _blockTimestamp(),
            assetPrice,
            mlpPrice,
            currentAssetValue,
            targetAssetValue,
            orderData
        );
        emit FillOrder(orderId, orderType, orderData);
    }

    /**
     * @dev   Withdraw collateral/profit. called by Broker.
     *
     * @param orderId           order id.
     * @param collateralPrice   collateral price. decimals = 18.
     * @param assetPrice        asset price. decimals = 18.
     * @param profitAssetPrice  profit asset price. decimals = 18.
     */
    function fillWithdrawalOrder(
        uint64 orderId,
        uint96 collateralPrice,
        uint96 assetPrice,
        uint96 profitAssetPrice // only used when !isLong
    ) external onlyBroker {
        require(_orders.contains(orderId), "OID"); // can not find this OrderID
        bytes32[3] memory orderData = _orders.get(orderId);
        _orders.remove(orderId);
        OrderType orderType = LibOrder.getOrderType(orderData);
        require(orderType == OrderType.WithdrawalOrder, "TYP"); // order TYPe mismatch

        WithdrawalOrder memory order = orderData.decodeWithdrawalOrder();
        require(_blockTimestamp() <= order.placeOrderTime + marketOrderTimeout, "EXP"); // EXPired
        if (order.isProfit) {
            _pool.withdrawProfit(
                order.subAccountId,
                order.rawAmount,
                order.profitTokenId,
                collateralPrice,
                assetPrice,
                profitAssetPrice
            );
        } else {
            _pool.withdrawCollateral(order.subAccountId, order.rawAmount, collateralPrice, assetPrice);
        }

        emit FillOrder(orderId, orderType, orderData);
    }

    /**
     * @dev   Rebalance. called by Broker.
     *
     * @param orderId  order id.
     * @param price0   price of token 0. decimals = 18.
     * @param price1   price of token 1. decimals = 18.
     */
    function fillRebalanceOrder(
        uint64 orderId,
        uint96 price0,
        uint96 price1
    ) external onlyBroker whenLiquidityOrderEnabled {
        require(_orders.contains(orderId), "OID"); // can not find this OrderID
        bytes32[3] memory orderData = _orders.get(orderId);
        _orders.remove(orderId);
        OrderType orderType = LibOrder.getOrderType(orderData);
        require(orderType == OrderType.RebalanceOrder, "TYP"); // order TYPe mismatch

        RebalanceOrder memory order = orderData.decodeRebalanceOrder();
        _pool.rebalance(
            order.rebalancer,
            order.tokenId0,
            order.tokenId1,
            order.rawAmount0,
            order.maxRawAmount1,
            order.userData,
            price0,
            price1
        );

        emit FillOrder(orderId, orderType, orderData);
    }

    /**
     * @notice Cancel an Order by orderId.
     */
    function cancelOrder(uint64 orderId) external {
        require(_orders.contains(orderId), "OID"); // can not find this OrderID
        bytes32[3] memory orderData = _orders.get(orderId);
        _orders.remove(orderId);
        address account = orderData.getOrderOwner();
        OrderType orderType = LibOrder.getOrderType(orderData);
        if (orderType == OrderType.PositionOrder) {
            PositionOrder memory order = orderData.decodePositionOrder();
            if (brokers[_msgSender()]) {
                require(_blockTimestamp() > _positionOrderDeadline(order), "EXP"); // not EXPired yet
            } else {
                require(_msgSender() == account, "SND"); // SeNDer is not authorized
            }
            if (order.isOpenPosition() && order.collateral > 0) {
                address collateralAddress = _pool.getAssetAddress(order.subAccountId.getSubAccountCollateralId());
                LibOrderBook._transferOut(_weth, _nativeUnwrapper, collateralAddress, account, order.collateral);
            }
            // tp/sl strategy
            delete positionOrderExtras[orderId];
            _activatedTpslOrders[order.subAccountId].remove(uint256(orderId));
        } else if (orderType == OrderType.LiquidityOrder) {
            require(_msgSender() == account, "SND"); // SeNDer is not authorized
            LiquidityOrder memory order = orderData.decodeLiquidityOrder();
            if (order.isAdding) {
                address collateralAddress = _pool.getAssetAddress(order.assetId);
                LibOrderBook._transferOut(_weth, _nativeUnwrapper, collateralAddress, account, order.rawAmount);
            } else {
                _mlp.safeTransfer(account, order.rawAmount);
            }
        } else if (orderType == OrderType.WithdrawalOrder) {
            if (brokers[_msgSender()]) {
                WithdrawalOrder memory order = orderData.decodeWithdrawalOrder();
                uint256 deadline = order.placeOrderTime + marketOrderTimeout;
                require(_blockTimestamp() > deadline, "EXP"); // not EXPired yet
            } else {
                require(_msgSender() == account, "SND"); // SeNDer is not authorized
            }
        } else if (orderType == OrderType.RebalanceOrder) {
            require(_msgSender() == account, "SND"); // SeNDer is not authorized
        } else {
            revert();
        }
        emit CancelOrder(orderId, LibOrder.getOrderType(orderData), orderData);
    }

    /**
     * @notice Trader can withdraw all collateral only when position = 0.
     */
    function withdrawAllCollateral(bytes32 subAccountId) external {
        require(subAccountId.getSubAccountOwner() == _msgSender(), "SND"); // SeNDer is not authorized
        _pool.withdrawAllCollateral(subAccountId);
    }

    /**
     * @notice Broker can update funding each [fundingInterval] seconds by specifying utilizations.
     *
     *         Check _getFundingRate in Liquidity.sol on how to calculate funding rate.
     * @param  stableUtilization    Stable coin utilization in all chains. decimals = 5.
     * @param  unstableTokenIds     All unstable Asset id(s) MUST be passed in order. ex: 1, 2, 5, 6, ...
     * @param  unstableUtilizations Unstable Asset utilizations in all chains decimals = 5.
     * @param  unstablePrices       Unstable Asset prices decimals = 18.
     */
    function updateFundingState(
        uint32 stableUtilization, // 1e5
        uint8[] calldata unstableTokenIds,
        uint32[] calldata unstableUtilizations, // 1e5
        uint96[] calldata unstablePrices // 1e18
    ) external onlyBroker {
        _pool.updateFundingState(stableUtilization, unstableTokenIds, unstableUtilizations, unstablePrices);
    }

    /**
     * @notice Deposit collateral into a subAccount.
     *
     * @param  subAccountId       sub account id. see LibSubAccount.decodeSubAccountId.
     * @param  collateralAmount   collateral amount. decimals = erc20.decimals.
     */
    function depositCollateral(bytes32 subAccountId, uint256 collateralAmount) external payable {
        LibSubAccount.DecodedSubAccountId memory account = subAccountId.decodeSubAccountId();
        require(account.account == _msgSender(), "SND"); // SeNDer is not authorized
        require(collateralAmount != 0, "C=0"); // Collateral Is Zero
        address collateralAddress = _pool.getAssetAddress(account.collateralId);
        LibOrderBook._transferIn(_weth, _msgSender(), collateralAddress, address(_pool), collateralAmount);
        _pool.depositCollateral(subAccountId, collateralAmount);
    }

    function liquidate(
        bytes32 subAccountId,
        uint8 profitAssetId, // only used when !isLong
        uint96 collateralPrice,
        uint96 assetPrice,
        uint96 profitAssetPrice // only used when !isLong
    ) external onlyBroker {
        _pool.liquidate(subAccountId, profitAssetId, collateralPrice, assetPrice, profitAssetPrice);
        // auto withdraw
        (uint96 collateral, , , , ) = _pool.getSubAccount(subAccountId);
        if (collateral > 0) {
            _pool.withdrawAllCollateral(subAccountId);
        }
        // cancel activated tp/sl orders
        LibOrderBook.cancelActivatedTpslOrders(_orders, _activatedTpslOrders, subAccountId);
    }

    function redeemMuxToken(uint8 tokenId, uint96 muxTokenAmount) external {
        address trader = _msgSender();
        LibOrderBook.redeemMuxToken(_pool, _weth, trader, tokenId, muxTokenAmount);
    }

    /**
     * @dev Broker can withdraw brokerGasRebate.
     */
    function claimBrokerGasRebate() external onlyBroker returns (uint256 rawAmount) {
        return _pool.claimBrokerGasRebate(msg.sender);
    }

    function _blockTimestamp() internal view virtual returns (uint32) {
        return uint32(block.timestamp);
    }

    function _positionOrderDeadline(PositionOrder memory order) internal view returns (uint32) {
        if (order.isMarketOrder()) {
            return order.placeOrderTime + marketOrderTimeout;
        } else {
            return order.placeOrderTime + LibMath.min32(uint32(order.expire10s) * 10, maxLimitOrderTimeout);
        }
    }

    function _placeTpslOrdersWhenOpen(PositionOrder memory order, PositionOrderExtra memory extra) internal {
        if (extra.tpPrice > 0) {
            uint64 orderId = _placePositionOrder(
                order.subAccountId,
                0 /* collateralAmount */, // tp/sl strategy only supports POSITION_WITHDRAW_ALL_IF_EMPTY
                order.size,
                extra.tpPrice,
                extra.tpslProfitTokenId,
                LibOrder.POSITION_WITHDRAW_ALL_IF_EMPTY,
                extra.tpslDeadline
            );
            _activatedTpslOrders[order.subAccountId].add(uint256(orderId));
        }
        if (extra.slPrice > 0) {
            uint64 orderId = _placePositionOrder(
                order.subAccountId,
                0 /* collateralAmount */, // tp/sl strategy only supports POSITION_WITHDRAW_ALL_IF_EMPTY
                order.size,
                extra.slPrice,
                extra.tpslProfitTokenId,
                LibOrder.POSITION_WITHDRAW_ALL_IF_EMPTY | LibOrder.POSITION_TRIGGER_ORDER,
                extra.tpslDeadline
            );
            _activatedTpslOrders[order.subAccountId].add(uint256(orderId));
        }
    }

    function _placeTpslOrdersWhenClose(
        bytes32 subAccountId,
        uint96 size, // 1e18
        PositionOrderExtra memory extra
    ) internal {
        if (extra.tpPrice > 0) {
            uint64 orderId = _placePositionOrder(
                subAccountId,
                0 /* collateralAmount */, // tp/sl strategy only supports POSITION_WITHDRAW_ALL_IF_EMPTY
                size,
                extra.tpPrice,
                extra.tpslProfitTokenId,
                LibOrder.POSITION_WITHDRAW_ALL_IF_EMPTY,
                extra.tpslDeadline
            );
            _activatedTpslOrders[subAccountId].add(uint256(orderId));
        }
        if (extra.slPrice > 0) {
            uint64 orderId = _placePositionOrder(
                subAccountId,
                0 /* collateralAmount */, // tp/sl strategy only supports POSITION_WITHDRAW_ALL_IF_EMPTY
                size,
                extra.slPrice,
                extra.tpslProfitTokenId,
                LibOrder.POSITION_WITHDRAW_ALL_IF_EMPTY | LibOrder.POSITION_TRIGGER_ORDER,
                extra.tpslDeadline
            );
            _activatedTpslOrders[subAccountId].add(uint256(orderId));
        }
    }
}