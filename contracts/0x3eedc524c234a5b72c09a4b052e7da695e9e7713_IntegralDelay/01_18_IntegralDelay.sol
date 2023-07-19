// SPDX-License-Identifier: GPL-3.0-or-later
// Deployed with donations via Gitcoin GR9

pragma solidity 0.7.5;
pragma experimental ABIEncoderV2;

import 'IIntegralPair.sol';
import 'IIntegralDelay.sol';
import 'IIntegralOracle.sol';
import 'IWETH.sol';
import 'SafeMath.sol';
import 'Normalizer.sol';
import 'Orders.sol';
import 'TokenShares.sol';
import 'AddLiquidity.sol';
import 'BuyHelper.sol';
import 'WithdrawHelper.sol';

contract IntegralDelay is IIntegralDelay {
    using SafeMath for uint256;
    using Normalizer for uint256;
    using Orders for Orders.Data;
    using TokenShares for TokenShares.Data;
    Orders.Data internal orders;
    TokenShares.Data internal tokenShares;

    uint256 public constant ORDER_CANCEL_TIME = 24 hours;
    uint256 private constant ORDER_EXECUTED_COST = 3700;

    address public override owner;
    mapping(address => bool) public override isBot;
    uint256 public override botExecuteTime;

    constructor(
        address _factory,
        address _weth,
        address _bot
    ) {
        orders.factory = _factory;
        owner = msg.sender;
        isBot[_bot] = true;
        orders.gasPrice = tx.gasprice - (tx.gasprice % 1e6);
        tokenShares.setWeth(_weth);
        orders.delay = 5 minutes;
        botExecuteTime = 4 * orders.delay;
        orders.maxGasLimit = 5000000;
        orders.gasPriceInertia = 20000000;
        orders.maxGasPriceImpact = 1000000;
    }

    function getTransferGasCost(address token) public view override returns (uint256 gasCost) {
        return orders.transferGasCosts[token];
    }

    function getDepositOrder(uint256 orderId) public view override returns (Orders.DepositOrder memory order) {
        return orders.getDepositOrder(orderId);
    }

    function getWithdrawOrder(uint256 orderId) public view override returns (Orders.WithdrawOrder memory order) {
        return orders.getWithdrawOrder(orderId);
    }

    function getSellOrder(uint256 orderId) public view override returns (Orders.SellOrder memory order) {
        return orders.getSellOrder(orderId);
    }

    function getBuyOrder(uint256 orderId) public view override returns (Orders.BuyOrder memory order) {
        return orders.getBuyOrder(orderId);
    }

    function getDepositDisabled(address pair) public view override returns (bool) {
        return orders.depositDisabled[pair];
    }

    function getWithdrawDisabled(address pair) public view override returns (bool) {
        return orders.withdrawDisabled[pair];
    }

    function getBuyDisabled(address pair) public view override returns (bool) {
        return orders.buyDisabled[pair];
    }

    function getSellDisabled(address pair) public view override returns (bool) {
        return orders.sellDisabled[pair];
    }

    function getOrderStatus(uint256 orderId) public view override returns (Orders.OrderStatus) {
        return orders.getOrderStatus(orderId);
    }

    uint256 private unlocked = 1;
    modifier lock() {
        require(unlocked == 1, 'ID_LOCKED');
        unlocked = 0;
        _;
        unlocked = 1;
    }

    function factory() public view override returns (address) {
        return orders.factory;
    }

    function totalShares(address token) public view override returns (uint256) {
        return tokenShares.totalShares[token];
    }

    function weth() public view override returns (address) {
        return tokenShares.weth;
    }

    function delay() public view override returns (uint256) {
        return orders.delay;
    }

    function lastProcessedOrderId() public view returns (uint256) {
        return orders.lastProcessedOrderId;
    }

    function newestOrderId() public view returns (uint256) {
        return orders.newestOrderId;
    }

    function getOrder(uint256 orderId) public view returns (Orders.OrderType orderType, uint256 validAfterTimestamp) {
        return orders.getOrder(orderId);
    }

    function isOrderCanceled(uint256 orderId) public view returns (bool) {
        return orders.canceled[orderId];
    }

    function maxGasLimit() public view override returns (uint256) {
        return orders.maxGasLimit;
    }

    function maxGasPriceImpact() public view override returns (uint256) {
        return orders.maxGasPriceImpact;
    }

    function gasPriceInertia() public view override returns (uint256) {
        return orders.gasPriceInertia;
    }

    function gasPrice() public view override returns (uint256) {
        return orders.gasPrice;
    }

    function setOrderDisabled(
        address pair,
        Orders.OrderType orderType,
        bool disabled
    ) public override {
        require(msg.sender == owner, 'ID_FORBIDDEN');
        require(orderType != Orders.OrderType.Empty, 'ID_INVALID_ORDER_TYPE');
        if (orderType == Orders.OrderType.Deposit) {
            orders.depositDisabled[pair] = disabled;
        } else if (orderType == Orders.OrderType.Withdraw) {
            orders.withdrawDisabled[pair] = disabled;
        } else if (orderType == Orders.OrderType.Sell) {
            orders.sellDisabled[pair] = disabled;
        } else if (orderType == Orders.OrderType.Buy) {
            orders.buyDisabled[pair] = disabled;
        }
        emit OrderDisabled(pair, orderType, disabled);
    }

    function setOwner(address _owner) public override {
        require(msg.sender == owner, 'ID_FORBIDDEN');
        owner = _owner;
        emit OwnerSet(owner);
    }

    function setBot(address _bot, bool _isBot) public override {
        require(msg.sender == owner, 'ID_FORBIDDEN');
        isBot[_bot] = _isBot;
        emit BotSet(_bot, _isBot);
    }

    function setMaxGasLimit(uint256 _maxGasLimit) public override {
        require(msg.sender == owner, 'ID_FORBIDDEN');
        orders.setMaxGasLimit(_maxGasLimit);
    }

    function setDelay(uint256 _delay) public override {
        require(msg.sender == owner, 'ID_FORBIDDEN');
        orders.delay = _delay;
        botExecuteTime = 4 * _delay;
        emit DelaySet(_delay);
    }

    function setGasPriceInertia(uint256 _gasPriceInertia) public override {
        require(msg.sender == owner, 'ID_FORBIDDEN');
        orders.setGasPriceInertia(_gasPriceInertia);
    }

    function setMaxGasPriceImpact(uint256 _maxGasPriceImpact) public override {
        require(msg.sender == owner, 'ID_FORBIDDEN');
        orders.setMaxGasPriceImpact(_maxGasPriceImpact);
    }

    function setTransferGasCost(address token, uint256 gasCost) public override {
        require(msg.sender == owner, 'ID_FORBIDDEN');
        orders.setTransferGasCost(token, gasCost);
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

    function execute(uint256 n) public override lock {
        emit Execute(msg.sender, n);
        uint256 gasBefore = gasleft();
        bool orderExecuted = false;
        for (uint256 i = 0; i < n; i++) {
            if (isOrderCanceled(orders.lastProcessedOrderId + 1)) {
                orders.dequeueCanceledOrder();
                continue;
            }
            (Orders.OrderType orderType, uint256 validAfterTimestamp) = orders.getNextOrder();
            if (orderType == Orders.OrderType.Empty || validAfterTimestamp >= block.timestamp) {
                break;
            }
            require(
                block.timestamp >= validAfterTimestamp + botExecuteTime || isBot[msg.sender] || isBot[address(0)],
                'ID_FORBIDDEN'
            );
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
        Orders.DepositOrder memory depositOrder = orders.dequeueDepositOrder();
        (, address token0, address token1) = orders.getPairInfo(depositOrder.pairId);
        (bool executionSuccess, bytes memory data) = address(this).call{
            gas: depositOrder.gasLimit.sub(
                Orders.ORDER_BASE_COST.add(orders.transferGasCosts[token0]).add(orders.transferGasCosts[token1])
            )
        }(abi.encodeWithSelector(this._executeDeposit.selector, depositOrder));
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
        if (!refundSuccess) {
            orders.markRefundFailed();
        } else {
            orders.forgetLastProcessedOrder();
        }
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
        (address pair, , ) = orders.getPairInfo(withdrawOrder.pairId);
        (bool executionSuccess, bytes memory data) = address(this).call{
            gas: withdrawOrder.gasLimit.sub(Orders.ORDER_BASE_COST.add(Orders.PAIR_TRANSFER_COST))
        }(abi.encodeWithSelector(this._executeWithdraw.selector, withdrawOrder));
        bool refundSuccess = true;
        if (!executionSuccess) {
            refundSuccess = refundLiquidity(pair, withdrawOrder.to, withdrawOrder.liquidity);
        }
        if (!refundSuccess) {
            orders.markRefundFailed();
        } else {
            orders.forgetLastProcessedOrder();
        }
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
        Orders.SellOrder memory sellOrder = orders.dequeueSellOrder();
        (, address token0, address token1) = orders.getPairInfo(sellOrder.pairId);
        (bool executionSuccess, bytes memory data) = address(this).call{
            gas: sellOrder.gasLimit.sub(
                Orders.ORDER_BASE_COST.add(orders.transferGasCosts[sellOrder.inverse ? token1 : token0])
            )
        }(abi.encodeWithSelector(this._executeSell.selector, sellOrder));
        bool refundSuccess = true;
        if (!executionSuccess) {
            refundSuccess = refundToken(
                sellOrder.inverse ? token1 : token0,
                sellOrder.to,
                sellOrder.shareIn,
                sellOrder.unwrap
            );
        }
        if (!refundSuccess) {
            orders.markRefundFailed();
        } else {
            orders.forgetLastProcessedOrder();
        }
        (uint256 gasUsed, uint256 ethRefund) = refund(sellOrder.gasLimit, sellOrder.gasPrice, gasStart, sellOrder.to);
        emit OrderExecuted(orders.lastProcessedOrderId, executionSuccess, data, gasUsed, ethRefund);
    }

    function executeBuy() internal {
        uint256 gasStart = gasleft();
        Orders.BuyOrder memory buyOrder = orders.dequeueBuyOrder();
        (, address token0, address token1) = orders.getPairInfo(buyOrder.pairId);
        (bool executionSuccess, bytes memory data) = address(this).call{
            gas: buyOrder.gasLimit.sub(
                Orders.ORDER_BASE_COST.add(orders.transferGasCosts[buyOrder.inverse ? token1 : token0])
            )
        }(abi.encodeWithSelector(this._executeBuy.selector, buyOrder));
        bool refundSuccess = true;
        if (!executionSuccess) {
            refundSuccess = refundToken(
                buyOrder.inverse ? token1 : token0,
                buyOrder.to,
                buyOrder.shareInMax,
                buyOrder.unwrap
            );
        }
        if (!refundSuccess) {
            orders.markRefundFailed();
        } else {
            orders.forgetLastProcessedOrder();
        }
        (uint256 gasUsed, uint256 ethRefund) = refund(buyOrder.gasLimit, buyOrder.gasPrice, gasStart, buyOrder.to);
        emit OrderExecuted(orders.lastProcessedOrderId, executionSuccess, data, gasUsed, ethRefund);
    }

    function refund(
        uint256 gasLimit,
        uint256 gasPriceInOrder,
        uint256 gasStart,
        address to
    ) private returns (uint256 gasUsed, uint256 leftOver) {
        uint256 feeCollected = gasLimit.mul(gasPriceInOrder);
        gasUsed = gasStart.sub(gasleft()).add(Orders.REFUND_END_COST).add(ORDER_EXECUTED_COST);
        uint256 actualRefund = Math.min(feeCollected, gasUsed.mul(orders.gasPrice));
        leftOver = feeCollected.sub(actualRefund);
        require(refundEth(msg.sender, actualRefund), 'ID_ETH_REFUND_FAILED');
        refundEth(payable(to), leftOver);
    }

    function refundEth(address payable to, uint256 value) internal returns (bool success) {
        if (value == 0) {
            return true;
        }
        success = to.send(value);
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
    ) external {
        // no need to check sender, because it is checked in _refundToken
        _refundToken(token0, to, share0, unwrap);
        _refundToken(token1, to, share1, unwrap);
    }

    function _refundToken(
        address token,
        address to,
        uint256 share,
        bool unwrap
    ) public {
        require(msg.sender == address(this), 'ID_FORBIDDEN');
        if (token == tokenShares.weth && unwrap) {
            uint256 amount = tokenShares.sharesToAmount(token, share);
            IWETH(tokenShares.weth).withdraw(amount);
            payable(to).transfer(amount);
        } else {
            return TransferHelper.safeTransfer(token, to, tokenShares.sharesToAmount(token, share));
        }
    }

    function refundLiquidity(
        address pair,
        address to,
        uint256 liquidity
    ) private returns (bool) {
        if (liquidity == 0) {
            return true;
        }
        (bool success, bytes memory data) = address(this).call{ gas: Orders.PAIR_TRANSFER_COST }(
            abi.encodeWithSelector(this._refundLiquidity.selector, pair, to, liquidity, false)
        );
        if (!success) {
            emit RefundFailed(to, pair, liquidity, data);
        }
        return success;
    }

    function _refundLiquidity(
        address pair,
        address to,
        uint256 liquidity
    ) public {
        require(msg.sender == address(this), 'ID_FORBIDDEN');
        return TransferHelper.safeTransfer(pair, to, liquidity);
    }

    function _executeDeposit(Orders.DepositOrder memory depositOrder) public {
        require(msg.sender == address(this), 'ID_FORBIDDEN');
        require(depositOrder.deadline >= block.timestamp, 'ID_EXPIRED');

        (address pair, address token0, address token1, uint256 amount0Left, uint256 amount1Left) = _initialDeposit(
            depositOrder
        );
        if (
            (amount0Left != 0 || amount1Left != 0) &&
            AddLiquidity.canSwap(
                depositOrder.initialRatio,
                depositOrder.minRatioChangeToSwap,
                orders.pairs[depositOrder.pairId].pair
            )
        ) {
            if (amount0Left != 0) {
                (amount0Left, amount1Left) = AddLiquidity.swapDeposit0(
                    pair,
                    token0,
                    amount0Left,
                    depositOrder.minSwapPrice
                );
            } else if (amount1Left != 0) {
                (amount0Left, amount1Left) = AddLiquidity.swapDeposit1(
                    pair,
                    token1,
                    amount1Left,
                    depositOrder.maxSwapPrice
                );
            }
        }
        if (amount0Left != 0 && amount1Left != 0) {
            (amount0Left, amount1Left) = _addLiquidityAndMint(
                pair,
                depositOrder.to,
                token0,
                token1,
                amount0Left,
                amount1Left
            );
        }

        _refundDeposit(depositOrder.to, token0, token1, amount0Left, amount1Left);
    }

    function _initialDeposit(Orders.DepositOrder memory depositOrder)
        private
        returns (
            address pair,
            address token0,
            address token1,
            uint256 amount0Left,
            uint256 amount1Left
        )
    {
        (pair, token0, token1) = orders.getPairInfo(depositOrder.pairId);
        uint256 amount0Desired = tokenShares.sharesToAmount(token0, depositOrder.share0);
        uint256 amount1Desired = tokenShares.sharesToAmount(token1, depositOrder.share1);
        IIntegralPair(pair).fullSync();
        (amount0Left, amount1Left) = _addLiquidityAndMint(
            pair,
            depositOrder.to,
            token0,
            token1,
            amount0Desired,
            amount1Desired
        );
    }

    function _addLiquidityAndMint(
        address pair,
        address to,
        address token0,
        address token1,
        uint256 amount0Desired,
        uint256 amount1Desired
    ) private returns (uint256 amount0Left, uint256 amount1Left) {
        (uint256 amount0, uint256 amount1) = AddLiquidity.addLiquidity(pair, amount0Desired, amount1Desired);
        if (amount0 == 0 || amount1 == 0) {
            return (amount0Desired, amount1Desired);
        }
        TransferHelper.safeTransfer(token0, pair, amount0);
        TransferHelper.safeTransfer(token1, pair, amount1);
        IIntegralPair(pair).mint(to);

        amount0Left = amount0Desired.sub(amount0);
        amount1Left = amount1Desired.sub(amount1);
    }

    function _refundDeposit(
        address to,
        address token0,
        address token1,
        uint256 amount0,
        uint256 amount1
    ) private {
        if (amount0 > 0) {
            TransferHelper.safeTransfer(token0, to, amount0);
        }
        if (amount1 > 0) {
            TransferHelper.safeTransfer(token1, to, amount1);
        }
    }

    function _executeWithdraw(Orders.WithdrawOrder memory withdrawOrder) public {
        require(msg.sender == address(this), 'ID_FORBIDDEN');
        require(withdrawOrder.deadline >= block.timestamp, 'ID_EXPIRED');

        (address pair, address token0, address token1) = orders.getPairInfo(withdrawOrder.pairId);
        IIntegralPair(pair).fullSync();
        TransferHelper.safeTransfer(pair, pair, withdrawOrder.liquidity);

        (uint256 wethAmount, uint256 amount0, uint256 amount1) = (0, 0, 0);
        if (withdrawOrder.unwrap && (token0 == tokenShares.weth || token1 == tokenShares.weth)) {
            bool success;
            (success, wethAmount, amount0, amount1) = WithdrawHelper.withdrawAndUnwrap(
                token0,
                token1,
                pair,
                tokenShares.weth,
                withdrawOrder.to
            );
            if (!success) {
                tokenShares.onUnwrapFailed(withdrawOrder.to, wethAmount);
            }
        } else {
            (amount0, amount1) = IIntegralPair(pair).burn(withdrawOrder.to);
        }
        require(amount0 >= withdrawOrder.amount0Min && amount1 >= withdrawOrder.amount1Min, 'ID_INSUFFICIENT_AMOUNT');
    }

    function _executeBuy(Orders.BuyOrder memory buyOrder) public {
        require(msg.sender == address(this), 'ID_FORBIDDEN');
        require(buyOrder.deadline >= block.timestamp, 'ID_EXPIRED');

        (address pairAddress, address token0, address token1) = orders.getPairInfo(buyOrder.pairId);
        (address tokenIn, address tokenOut) = buyOrder.inverse ? (token1, token0) : (token0, token1);
        uint256 amountInMax = tokenShares.sharesToAmount(tokenIn, buyOrder.shareInMax);
        IIntegralPair pair = IIntegralPair(pairAddress);
        pair.fullSync();
        uint256 amountIn = buyOrder.inverse
            ? BuyHelper.getSwapAmount1In(pairAddress, buyOrder.amountOut)
            : BuyHelper.getSwapAmount0In(pairAddress, buyOrder.amountOut);
        require(amountInMax >= amountIn, 'ID_INSUFFICIENT_INPUT_AMOUNT');
        (uint256 amount0Out, uint256 amount1Out) = buyOrder.inverse
            ? (buyOrder.amountOut, uint256(0))
            : (uint256(0), buyOrder.amountOut);
        TransferHelper.safeTransfer(tokenIn, pairAddress, amountIn);
        if (tokenOut == tokenShares.weth && buyOrder.unwrap) {
            pair.swap(amount0Out, amount1Out, address(this));
            IWETH(tokenShares.weth).withdraw(buyOrder.amountOut);
            (bool success, ) = buyOrder.to.call{ value: buyOrder.amountOut, gas: Orders.ETHER_TRANSFER_CALL_COST }('');
            if (!success) {
                tokenShares.onUnwrapFailed(buyOrder.to, buyOrder.amountOut);
            }
        } else {
            pair.swap(amount0Out, amount1Out, buyOrder.to);
        }
    }

    function _executeSell(Orders.SellOrder memory sellOrder) public {
        require(msg.sender == address(this), 'ID_FORBIDDEN');
        require(sellOrder.deadline >= block.timestamp, 'ID_EXPIRED');

        (address pairAddress, address token0, address token1) = orders.getPairInfo(sellOrder.pairId);
        (address tokenIn, address tokenOut) = sellOrder.inverse ? (token1, token0) : (token0, token1);
        uint256 amountIn = tokenShares.sharesToAmount(tokenIn, sellOrder.shareIn);
        IIntegralPair pair = IIntegralPair(pairAddress);
        pair.fullSync();
        TransferHelper.safeTransfer(tokenIn, pairAddress, amountIn);
        uint256 amountOut = sellOrder.inverse ? pair.getSwapAmount0Out(amountIn) : pair.getSwapAmount1Out(amountIn);
        require(amountOut >= sellOrder.amountOutMin, 'ID_INSUFFICIENT_OUTPUT_AMOUNT');
        (uint256 amount0Out, uint256 amount1Out) = sellOrder.inverse
            ? (amountOut, uint256(0))
            : (uint256(0), amountOut);
        if (tokenOut == tokenShares.weth && sellOrder.unwrap) {
            pair.swap(amount0Out, amount1Out, address(this));
            IWETH(tokenShares.weth).withdraw(amountOut);
            (bool success, ) = sellOrder.to.call{ value: amountOut, gas: Orders.ETHER_TRANSFER_CALL_COST }('');
            if (!success) {
                tokenShares.onUnwrapFailed(sellOrder.to, amountOut);
            }
        } else {
            pair.swap(amount0Out, amount1Out, sellOrder.to);
        }
    }

    function performRefund(
        Orders.OrderType orderType,
        uint256 validAfterTimestamp,
        uint256 orderId,
        bool shouldRefundEth
    ) internal {
        bool canOwnerRefund = validAfterTimestamp.add(365 days) < block.timestamp;
        if (orderType == Orders.OrderType.Deposit) {
            Orders.DepositOrder memory depositOrder = orders.getDepositOrder(orderId);
            (, address token0, address token1) = orders.getPairInfo(depositOrder.pairId);
            address to = canOwnerRefund ? owner : depositOrder.to;
            require(
                refundTokens(to, token0, depositOrder.share0, token1, depositOrder.share1, depositOrder.unwrap),
                'ID_REFUND_FAILED'
            );
            if (shouldRefundEth) {
                uint256 value = depositOrder.gasPrice.mul(depositOrder.gasLimit);
                require(refundEth(payable(to), value), 'ID_ETH_REFUND_FAILED');
            }
        } else if (orderType == Orders.OrderType.Withdraw) {
            Orders.WithdrawOrder memory withdrawOrder = orders.getWithdrawOrder(orderId);
            (address pair, , ) = orders.getPairInfo(withdrawOrder.pairId);
            address to = canOwnerRefund ? owner : withdrawOrder.to;
            require(refundLiquidity(pair, to, withdrawOrder.liquidity), 'ID_REFUND_FAILED');
            if (shouldRefundEth) {
                uint256 value = withdrawOrder.gasPrice.mul(withdrawOrder.gasLimit);
                require(refundEth(payable(to), value), 'ID_ETH_REFUND_FAILED');
            }
        } else if (orderType == Orders.OrderType.Sell) {
            Orders.SellOrder memory sellOrder = orders.getSellOrder(orderId);
            (, address token0, address token1) = orders.getPairInfo(sellOrder.pairId);
            address to = canOwnerRefund ? owner : sellOrder.to;
            require(
                refundToken(sellOrder.inverse ? token1 : token0, to, sellOrder.shareIn, sellOrder.unwrap),
                'ID_REFUND_FAILED'
            );
            if (shouldRefundEth) {
                uint256 value = sellOrder.gasPrice.mul(sellOrder.gasLimit);
                require(refundEth(payable(to), value), 'ID_ETH_REFUND_FAILED');
            }
        } else if (orderType == Orders.OrderType.Buy) {
            Orders.BuyOrder memory buyOrder = orders.getBuyOrder(orderId);
            (, address token0, address token1) = orders.getPairInfo(buyOrder.pairId);
            address to = canOwnerRefund ? owner : buyOrder.to;
            require(
                refundToken(buyOrder.inverse ? token1 : token0, to, buyOrder.shareInMax, buyOrder.unwrap),
                'ID_REFUND_FAILED'
            );
            if (shouldRefundEth) {
                uint256 value = buyOrder.gasPrice.mul(buyOrder.gasLimit);
                require(refundEth(payable(to), value), 'ID_ETH_REFUND_FAILED');
            }
        }
        orders.forgetOrder(orderId);
    }

    function retryRefund(uint256 orderId) public lock {
        (Orders.OrderType orderType, uint256 validAfterTimestamp) = orders.getFailedOrderType(orderId);
        performRefund(orderType, validAfterTimestamp, orderId, false);
    }

    function cancelOrder(uint256 orderId) public lock {
        (Orders.OrderType orderType, uint256 validAfterTimestamp) = orders.getOrder(orderId);
        require(validAfterTimestamp.sub(delay()).add(ORDER_CANCEL_TIME) < block.timestamp, 'ID_ORDER_NOT_EXCEEDED');
        performRefund(orderType, validAfterTimestamp, orderId, true);
        orders.canceled[orderId] = true;
    }

    receive() external payable {}
}