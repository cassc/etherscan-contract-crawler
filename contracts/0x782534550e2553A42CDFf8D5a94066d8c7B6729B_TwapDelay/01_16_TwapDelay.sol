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
        orders.gasPrice = tx.gasprice - (tx.gasprice % 1e6);
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

    function getDepositOrder(uint256 orderId) external view override returns (Orders.DepositOrder memory order) {
        (order, , ) = orders.getDepositOrder(orderId);
    }

    function getWithdrawOrder(uint256 orderId) external view override returns (Orders.WithdrawOrder memory order) {
        return orders.getWithdrawOrder(orderId);
    }

    function getSellOrder(uint256 orderId) external view override returns (Orders.SellOrder memory order) {
        (order, ) = orders.getSellOrder(orderId);
    }

    function getBuyOrder(uint256 orderId) external view override returns (Orders.BuyOrder memory order) {
        (order, ) = orders.getBuyOrder(orderId);
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

    function getOrderStatus(uint256 orderId) external view override returns (Orders.OrderStatus) {
        return orders.getOrderStatus(orderId);
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

    function weth() external view override returns (address) {
        return tokenShares.weth;
    }

    function delay() external view override returns (uint32) {
        return orders.delay;
    }

    function lastProcessedOrderId() external view returns (uint256) {
        return orders.lastProcessedOrderId;
    }

    function newestOrderId() external view returns (uint256) {
        return orders.newestOrderId;
    }

    function getOrder(uint256 orderId) external view returns (Orders.OrderType orderType, uint32 validAfterTimestamp) {
        return orders.getOrder(orderId);
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

    function execute(uint256 n) external payable override lock {
        emit Execute(msg.sender, n);
        uint256 gasBefore = gasleft();
        bool orderExecuted;
        bool senderCanExecute = isBot[msg.sender] || isBot[address(0)];
        for (uint256 i; i < n; ++i) {
            if (orders.canceled[orders.lastProcessedOrderId + 1]) {
                orders.dequeueCanceledOrder();
                continue;
            }
            (Orders.OrderType orderType, uint256 validAfterTimestamp) = orders.getNextOrder();
            if (orderType == Orders.OrderType.Empty || validAfterTimestamp >= block.timestamp) {
                break;
            }
            require(senderCanExecute || block.timestamp >= validAfterTimestamp + BOT_EXECUTION_TIME, 'TD00');
            orderExecuted = true;
            if (orderType == Orders.OrderType.Deposit) {
                executeDeposit();
            } else if (orderType == Orders.OrderType.Withdraw) {
                executeWithdraw();
            } else if (orderType == Orders.OrderType.Sell) {
                executeSell();
            } else if (orderType == Orders.OrderType.Buy) {
                executeBuy();
            }
        }
        if (orderExecuted) {
            orders.updateGasPrice(gasBefore.sub(gasleft()));
        }
    }

    function executeDeposit() internal {
        uint256 gasStart = gasleft();
        (Orders.DepositOrder memory depositOrder, uint256 amountLimit0, uint256 amountLimit1) = orders
            .dequeueDepositOrder();
        (, address token0, address token1) = orders.getPairInfo(depositOrder.pairId);
        (bool executionSuccess, bytes memory data) = address(this).call{
            gas: depositOrder.gasLimit.sub(
                Orders.ORDER_BASE_COST.add(orders.transferGasCosts[token0]).add(orders.transferGasCosts[token1])
            )
        }(abi.encodeWithSelector(this._executeDeposit.selector, depositOrder, amountLimit0, amountLimit1));
        bool refundSuccess = true;
        if (!executionSuccess) {
            refundSuccess = refundTokens(
                depositOrder.to,
                token0,
                depositOrder.share0,
                token1,
                depositOrder.share1,
                depositOrder.unwrap
            );
        }
        finalizeOrder(refundSuccess);
        (uint256 gasUsed, uint256 ethRefund) = refund(
            depositOrder.gasLimit,
            depositOrder.gasPrice,
            gasStart,
            depositOrder.to
        );
        emit OrderExecuted(orders.lastProcessedOrderId, executionSuccess, data, gasUsed, ethRefund);
    }

    function executeWithdraw() internal {
        uint256 gasStart = gasleft();
        Orders.WithdrawOrder memory withdrawOrder = orders.dequeueWithdrawOrder();
        (bool executionSuccess, bytes memory data) = address(this).call{
            gas: withdrawOrder.gasLimit.sub(Orders.ORDER_BASE_COST.add(Orders.PAIR_TRANSFER_COST))
        }(abi.encodeWithSelector(this._executeWithdraw.selector, withdrawOrder));
        bool refundSuccess = true;
        if (!executionSuccess) {
            (address pair, , ) = orders.getPairInfo(withdrawOrder.pairId);
            refundSuccess = Orders.refundLiquidity(
                pair,
                withdrawOrder.to,
                withdrawOrder.liquidity,
                this._refundLiquidity.selector
            );
        }
        finalizeOrder(refundSuccess);
        (uint256 gasUsed, uint256 ethRefund) = refund(
            withdrawOrder.gasLimit,
            withdrawOrder.gasPrice,
            gasStart,
            withdrawOrder.to
        );
        emit OrderExecuted(orders.lastProcessedOrderId, executionSuccess, data, gasUsed, ethRefund);
    }

    function executeSell() internal {
        uint256 gasStart = gasleft();
        (Orders.SellOrder memory sellOrder, uint256 amountLimit) = orders.dequeueSellOrder();

        (, address token0, address token1) = orders.getPairInfo(sellOrder.pairId);
        (bool executionSuccess, bytes memory data) = address(this).call{
            gas: sellOrder.gasLimit.sub(
                Orders.ORDER_BASE_COST.add(orders.transferGasCosts[sellOrder.inverse ? token1 : token0])
            )
        }(abi.encodeWithSelector(this._executeSell.selector, sellOrder, amountLimit));
        bool refundSuccess = true;
        if (!executionSuccess) {
            refundSuccess = refundToken(
                sellOrder.inverse ? token1 : token0,
                sellOrder.to,
                sellOrder.shareIn,
                sellOrder.unwrap
            );
        }
        finalizeOrder(refundSuccess);
        (uint256 gasUsed, uint256 ethRefund) = refund(sellOrder.gasLimit, sellOrder.gasPrice, gasStart, sellOrder.to);
        emit OrderExecuted(orders.lastProcessedOrderId, executionSuccess, data, gasUsed, ethRefund);
    }

    function executeBuy() internal {
        uint256 gasStart = gasleft();
        (Orders.BuyOrder memory buyOrder, uint256 amountLimit) = orders.dequeueBuyOrder();
        (, address token0, address token1) = orders.getPairInfo(buyOrder.pairId);
        (bool executionSuccess, bytes memory data) = address(this).call{
            gas: buyOrder.gasLimit.sub(
                Orders.ORDER_BASE_COST.add(orders.transferGasCosts[buyOrder.inverse ? token1 : token0])
            )
        }(abi.encodeWithSelector(this._executeBuy.selector, buyOrder, amountLimit));
        bool refundSuccess = true;
        if (!executionSuccess) {
            refundSuccess = refundToken(
                buyOrder.inverse ? token1 : token0,
                buyOrder.to,
                buyOrder.shareInMax,
                buyOrder.unwrap
            );
        }
        finalizeOrder(refundSuccess);
        (uint256 gasUsed, uint256 ethRefund) = refund(buyOrder.gasLimit, buyOrder.gasPrice, gasStart, buyOrder.to);
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

    function _executeDeposit(
        Orders.DepositOrder calldata depositOrder,
        uint256 amountLimit0,
        uint256 amountLimit1
    ) external payable {
        require(msg.sender == address(this), 'TD00');
        require(depositOrder.validAfterTimestamp + ORDER_LIFESPAN >= block.timestamp, 'TD04');

        (
            Orders.PairInfo memory pairInfo,
            uint256 amount0Left,
            uint256 amount1Left,
            uint256 swapToken
        ) = _initialDeposit(depositOrder, amountLimit0, amountLimit1);
        if (depositOrder.swap && swapToken != 0) {
            bytes memory data = encodePriceInfo(pairInfo.pair, depositOrder.priceAccumulator, depositOrder.timestamp);
            if (amount0Left != 0 && swapToken == 1) {
                uint256 extraAmount1;
                (amount0Left, extraAmount1) = AddLiquidity.swapDeposit0(
                    pairInfo.pair,
                    pairInfo.token0,
                    amount0Left,
                    depositOrder.minSwapPrice,
                    tolerance[pairInfo.pair],
                    data
                );
                amount1Left = amount1Left.add(extraAmount1);
            } else if (amount1Left != 0 && swapToken == 2) {
                uint256 extraAmount0;
                (extraAmount0, amount1Left) = AddLiquidity.swapDeposit1(
                    pairInfo.pair,
                    pairInfo.token1,
                    amount1Left,
                    depositOrder.maxSwapPrice,
                    tolerance[pairInfo.pair],
                    data
                );
                amount0Left = amount0Left.add(extraAmount0);
            }
        }

        if (amount0Left != 0 && amount1Left != 0) {
            (amount0Left, amount1Left, ) = AddLiquidity.addLiquidityAndMint(
                pairInfo.pair,
                depositOrder.to,
                pairInfo.token0,
                pairInfo.token1,
                amount0Left,
                amount1Left
            );
        }

        AddLiquidity._refundDeposit(depositOrder.to, pairInfo.token0, pairInfo.token1, amount0Left, amount1Left);
    }

    function _initialDeposit(
        Orders.DepositOrder calldata depositOrder,
        uint256 amountLimit0,
        uint256 amountLimit1
    )
        private
        returns (
            Orders.PairInfo memory pairInfo,
            uint256 amount0Left,
            uint256 amount1Left,
            uint256 swapToken
        )
    {
        pairInfo = orders.pairs[depositOrder.pairId];
        uint256 amount0Desired = tokenShares.sharesToAmount(
            pairInfo.token0,
            depositOrder.share0,
            amountLimit0,
            depositOrder.to
        );
        uint256 amount1Desired = tokenShares.sharesToAmount(
            pairInfo.token1,
            depositOrder.share1,
            amountLimit1,
            depositOrder.to
        );
        ITwapPair(pairInfo.pair).sync();
        (amount0Left, amount1Left, swapToken) = AddLiquidity.addLiquidityAndMint(
            pairInfo.pair,
            depositOrder.to,
            pairInfo.token0,
            pairInfo.token1,
            amount0Desired,
            amount1Desired
        );
    }

    function _executeWithdraw(Orders.WithdrawOrder calldata withdrawOrder) external payable {
        require(msg.sender == address(this), 'TD00');
        require(withdrawOrder.validAfterTimestamp + ORDER_LIFESPAN >= block.timestamp, 'TD04');
        (address pair, address token0, address token1) = orders.getPairInfo(withdrawOrder.pairId);
        ITwapPair(pair).sync();
        TransferHelper.safeTransfer(pair, pair, withdrawOrder.liquidity);
        uint256 wethAmount;
        uint256 amount0;
        uint256 amount1;
        if (withdrawOrder.unwrap && (token0 == tokenShares.weth || token1 == tokenShares.weth)) {
            bool success;
            (success, wethAmount, amount0, amount1) = WithdrawHelper.withdrawAndUnwrap(
                token0,
                token1,
                pair,
                tokenShares.weth,
                withdrawOrder.to,
                orders.transferGasCosts[address(0)]
            );
            if (!success) {
                tokenShares.onUnwrapFailed(withdrawOrder.to, wethAmount);
            }
        } else {
            (amount0, amount1) = ITwapPair(pair).burn(withdrawOrder.to);
        }
        require(amount0 >= withdrawOrder.amount0Min && amount1 >= withdrawOrder.amount1Min, 'TD03');
    }

    function _executeBuy(Orders.BuyOrder calldata buyOrder, uint256 amountLimit) external payable {
        require(msg.sender == address(this), 'TD00');
        require(buyOrder.validAfterTimestamp + ORDER_LIFESPAN >= block.timestamp, 'TD04');

        (address pairAddress, address tokenIn, address tokenOut) = _getPairAndTokens(buyOrder.pairId, buyOrder.inverse);
        uint256 amountInMax = tokenShares.sharesToAmount(tokenIn, buyOrder.shareInMax, amountLimit, buyOrder.to);
        ITwapPair(pairAddress).sync();
        bytes memory priceInfo = encodePriceInfo(pairAddress, buyOrder.priceAccumulator, buyOrder.timestamp);
        uint256 amountIn;
        uint256 amountOut;
        uint256 reserveOut;
        {
            // scope for reserve out logic, avoids stack too deep errors
            (uint112 reserve0, uint112 reserve1) = ITwapPair(pairAddress).getReserves();
            // subtract 1 to prevent reserve going to 0
            reserveOut = uint256(buyOrder.inverse ? reserve0 : reserve1).sub(1);
        }
        {
            // scope for partial fill logic, avoids stack too deep errors
            address oracle = ITwapPair(pairAddress).oracle();
            uint256 swapFee = ITwapPair(pairAddress).swapFee();
            (amountIn, amountOut) = ITwapOracle(oracle).getSwapAmountInMaxOut(
                buyOrder.inverse,
                swapFee,
                buyOrder.amountOut,
                priceInfo
            );
            uint256 amountInMaxScaled;
            if (amountOut > reserveOut) {
                amountInMaxScaled = amountInMax.mul(reserveOut).ceil_div(buyOrder.amountOut);
                (amountIn, amountOut) = ITwapOracle(oracle).getSwapAmountInMinOut(
                    buyOrder.inverse,
                    swapFee,
                    reserveOut,
                    priceInfo
                );
            } else {
                amountInMaxScaled = amountInMax;
                amountOut = buyOrder.amountOut; // Truncate to desired out
            }
            require(amountInMaxScaled >= amountIn, 'TD08');
            if (amountInMax > amountIn) {
                if (tokenIn == tokenShares.weth && buyOrder.unwrap) {
                    _forceEtherTransfer(buyOrder.to, amountInMax.sub(amountIn));
                } else {
                    TransferHelper.safeTransfer(tokenIn, buyOrder.to, amountInMax.sub(amountIn));
                }
            }
            TransferHelper.safeTransfer(tokenIn, pairAddress, amountIn);
        }
        amountOut = amountOut.sub(tolerance[pairAddress]);
        uint256 amount0Out;
        uint256 amount1Out;
        if (buyOrder.inverse) {
            amount0Out = amountOut;
        } else {
            amount1Out = amountOut;
        }
        if (tokenOut == tokenShares.weth && buyOrder.unwrap) {
            ITwapPair(pairAddress).swap(amount0Out, amount1Out, address(this), priceInfo);
            _forceEtherTransfer(buyOrder.to, amountOut);
        } else {
            ITwapPair(pairAddress).swap(amount0Out, amount1Out, buyOrder.to, priceInfo);
        }
    }

    function _executeSell(Orders.SellOrder calldata sellOrder, uint256 amountLimit) external payable {
        require(msg.sender == address(this), 'TD00');
        require(sellOrder.validAfterTimestamp + ORDER_LIFESPAN >= block.timestamp, 'TD04');

        (address pairAddress, address tokenIn, address tokenOut) = _getPairAndTokens(
            sellOrder.pairId,
            sellOrder.inverse
        );
        ITwapPair(pairAddress).sync();
        bytes memory priceInfo = encodePriceInfo(pairAddress, sellOrder.priceAccumulator, sellOrder.timestamp);

        uint256 amountOut = _executeSellHelper(sellOrder, amountLimit, pairAddress, tokenIn, priceInfo);

        (uint256 amount0Out, uint256 amount1Out) = sellOrder.inverse
            ? (amountOut, uint256(0))
            : (uint256(0), amountOut);
        if (tokenOut == tokenShares.weth && sellOrder.unwrap) {
            ITwapPair(pairAddress).swap(amount0Out, amount1Out, address(this), priceInfo);
            _forceEtherTransfer(sellOrder.to, amountOut);
        } else {
            ITwapPair(pairAddress).swap(amount0Out, amount1Out, sellOrder.to, priceInfo);
        }
    }

    function _executeSellHelper(
        Orders.SellOrder calldata sellOrder,
        uint256 amountLimit,
        address pairAddress,
        address tokenIn,
        bytes memory priceInfo
    ) internal returns (uint256 amountOut) {
        uint256 reserveOut;
        {
            // scope for determining reserve out, avoids stack too deep errors
            (uint112 reserve0, uint112 reserve1) = ITwapPair(pairAddress).getReserves();
            // subtract 1 to prevent reserve going to 0
            reserveOut = uint256(sellOrder.inverse ? reserve0 : reserve1).sub(1);
        }
        {
            // scope for calculations, avoids stack too deep errors
            address oracle = ITwapPair(pairAddress).oracle();
            uint256 swapFee = ITwapPair(pairAddress).swapFee();
            uint256 amountIn = tokenShares.sharesToAmount(tokenIn, sellOrder.shareIn, amountLimit, sellOrder.to);
            amountOut = sellOrder.inverse
                ? ITwapOracle(oracle).getSwapAmount0Out(swapFee, amountIn, priceInfo)
                : ITwapOracle(oracle).getSwapAmount1Out(swapFee, amountIn, priceInfo);

            uint256 amountOutMinScaled;
            if (amountOut > reserveOut) {
                amountOutMinScaled = sellOrder.amountOutMin.mul(reserveOut).div(amountOut);
                uint256 _amountIn = amountIn;
                (amountIn, amountOut) = ITwapOracle(oracle).getSwapAmountInMinOut(
                    sellOrder.inverse,
                    swapFee,
                    reserveOut,
                    priceInfo
                );
                if (tokenIn == tokenShares.weth && sellOrder.unwrap) {
                    _forceEtherTransfer(sellOrder.to, _amountIn.sub(amountIn));
                } else {
                    TransferHelper.safeTransfer(tokenIn, sellOrder.to, _amountIn.sub(amountIn));
                }
            } else {
                amountOutMinScaled = sellOrder.amountOutMin;
            }
            amountOut = amountOut.sub(tolerance[pairAddress]);
            require(amountOut >= amountOutMinScaled, 'TD37');
            TransferHelper.safeTransfer(tokenIn, pairAddress, amountIn);
        }
    }

    function _getPairAndTokens(uint32 pairId, bool pairInversed)
        private
        view
        returns (
            address,
            address,
            address
        )
    {
        (address pairAddress, address token0, address token1) = orders.getPairInfo(pairId);
        (address tokenIn, address tokenOut) = pairInversed ? (token1, token0) : (token0, token1);
        return (pairAddress, tokenIn, tokenOut);
    }

    function _forceEtherTransfer(address to, uint256 amount) internal {
        IWETH(tokenShares.weth).withdraw(amount);
        (bool success, ) = to.call{ value: amount, gas: orders.transferGasCosts[address(0)] }('');
        if (!success) {
            tokenShares.onUnwrapFailed(to, amount);
        }
    }

    function performRefund(
        Orders.OrderType orderType,
        uint256 validAfterTimestamp,
        uint256 orderId,
        bool shouldRefundEth
    ) internal {
        require(orderType != Orders.OrderType.Empty, 'TD41');
        bool canOwnerRefund = validAfterTimestamp.add(365 days) < block.timestamp;

        if (orderType == Orders.OrderType.Deposit) {
            (Orders.DepositOrder memory depositOrder, , ) = orders.getDepositOrder(orderId);
            (, address token0, address token1) = orders.getPairInfo(depositOrder.pairId);
            address to = canOwnerRefund ? owner : depositOrder.to;
            require(
                refundTokens(to, token0, depositOrder.share0, token1, depositOrder.share1, depositOrder.unwrap),
                'TD14'
            );
            if (shouldRefundEth) {
                require(refundEth(payable(to), depositOrder.gasPrice.mul(depositOrder.gasLimit)), 'TD40');
            }
        } else if (orderType == Orders.OrderType.Withdraw) {
            Orders.WithdrawOrder memory withdrawOrder = orders.getWithdrawOrder(orderId);
            (address pair, , ) = orders.getPairInfo(withdrawOrder.pairId);
            address to = canOwnerRefund ? owner : withdrawOrder.to;
            require(Orders.refundLiquidity(pair, to, withdrawOrder.liquidity, this._refundLiquidity.selector), 'TD14');
            if (shouldRefundEth) {
                require(refundEth(payable(to), withdrawOrder.gasPrice.mul(withdrawOrder.gasLimit)), 'TD40');
            }
        } else if (orderType == Orders.OrderType.Sell) {
            (Orders.SellOrder memory sellOrder, ) = orders.getSellOrder(orderId);
            (, address token0, address token1) = orders.getPairInfo(sellOrder.pairId);
            address to = canOwnerRefund ? owner : sellOrder.to;
            require(refundToken(sellOrder.inverse ? token1 : token0, to, sellOrder.shareIn, sellOrder.unwrap), 'TD14');
            if (shouldRefundEth) {
                require(refundEth(payable(to), sellOrder.gasPrice.mul(sellOrder.gasLimit)), 'TD40');
            }
        } else if (orderType == Orders.OrderType.Buy) {
            (Orders.BuyOrder memory buyOrder, ) = orders.getBuyOrder(orderId);
            (, address token0, address token1) = orders.getPairInfo(buyOrder.pairId);
            address to = canOwnerRefund ? owner : buyOrder.to;
            require(refundToken(buyOrder.inverse ? token1 : token0, to, buyOrder.shareInMax, buyOrder.unwrap), 'TD14');
            if (shouldRefundEth) {
                require(refundEth(payable(to), buyOrder.gasPrice.mul(buyOrder.gasLimit)), 'TD40');
            }
        }
        orders.forgetOrder(orderId);
    }

    function retryRefund(uint256 orderId) external override lock {
        (Orders.OrderType orderType, uint256 validAfterTimestamp) = orders.getFailedOrderType(orderId);
        performRefund(orderType, validAfterTimestamp, orderId, false);
    }

    function cancelOrder(uint256 orderId) external override lock {
        require(orders.getOrderStatus(orderId) == Orders.OrderStatus.EnqueuedReady, 'TD52');
        (Orders.OrderType orderType, uint256 validAfterTimestamp) = orders.getOrder(orderId);
        require(validAfterTimestamp.sub(orders.delay).add(ORDER_CANCEL_TIME) < block.timestamp, 'TD1C');
        orders.canceled[orderId] = true;
        performRefund(orderType, validAfterTimestamp, orderId, true);
    }

    function encodePriceInfo(
        address pair,
        uint256 priceAccumulator,
        uint32 priceTimestamp
    ) internal view returns (bytes memory data) {
        uint256 price = ITwapOracle(ITwapPair(pair).oracle()).getAveragePrice(priceAccumulator, priceTimestamp);
        // Pack everything as 32 bytes / uint256 to simplify decoding
        data = abi.encode(price);
    }

    receive() external payable {}
}