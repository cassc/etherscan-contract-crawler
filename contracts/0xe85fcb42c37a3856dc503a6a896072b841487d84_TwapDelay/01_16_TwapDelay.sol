// SPDX-License-Identifier: GPL-3.0-or-later
// Deployed with donations via Gitcoin GR9

pragma solidity 0.7.6;
pragma abicoder v2;

import './interfaces/ITwapPair.sol';
import './interfaces/ITwapDelay.sol';
import './interfaces/IWETH.sol';
import './libraries/SafeMath.sol';
import './libraries/Orders.sol';
import './libraries/TokenShares.sol';
import './libraries/AddLiquidity.sol';
import './libraries/WithdrawHelper.sol';

contract TwapDelay is ITwapDelay {
    using SafeMath for uint256;
    using Orders for Orders.Data;
    using TokenShares for TokenShares.Data;

    Orders.Data internal orders;
    TokenShares.Data internal tokenShares;

    uint256 private constant ORDER_CANCEL_TIME = 24 hours;
    uint256 private constant BOT_EXECUTION_TIME = 20 minutes;
    uint256 private constant ORDER_LIFESPAN = 48 hours;
    uint16 private constant MAX_TOLERANCE = 10;

    address public override owner;
    mapping(address => bool) public override isBot;

    mapping(address => uint16) public override tolerance;

    constructor(
        address _factory,
        address _weth,
        address _bot
    ) {
        orders.factory = _factory;
        owner = msg.sender;
        isBot[_bot] = true;
        orders.gasPrice = tx.gasprice;
        tokenShares.weth = _weth;
        orders.delay = 30 minutes;
        orders.maxGasLimit = 5_000_000;
        orders.gasPriceInertia = 20_000_000;
        orders.maxGasPriceImpact = 1_000_000;
        orders.setTransferGasCost(address(0), Orders.ETHER_TRANSFER_CALL_COST);

        emit OwnerSet(msg.sender);
    }

    function getTransferGasCost(address token) external view override returns (uint256 gasCost) {
        return orders.transferGasCosts[token];
    }

    function getDepositDisabled(address pair) external view override returns (bool) {
        return orders.getDepositDisabled(pair);
    }

    function getWithdrawDisabled(address pair) external view override returns (bool) {
        return orders.getWithdrawDisabled(pair);
    }

    function getBuyDisabled(address pair) external view override returns (bool) {
        return orders.getBuyDisabled(pair);
    }

    function getSellDisabled(address pair) external view override returns (bool) {
        return orders.getSellDisabled(pair);
    }

    function getOrderStatus(uint256 orderId, uint256 validAfterTimestamp)
        external
        view
        override
        returns (Orders.OrderStatus)
    {
        return orders.getOrderStatus(orderId, validAfterTimestamp);
    }

    uint256 private locked;
    modifier lock() {
        require(locked == 0, 'TD06');
        locked = 1;
        _;
        locked = 0;
    }

    function factory() external view override returns (address) {
        return orders.factory;
    }

    function totalShares(address token) external view override returns (uint256) {
        return tokenShares.totalShares[token];
    }

    // returns wrapped native currency for particular blockchain (WETH or WMATIC)
    function weth() external view override returns (address) {
        return tokenShares.weth;
    }

    function delay() external view override returns (uint256) {
        return orders.delay;
    }

    function lastProcessedOrderId() external view returns (uint256) {
        return orders.lastProcessedOrderId;
    }

    function newestOrderId() external view returns (uint256) {
        return orders.newestOrderId;
    }

    function isOrderCanceled(uint256 orderId) external view returns (bool) {
        return orders.canceled[orderId];
    }

    function maxGasLimit() external view override returns (uint256) {
        return orders.maxGasLimit;
    }

    function maxGasPriceImpact() external view override returns (uint256) {
        return orders.maxGasPriceImpact;
    }

    function gasPriceInertia() external view override returns (uint256) {
        return orders.gasPriceInertia;
    }

    function gasPrice() external view override returns (uint256) {
        return orders.gasPrice;
    }

    function setOrderDisabled(
        address pair,
        Orders.OrderType orderType,
        bool disabled
    ) external payable override {
        require(msg.sender == owner, 'TD00');
        orders.setOrderDisabled(pair, orderType, disabled);
    }

    function setOwner(address _owner) external payable override {
        require(msg.sender == owner, 'TD00');
        // require(_owner != owner, 'TD01'); // Comment out to save size
        require(_owner != address(0), 'TD02');
        owner = _owner;
        emit OwnerSet(_owner);
    }

    function setBot(address _bot, bool _isBot) external payable override {
        require(msg.sender == owner, 'TD00');
        // require(_isBot != isBot[_bot], 'TD01'); // Comment out to save size
        isBot[_bot] = _isBot;
        emit BotSet(_bot, _isBot);
    }

    function setMaxGasLimit(uint256 _maxGasLimit) external payable override {
        require(msg.sender == owner, 'TD00');
        orders.setMaxGasLimit(_maxGasLimit);
    }

    function setDelay(uint32 _delay) external payable override {
        require(msg.sender == owner, 'TD00');
        // require(_delay != orders.delay, 'TD01'); // Comment out to save size
        orders.delay = _delay;
        emit DelaySet(_delay);
    }

    function setGasPriceInertia(uint256 _gasPriceInertia) external payable override {
        require(msg.sender == owner, 'TD00');
        orders.setGasPriceInertia(_gasPriceInertia);
    }

    function setMaxGasPriceImpact(uint256 _maxGasPriceImpact) external payable override {
        require(msg.sender == owner, 'TD00');
        orders.setMaxGasPriceImpact(_maxGasPriceImpact);
    }

    function setTransferGasCost(address token, uint256 gasCost) external payable override {
        require(msg.sender == owner, 'TD00');
        orders.setTransferGasCost(token, gasCost);
    }

    function setTolerance(address pair, uint16 amount) external payable override {
        require(msg.sender == owner, 'TD00');
        require(amount <= MAX_TOLERANCE, 'TD54');
        tolerance[pair] = amount;
        emit ToleranceSet(pair, amount);
    }

    function deposit(Orders.DepositParams calldata depositParams)
        external
        payable
        override
        lock
        returns (uint256 orderId)
    {
        orders.deposit(depositParams, tokenShares);
        return orders.newestOrderId;
    }

    function withdraw(Orders.WithdrawParams calldata withdrawParams)
        external
        payable
        override
        lock
        returns (uint256 orderId)
    {
        orders.withdraw(withdrawParams);
        return orders.newestOrderId;
    }

    function sell(Orders.SellParams calldata sellParams) external payable override lock returns (uint256 orderId) {
        orders.sell(sellParams, tokenShares);
        return orders.newestOrderId;
    }

    function buy(Orders.BuyParams calldata buyParams) external payable override lock returns (uint256 orderId) {
        orders.buy(buyParams, tokenShares);
        return orders.newestOrderId;
    }

    /// @dev This implementation processes orders sequentially and skips orders that have already been executed.
    /// If it encounters an order that is not yet valid, it stops execution since subsequent orders will also be invalid
    /// at the time.
    function execute(Orders.Order[] calldata _orders) external payable override lock {
        uint256 ordersLength = _orders.length;
        uint256 gasBefore = gasleft();
        bool orderExecuted;
        bool senderCanExecute = isBot[msg.sender] || isBot[address(0)];
        for (uint256 i; i < ordersLength; ++i) {
            if (_orders[i].orderId <= orders.lastProcessedOrderId) {
                continue;
            }
            if (orders.canceled[_orders[i].orderId]) {
                orders.dequeueOrder(_orders[i].orderId);
                continue;
            }
            orders.verifyOrder(_orders[i]);
            uint256 validAfterTimestamp = _orders[i].validAfterTimestamp;
            if (validAfterTimestamp >= block.timestamp) {
                break;
            }
            require(senderCanExecute || block.timestamp >= validAfterTimestamp + BOT_EXECUTION_TIME, 'TD00');
            orderExecuted = true;
            if (_orders[i].orderType == Orders.DEPOSIT_TYPE) {
                executeDeposit(_orders[i]);
            } else if (_orders[i].orderType == Orders.WITHDRAW_TYPE) {
                executeWithdraw(_orders[i]);
            } else if (_orders[i].orderType == Orders.SELL_TYPE || _orders[i].orderType == Orders.SELL_INVERTED_TYPE) {
                executeSell(_orders[i]);
            } else if (_orders[i].orderType == Orders.BUY_TYPE || _orders[i].orderType == Orders.BUY_INVERTED_TYPE) {
                executeBuy(_orders[i]);
            }
        }
        if (orderExecuted) {
            orders.updateGasPrice(gasBefore.sub(gasleft()));
        }
    }

    /// @dev The `order` must be verified by calling `Orders.verifyOrder` before calling this function.
    function executeDeposit(Orders.Order calldata order) internal {
        uint256 gasStart = gasleft();
        orders.dequeueOrder(order.orderId);

        (bool executionSuccess, bytes memory data) = address(this).call{
            gas: order.gasLimit.sub(
                Orders.ORDER_BASE_COST.add(orders.transferGasCosts[order.token0]).add(
                    orders.transferGasCosts[order.token1]
                )
            )
        }(abi.encodeWithSelector(this._executeDeposit.selector, order));

        bool refundSuccess = true;
        if (!executionSuccess) {
            refundSuccess = refundTokens(
                order.to,
                order.token0,
                order.value0,
                order.token1,
                order.value1,
                order.unwrap
            );
        }
        finalizeOrder(refundSuccess);
        (uint256 gasUsed, uint256 ethRefund) = refund(order.gasLimit, order.gasPrice, gasStart, order.to);
        emit OrderExecuted(orders.lastProcessedOrderId, executionSuccess, data, gasUsed, ethRefund);
    }

    /// @dev The `order` must be verified by calling `Orders.verifyOrder` before calling this function.
    function executeWithdraw(Orders.Order calldata order) internal {
        uint256 gasStart = gasleft();
        orders.dequeueOrder(order.orderId);

        (bool executionSuccess, bytes memory data) = address(this).call{
            gas: order.gasLimit.sub(Orders.ORDER_BASE_COST.add(Orders.PAIR_TRANSFER_COST))
        }(abi.encodeWithSelector(this._executeWithdraw.selector, order));

        bool refundSuccess = true;
        if (!executionSuccess) {
            (address pair, ) = orders.getPair(order.token0, order.token1);
            refundSuccess = Orders.refundLiquidity(pair, order.to, order.liquidity, this._refundLiquidity.selector);
        }
        finalizeOrder(refundSuccess);
        (uint256 gasUsed, uint256 ethRefund) = refund(order.gasLimit, order.gasPrice, gasStart, order.to);
        emit OrderExecuted(orders.lastProcessedOrderId, executionSuccess, data, gasUsed, ethRefund);
    }

    /// @dev The `order` must be verified by calling `Orders.verifyOrder` before calling this function.
    function executeSell(Orders.Order calldata order) internal {
        uint256 gasStart = gasleft();
        orders.dequeueOrder(order.orderId);

        (bool executionSuccess, bytes memory data) = address(this).call{
            gas: order.gasLimit.sub(Orders.ORDER_BASE_COST.add(orders.transferGasCosts[order.token0]))
        }(abi.encodeWithSelector(this._executeSell.selector, order));

        bool refundSuccess = true;
        if (!executionSuccess) {
            refundSuccess = refundToken(order.token0, order.to, order.value0, order.unwrap);
        }
        finalizeOrder(refundSuccess);
        (uint256 gasUsed, uint256 ethRefund) = refund(order.gasLimit, order.gasPrice, gasStart, order.to);
        emit OrderExecuted(orders.lastProcessedOrderId, executionSuccess, data, gasUsed, ethRefund);
    }

    /// @dev The `order` must be verified by calling `Orders.verifyOrder` before calling this function.
    function executeBuy(Orders.Order calldata order) internal {
        uint256 gasStart = gasleft();
        orders.dequeueOrder(order.orderId);

        (bool executionSuccess, bytes memory data) = address(this).call{
            gas: order.gasLimit.sub(Orders.ORDER_BASE_COST.add(orders.transferGasCosts[order.token0]))
        }(abi.encodeWithSelector(this._executeBuy.selector, order));

        bool refundSuccess = true;
        if (!executionSuccess) {
            refundSuccess = refundToken(order.token0, order.to, order.value0, order.unwrap);
        }
        finalizeOrder(refundSuccess);
        (uint256 gasUsed, uint256 ethRefund) = refund(order.gasLimit, order.gasPrice, gasStart, order.to);
        emit OrderExecuted(orders.lastProcessedOrderId, executionSuccess, data, gasUsed, ethRefund);
    }

    function finalizeOrder(bool refundSuccess) private {
        if (!refundSuccess) {
            orders.markRefundFailed();
        } else {
            orders.forgetLastProcessedOrder();
        }
    }

    function refund(
        uint256 gasLimit,
        uint256 gasPriceInOrder,
        uint256 gasStart,
        address to
    ) private returns (uint256 gasUsed, uint256 leftOver) {
        uint256 feeCollected = gasLimit.mul(gasPriceInOrder);
        gasUsed = gasStart.sub(gasleft()).add(Orders.REFUND_BASE_COST);
        uint256 actualRefund = Math.min(feeCollected, gasUsed.mul(orders.gasPrice));
        leftOver = feeCollected.sub(actualRefund);
        require(refundEth(msg.sender, actualRefund), 'TD40');
        refundEth(payable(to), leftOver);
    }

    function refundEth(address payable to, uint256 value) internal returns (bool success) {
        if (value == 0) {
            return true;
        }
        success = TransferHelper.transferETH(to, value, orders.transferGasCosts[address(0)]);
        emit EthRefund(to, success, value);
    }

    function refundToken(
        address token,
        address to,
        uint256 share,
        bool unwrap
    ) private returns (bool) {
        if (share == 0) {
            return true;
        }
        (bool success, bytes memory data) = address(this).call{ gas: orders.transferGasCosts[token] }(
            abi.encodeWithSelector(this._refundToken.selector, token, to, share, unwrap)
        );
        if (!success) {
            emit RefundFailed(to, token, share, data);
        }
        return success;
    }

    function refundTokens(
        address to,
        address token0,
        uint256 share0,
        address token1,
        uint256 share1,
        bool unwrap
    ) private returns (bool) {
        (bool success, bytes memory data) = address(this).call{
            gas: orders.transferGasCosts[token0].add(orders.transferGasCosts[token1])
        }(abi.encodeWithSelector(this._refundTokens.selector, to, token0, share0, token1, share1, unwrap));
        if (!success) {
            emit RefundFailed(to, token0, share0, data);
            emit RefundFailed(to, token1, share1, data);
        }
        return success;
    }

    function _refundTokens(
        address to,
        address token0,
        uint256 share0,
        address token1,
        uint256 share1,
        bool unwrap
    ) external payable {
        // no need to check sender, because it is checked in _refundToken
        _refundToken(token0, to, share0, unwrap);
        _refundToken(token1, to, share1, unwrap);
    }

    function _refundToken(
        address token,
        address to,
        uint256 share,
        bool unwrap
    ) public payable {
        require(msg.sender == address(this), 'TD00');
        if (token == tokenShares.weth && unwrap) {
            uint256 amount = tokenShares.sharesToAmount(token, share, 0, to);
            IWETH(tokenShares.weth).withdraw(amount);
            TransferHelper.safeTransferETH(to, amount, orders.transferGasCosts[address(0)]);
        } else {
            TransferHelper.safeTransfer(token, to, tokenShares.sharesToAmount(token, share, 0, to));
        }
    }

    function _refundLiquidity(
        address pair,
        address to,
        uint256 liquidity
    ) external payable {
        require(msg.sender == address(this), 'TD00');
        return TransferHelper.safeTransfer(pair, to, liquidity);
    }

    function _executeDeposit(Orders.Order calldata order) external payable {
        require(msg.sender == address(this), 'TD00');
        require(order.validAfterTimestamp + ORDER_LIFESPAN >= block.timestamp, 'TD04');

        (address pair, ) = orders.getPair(order.token0, order.token1);
        (uint256 amount0Left, uint256 amount1Left, uint256 swapToken) = _initialDeposit(order, pair);

        if (order.swap && swapToken != 0) {
            bytes memory data = encodePriceInfo(pair, order.priceAccumulator, order.timestamp);
            if (amount0Left != 0 && swapToken == 1) {
                uint256 extraAmount1;
                (amount0Left, extraAmount1) = AddLiquidity.swapDeposit0(
                    pair,
                    order.token0,
                    amount0Left,
                    order.minSwapPrice,
                    tolerance[pair],
                    data
                );
                amount1Left = amount1Left.add(extraAmount1);
            } else if (amount1Left != 0 && swapToken == 2) {
                uint256 extraAmount0;
                (extraAmount0, amount1Left) = AddLiquidity.swapDeposit1(
                    pair,
                    order.token1,
                    amount1Left,
                    order.maxSwapPrice,
                    tolerance[pair],
                    data
                );
                amount0Left = amount0Left.add(extraAmount0);
            }
        }

        if (amount0Left != 0 && amount1Left != 0) {
            (amount0Left, amount1Left, ) = AddLiquidity.addLiquidityAndMint(
                pair,
                order.to,
                order.token0,
                order.token1,
                amount0Left,
                amount1Left
            );
        }

        AddLiquidity._refundDeposit(order.to, order.token0, order.token1, amount0Left, amount1Left);
    }

    function _initialDeposit(Orders.Order calldata order, address pair)
        private
        returns (
            uint256 amount0Left,
            uint256 amount1Left,
            uint256 swapToken
        )
    {
        uint256 amount0Desired = tokenShares.sharesToAmount(order.token0, order.value0, order.amountLimit0, order.to);
        uint256 amount1Desired = tokenShares.sharesToAmount(order.token1, order.value1, order.amountLimit1, order.to);
        ITwapPair(pair).sync();
        (amount0Left, amount1Left, swapToken) = AddLiquidity.addLiquidityAndMint(
            pair,
            order.to,
            order.token0,
            order.token1,
            amount0Desired,
            amount1Desired
        );
    }

    function _executeWithdraw(Orders.Order calldata order) external payable {
        require(msg.sender == address(this), 'TD00');
        require(order.validAfterTimestamp + ORDER_LIFESPAN >= block.timestamp, 'TD04');
        (address pair, ) = orders.getPair(order.token0, order.token1);
        ITwapPair(pair).sync();
        TransferHelper.safeTransfer(pair, pair, order.liquidity);
        uint256 wethAmount;
        uint256 amount0;
        uint256 amount1;
        if (order.unwrap && (order.token0 == tokenShares.weth || order.token1 == tokenShares.weth)) {
            bool success;
            (success, wethAmount, amount0, amount1) = WithdrawHelper.withdrawAndUnwrap(
                order.token0,
                order.token1,
                pair,
                tokenShares.weth,
                order.to,
                orders.transferGasCosts[address(0)]
            );
            if (!success) {
                tokenShares.onUnwrapFailed(order.to, wethAmount);
            }
        } else {
            (amount0, amount1) = ITwapPair(pair).burn(order.to);
        }
        require(amount0 >= order.value0 && amount1 >= order.value1, 'TD03');
    }

    function _executeBuy(Orders.Order calldata order) external payable {
        require(msg.sender == address(this), 'TD00');
        require(order.validAfterTimestamp + ORDER_LIFESPAN >= block.timestamp, 'TD04');

        (address pairAddress, ) = orders.getPair(order.token0, order.token1);
        uint256 amountInMax = tokenShares.sharesToAmount(order.token0, order.value0, order.amountLimit0, order.to);
        ITwapPair(pairAddress).sync();
        bytes memory priceInfo = encodePriceInfo(pairAddress, order.priceAccumulator, order.timestamp);
        uint256 amountIn;
        uint256 amountOut;
        uint256 reserveOut;
        bool inverted = order.orderType == Orders.BUY_INVERTED_TYPE;
        {
            // scope for reserve out logic, avoids stack too deep errors
            (uint112 reserve0, uint112 reserve1) = ITwapPair(pairAddress).getReserves();
            // subtract 1 to prevent reserve going to 0
            reserveOut = uint256(inverted ? reserve0 : reserve1).sub(1);
        }
        {
            // scope for partial fill logic, avoids stack too deep errors
            address oracle = ITwapPair(pairAddress).oracle();
            uint256 swapFee = ITwapPair(pairAddress).swapFee();
            (amountIn, amountOut) = ITwapOracle(oracle).getSwapAmountInMaxOut(
                inverted,
                swapFee,
                order.value1,
                priceInfo
            );
            uint256 amountInMaxScaled;
            if (amountOut > reserveOut) {
                amountInMaxScaled = amountInMax.mul(reserveOut).ceil_div(order.value1);
                (amountIn, amountOut) = ITwapOracle(oracle).getSwapAmountInMinOut(
                    inverted,
                    swapFee,
                    reserveOut,
                    priceInfo
                );
            } else {
                amountInMaxScaled = amountInMax;
                amountOut = order.value1; // Truncate to desired out
            }
            require(amountInMaxScaled >= amountIn, 'TD08');
            if (amountInMax > amountIn) {
                if (order.token0 == tokenShares.weth && order.unwrap) {
                    _forceEtherTransfer(order.to, amountInMax.sub(amountIn));
                } else {
                    TransferHelper.safeTransfer(order.token0, order.to, amountInMax.sub(amountIn));
                }
            }
            TransferHelper.safeTransfer(order.token0, pairAddress, amountIn);
        }
        amountOut = amountOut.sub(tolerance[pairAddress]);
        uint256 amount0Out;
        uint256 amount1Out;
        if (inverted) {
            amount0Out = amountOut;
        } else {
            amount1Out = amountOut;
        }
        if (order.token1 == tokenShares.weth && order.unwrap) {
            ITwapPair(pairAddress).swap(amount0Out, amount1Out, address(this), priceInfo);
            _forceEtherTransfer(order.to, amountOut);
        } else {
            ITwapPair(pairAddress).swap(amount0Out, amount1Out, order.to, priceInfo);
        }
    }

    function _executeSell(Orders.Order calldata order) external payable {
        require(msg.sender == address(this), 'TD00');
        require(order.validAfterTimestamp + ORDER_LIFESPAN >= block.timestamp, 'TD04');

        (address pairAddress, ) = orders.getPair(order.token0, order.token1);
        ITwapPair(pairAddress).sync();
        bytes memory priceInfo = encodePriceInfo(pairAddress, order.priceAccumulator, order.timestamp);

        bool inverted = order.orderType == Orders.SELL_INVERTED_TYPE;
        uint256 amountOut = _executeSellHelper(order, inverted, pairAddress, priceInfo);

        (uint256 amount0Out, uint256 amount1Out) = inverted ? (amountOut, uint256(0)) : (uint256(0), amountOut);
        if (order.token1 == tokenShares.weth && order.unwrap) {
            ITwapPair(pairAddress).swap(amount0Out, amount1Out, address(this), priceInfo);
            _forceEtherTransfer(order.to, amountOut);
        } else {
            ITwapPair(pairAddress).swap(amount0Out, amount1Out, order.to, priceInfo);
        }
    }

    function _executeSellHelper(
        Orders.Order calldata order,
        bool inverted,
        address pairAddress,
        bytes memory priceInfo
    ) internal returns (uint256 amountOut) {
        uint256 reserveOut;
        {
            // scope for determining reserve out, avoids stack too deep errors
            (uint112 reserve0, uint112 reserve1) = ITwapPair(pairAddress).getReserves();
            // subtract 1 to prevent reserve going to 0
            reserveOut = uint256(inverted ? reserve0 : reserve1).sub(1);
        }
        {
            // scope for calculations, avoids stack too deep errors
            address oracle = ITwapPair(pairAddress).oracle();
            uint256 swapFee = ITwapPair(pairAddress).swapFee();
            uint256 amountIn = tokenShares.sharesToAmount(order.token0, order.value0, order.amountLimit0, order.to);
            amountOut = inverted
                ? ITwapOracle(oracle).getSwapAmount0Out(swapFee, amountIn, priceInfo)
                : ITwapOracle(oracle).getSwapAmount1Out(swapFee, amountIn, priceInfo);

            uint256 amountOutMinScaled;
            if (amountOut > reserveOut) {
                amountOutMinScaled = order.value1.mul(reserveOut).div(amountOut);
                uint256 _amountIn = amountIn;
                (amountIn, amountOut) = ITwapOracle(oracle).getSwapAmountInMinOut(
                    inverted,
                    swapFee,
                    reserveOut,
                    priceInfo
                );
                if (order.token0 == tokenShares.weth && order.unwrap) {
                    _forceEtherTransfer(order.to, _amountIn.sub(amountIn));
                } else {
                    TransferHelper.safeTransfer(order.token0, order.to, _amountIn.sub(amountIn));
                }
            } else {
                amountOutMinScaled = order.value1;
            }
            amountOut = amountOut.sub(tolerance[pairAddress]);
            require(amountOut >= amountOutMinScaled, 'TD37');
            TransferHelper.safeTransfer(order.token0, pairAddress, amountIn);
        }
    }

    function _forceEtherTransfer(address to, uint256 amount) internal {
        IWETH(tokenShares.weth).withdraw(amount);
        (bool success, ) = to.call{ value: amount, gas: orders.transferGasCosts[address(0)] }('');
        if (!success) {
            tokenShares.onUnwrapFailed(to, amount);
        }
    }

    /// @dev The `order` must be verified by calling `Orders.verifyOrder` before calling this function.
    function performRefund(Orders.Order calldata order, bool shouldRefundEth) internal {
        bool canOwnerRefund = order.validAfterTimestamp.add(365 days) < block.timestamp;

        if (order.orderType == Orders.DEPOSIT_TYPE) {
            address to = canOwnerRefund ? owner : order.to;
            require(refundTokens(to, order.token0, order.value0, order.token1, order.value1, order.unwrap), 'TD14');
            if (shouldRefundEth) {
                require(refundEth(payable(to), order.gasPrice.mul(order.gasLimit)), 'TD40');
            }
        } else if (order.orderType == Orders.WITHDRAW_TYPE) {
            (address pair, ) = orders.getPair(order.token0, order.token1);
            address to = canOwnerRefund ? owner : order.to;
            require(Orders.refundLiquidity(pair, to, order.liquidity, this._refundLiquidity.selector), 'TD14');
            if (shouldRefundEth) {
                require(refundEth(payable(to), order.gasPrice.mul(order.gasLimit)), 'TD40');
            }
        } else if (order.orderType == Orders.SELL_TYPE || order.orderType == Orders.SELL_INVERTED_TYPE) {
            address to = canOwnerRefund ? owner : order.to;
            require(refundToken(order.token0, to, order.value0, order.unwrap), 'TD14');
            if (shouldRefundEth) {
                require(refundEth(payable(to), order.gasPrice.mul(order.gasLimit)), 'TD40');
            }
        } else if (order.orderType == Orders.BUY_TYPE || order.orderType == Orders.BUY_INVERTED_TYPE) {
            address to = canOwnerRefund ? owner : order.to;
            require(refundToken(order.token0, to, order.value0, order.unwrap), 'TD14');
            if (shouldRefundEth) {
                require(refundEth(payable(to), order.gasPrice.mul(order.gasLimit)), 'TD40');
            }
        } else {
            return;
        }
        orders.forgetOrder(order.orderId);
    }

    function retryRefund(Orders.Order calldata order) external override lock {
        orders.verifyOrder(order);
        require(orders.refundFailed[order.orderId], 'TD21');
        performRefund(order, false);
    }

    function cancelOrder(Orders.Order calldata order) external override lock {
        orders.verifyOrder(order);
        require(
            orders.getOrderStatus(order.orderId, order.validAfterTimestamp) == Orders.OrderStatus.EnqueuedReady,
            'TD52'
        );
        require(order.validAfterTimestamp.sub(orders.delay).add(ORDER_CANCEL_TIME) < block.timestamp, 'TD1C');
        orders.canceled[order.orderId] = true;
        performRefund(order, true);
    }

    function encodePriceInfo(
        address pair,
        uint256 priceAccumulator,
        uint256 priceTimestamp
    ) internal view returns (bytes memory data) {
        uint256 price = ITwapOracle(ITwapPair(pair).oracle()).getAveragePrice(priceAccumulator, priceTimestamp);
        // Pack everything as 32 bytes / uint256 to simplify decoding
        data = abi.encode(price);
    }

    receive() external payable {}
}