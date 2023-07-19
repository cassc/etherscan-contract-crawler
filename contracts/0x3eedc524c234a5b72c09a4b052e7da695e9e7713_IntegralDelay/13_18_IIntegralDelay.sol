// SPDX-License-Identifier: GPL-3.0-or-later
// Deployed with donations via Gitcoin GR9

pragma solidity 0.7.5;
pragma experimental ABIEncoderV2;

import 'Orders.sol';

interface IIntegralDelay {
    event OrderExecuted(uint256 indexed id, bool indexed success, bytes data, uint256 gasSpent, uint256 ethRefunded);
    event RefundFailed(address indexed to, address indexed token, uint256 amount, bytes data);
    event EthRefund(address indexed to, bool indexed success, uint256 value);
    event OwnerSet(address owner);
    event BotSet(address bot, bool isBot);
    event DelaySet(uint256 delay);
    event MaxGasLimitSet(uint256 maxGasLimit);
    event GasPriceInertiaSet(uint256 gasPriceInertia);
    event MaxGasPriceImpactSet(uint256 maxGasPriceImpact);
    event TransferGasCostSet(address token, uint256 gasCost);
    event OrderDisabled(address pair, Orders.OrderType orderType, bool disabled);
    event UnwrapFailed(address to, uint256 amount);
    event Execute(address sender, uint256 n);

    function factory() external returns (address);

    function owner() external returns (address);

    function isBot(address bot) external returns (bool);

    function botExecuteTime() external returns (uint256);

    function gasPriceInertia() external returns (uint256);

    function gasPrice() external returns (uint256);

    function maxGasPriceImpact() external returns (uint256);

    function maxGasLimit() external returns (uint256);

    function delay() external returns (uint256);

    function totalShares(address token) external returns (uint256);

    function weth() external returns (address);

    function getTransferGasCost(address token) external returns (uint256);

    function getDepositOrder(uint256 orderId) external returns (Orders.DepositOrder memory order);

    function getWithdrawOrder(uint256 orderId) external returns (Orders.WithdrawOrder memory order);

    function getSellOrder(uint256 orderId) external returns (Orders.SellOrder memory order);

    function getBuyOrder(uint256 orderId) external returns (Orders.BuyOrder memory order);

    function getDepositDisabled(address pair) external returns (bool);

    function getWithdrawDisabled(address pair) external returns (bool);

    function getBuyDisabled(address pair) external returns (bool);

    function getSellDisabled(address pair) external returns (bool);

    function getOrderStatus(uint256 orderId) external returns (Orders.OrderStatus);

    function setOrderDisabled(
        address pair,
        Orders.OrderType orderType,
        bool disabled
    ) external;

    function setOwner(address _owner) external;

    function setBot(address _bot, bool _isBot) external;

    function setMaxGasLimit(uint256 _maxGasLimit) external;

    function setDelay(uint256 _delay) external;

    function setGasPriceInertia(uint256 _gasPriceInertia) external;

    function setMaxGasPriceImpact(uint256 _maxGasPriceImpact) external;

    function setTransferGasCost(address token, uint256 gasCost) external;

    function deposit(Orders.DepositParams memory depositParams) external payable returns (uint256 orderId);

    function withdraw(Orders.WithdrawParams memory withdrawParams) external payable returns (uint256 orderId);

    function sell(Orders.SellParams memory sellParams) external payable returns (uint256 orderId);

    function buy(Orders.BuyParams memory buyParams) external payable returns (uint256 orderId);

    function execute(uint256 n) external;
}