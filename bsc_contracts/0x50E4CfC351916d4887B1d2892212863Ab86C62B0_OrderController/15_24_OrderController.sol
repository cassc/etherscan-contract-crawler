// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.18;

import { IERC20 } from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import { ITranchePool } from "./interfaces/ITranchePool.sol";
import { IOrderController, OrderType, Order } from "./interfaces/IOrderController.sol";
import { Base } from "./Base.sol";
import { IProtocolConfig } from "./interfaces/IProtocolConfig.sol";
import { IPortfolio, Status } from "./interfaces/IPortfolio.sol";

/// @title OrderController
/// @notice The OrderController is for handling deposit and withdrawal orders.
contract OrderController is IOrderController, Base {
    IPortfolio public portfolio;
    IERC20 public token;
    ITranchePool public tranche;
    uint256 public dust;

    uint256 public constant NULL = 0;
    uint256 public constant HEAD = 0;

    uint256 internal nextOrderId = 1;
    mapping(uint256 => Order) internal orders;

    constructor(
        ITranchePool tranche_,
        IProtocolConfig protocolConfig_,
        IPortfolio portfolio_,
        uint256 dust_,
        address manager_
    )
        Base(protocolConfig_.protocolAdmin(), protocolConfig_.pauser())
    {
        _grantManagerRole(manager_);
        _setToken(IERC20(tranche_.asset()));
        _setTranche(tranche_);
        _setPortfolio(portfolio_);
        _setDust(dust_);
    }

    /// @inheritdoc IOrderController
    function deposit(uint256 tokenAmount, uint256 iterationLimit) external whenNotPaused {
        _validateInputs(msg.sender, tokenAmount, OrderType.DEPOSIT);

        _cancelOrder(msg.sender);

        (uint256 remainingTokenAmount, uint256 iterations) = _processWithdrawOrder(tokenAmount, iterationLimit);

        if (iterations == iterationLimit) return;

        // double check for the case when dust = 0
        if (remainingTokenAmount > 0 && remainingTokenAmount >= dust) {
            _createOrder(msg.sender, remainingTokenAmount, OrderType.DEPOSIT);
        }
    }

    /// @inheritdoc IOrderController
    function withdraw(uint256 trancheAmount, uint256 iterationLimit) external whenNotPaused {
        _validateInputs(msg.sender, trancheAmount, OrderType.WITHDRAW);

        _cancelOrder(msg.sender);

        (uint256 remainingTrancheAmount, uint256 iterations) = _processDepositOrder(trancheAmount, iterationLimit);

        if (iterations == iterationLimit) return;

        // double check for the case when dust = 0
        if (remainingTrancheAmount > 0 && remainingTrancheAmount >= dust) {
            _createOrder(msg.sender, remainingTrancheAmount, OrderType.WITHDRAW);
        }
    }

    /// @inheritdoc IOrderController
    function cancelOrder() external {
        _cancelOrder(msg.sender);
    }

    /// @inheritdoc IOrderController
    function cancelDustOrder(uint256 orderId) external {
        Order storage order = orders[orderId];

        if (order.user == address(0)) {
            revert InvalidOrderId();
        }

        if (order.amount >= dust) {
            revert InvalidAmount();
        }

        _removeOrder(orderId);
    }

    function setDust(uint256 _dust) external {
        _requireManagerRole();
        _setDust(_dust);
    }

    /// @inheritdoc IOrderController
    function expectedTokenAmount(uint256 trancheAmount) public view virtual returns (uint256) {
        return tranche.convertToAssets(trancheAmount);
    }

    /// @inheritdoc IOrderController
    function expectedTrancheAmount(uint256 tokenAmount) public view virtual returns (uint256) {
        return tranche.convertToShares(tokenAmount);
    }

    function expectedTokenAmountCeil(uint256 trancheAmount) internal view virtual returns (uint256) {
        return tranche.convertToAssetsCeil(trancheAmount);
    }

    function expectedTrancheAmountCeil(uint256 tokenAmount) internal view virtual returns (uint256) {
        return tranche.convertToSharesCeil(tokenAmount);
    }

    /// @inheritdoc IOrderController
    function getUserOrder(address user) public view returns (Order memory) {
        if (_isStatus(Status.SeniorClosed) || _isStatus(Status.EquityClosed)) {
            return Order(0, 0, 0, 0, 0, address(0), OrderType.NONE);
        }

        uint256 currentOrderId = orders[HEAD].next;
        Order memory order = Order(0, 0, 0, 0, 0, address(0), OrderType.NONE);

        while (currentOrderId != NULL) {
            order = orders[currentOrderId];

            if (order.user == user) {
                return order;
            }

            currentOrderId = order.next;
        }

        // No order matched
        return Order(0, 0, 0, 0, 0, address(0), OrderType.NONE);
    }

    /// @inheritdoc IOrderController
    function getOrders() public view returns (Order[] memory) {
        if (_isStatus(Status.SeniorClosed) || _isStatus(Status.EquityClosed)) return new Order[](0);

        uint256 orderCount = getOrderCount();
        Order[] memory ordersArray = new Order[](orderCount);
        uint256 currentIndex = 0;
        uint256 currentOrderId = orders[HEAD].next;

        while (currentOrderId != NULL) {
            Order storage currentOrder = orders[currentOrderId];
            ordersArray[currentIndex] = currentOrder;
            currentOrderId = currentOrder.next;
            currentIndex++;
        }

        return ordersArray;
    }

    /// @inheritdoc IOrderController
    function getValidOrders() public view returns (Order[] memory, OrderType) {
        if (_isStatus(Status.SeniorClosed) || _isStatus(Status.EquityClosed)) return (new Order[](0), OrderType.NONE);

        (uint256 orderCount, OrderType orderType) = getValidOrderCount();
        Order[] memory ordersArray = new Order[](orderCount);
        uint256 currentIndex = 0;
        uint256 currentOrderId = orders[HEAD].next;

        while (currentOrderId != NULL) {
            Order storage currentOrder = orders[currentOrderId];

            if (_validateOrder(currentOrder, orderType)) {
                ordersArray[currentIndex] = currentOrder;
                currentIndex++;
            }

            currentOrderId = currentOrder.next;
        }

        return (ordersArray, orderType);
    }

    /// @inheritdoc IOrderController
    function getOrderCount() public view returns (uint256) {
        if (_isStatus(Status.SeniorClosed) || _isStatus(Status.EquityClosed)) return 0;

        uint256 count = 0;
        uint256 currentOrderId = orders[HEAD].next;

        while (currentOrderId != NULL) {
            count++;
            currentOrderId = orders[currentOrderId].next;
        }

        return count;
    }

    /// @inheritdoc IOrderController
    function getValidOrderCount() public view returns (uint256 count, OrderType orderType) {
        if (_isStatus(Status.SeniorClosed) || _isStatus(Status.EquityClosed)) return (0, OrderType.NONE);

        orderType = currentOrderType();
        uint256 currentOrderId = orders[HEAD].next;

        while (currentOrderId != NULL) {
            if (_validateOrder(orders[currentOrderId], orderType)) count++;
            currentOrderId = orders[currentOrderId].next;
        }

        return (count, orderType);
    }

    /// @inheritdoc IOrderController
    function currentOrderType() public view returns (OrderType) {
        uint256 currentOrderId = orders[HEAD].next;

        if (currentOrderId != NULL) {
            return orders[currentOrderId].orderType;
        } else {
            return OrderType.NONE;
        }
    }

    function _processWithdrawOrder(uint256 tokenAmount, uint256 iterationLimit) internal returns (uint256, uint256) {
        uint256 currentId = orders[HEAD].next;
        uint256 iterations = 0;

        while (currentId != NULL && tokenAmount > 0 && iterations < iterationLimit) {
            Order memory order = orders[currentId];

            if (order.orderType == OrderType.WITHDRAW) {
                if (_validateOrder(order, OrderType.WITHDRAW)) {
                    // round up to calculate the token amount for msg.sender to pay
                    uint256 orderTokenAmount = expectedTokenAmountCeil(order.amount);
                    if (orderTokenAmount <= tokenAmount) {
                        tokenAmount -= orderTokenAmount;
                        _executeWithdrawOrder(orderTokenAmount, order.amount, order.user);
                        _removeOrder(currentId);
                        currentId = order.next;
                    } else {
                        // round down to calculate the tranche amount for msg.sender to receive
                        uint256 trancheAmountToWithdraw = expectedTrancheAmount(tokenAmount);
                        orders[currentId].amount -= trancheAmountToWithdraw;
                        _executeWithdrawOrder(tokenAmount, trancheAmountToWithdraw, order.user);
                        tokenAmount = 0;
                    }
                } else {
                    _removeOrder(currentId);
                    currentId = order.next;
                }
                iterations++;
            } else {
                currentId = order.next;
            }
        }

        return (tokenAmount, iterations);
    }

    function _processDepositOrder(uint256 trancheAmount, uint256 iterationLimit) internal returns (uint256, uint256) {
        uint256 currentId = orders[HEAD].next;
        uint256 iterations = 0;

        while (currentId != NULL && trancheAmount > 0 && iterations < iterationLimit) {
            Order memory order = orders[currentId];

            if (order.orderType == OrderType.DEPOSIT) {
                if (_validateOrder(order, OrderType.DEPOSIT)) {
                    // round up to calculate the tranche amount for msg.sender to pay
                    uint256 orderTrancheAmount = expectedTrancheAmountCeil(order.amount);
                    if (orderTrancheAmount <= trancheAmount) {
                        trancheAmount -= orderTrancheAmount;
                        _executeDepositOrder(order.amount, orderTrancheAmount, order.user);
                        _removeOrder(currentId);
                        currentId = order.next;
                    } else {
                        // round down to calculate the tranche amount for msg.sender to receive
                        uint256 tokenAmountToDeposit = expectedTokenAmount(trancheAmount);
                        orders[currentId].amount -= tokenAmountToDeposit;
                        _executeDepositOrder(tokenAmountToDeposit, trancheAmount, order.user);
                        trancheAmount = 0;
                    }
                } else {
                    _removeOrder(currentId);
                    currentId = order.next;
                }
                iterations++;
            } else {
                currentId = order.next;
            }
        }

        return (trancheAmount, iterations);
    }

    function _createOrder(address user, uint256 amount, OrderType orderType) internal {
        uint256 orderId = nextOrderId++;
        uint256 prevId = orders[HEAD].prev;

        orders[orderId] = Order(orderId, amount, prevId, NULL, block.timestamp, user, orderType);
        orders[prevId].next = orderId;
        orders[HEAD].prev = orderId;
    }

    function _removeOrder(uint256 orderId) internal {
        Order storage order = orders[orderId];

        orders[order.prev].next = order.next;
        orders[order.next].prev = order.prev;

        delete orders[orderId];
    }

    function _cancelOrder(address user) internal {
        uint256 currentId = orders[HEAD].next;

        while (currentId != NULL) {
            Order memory order = orders[currentId];

            if (order.user == user) {
                _removeOrder(currentId);
                break;
            }

            currentId = order.next;
        }
    }

    // TO DEPRECATED: only used in tests
    function _executeDepositOrder(uint256 tokenAmount, address user) internal returns (uint256 trancheAmount) {
        trancheAmount = expectedTrancheAmount(tokenAmount);

        // Transfer USDT from depositor to the user who requested the withdrawal
        token.transferFrom(user, msg.sender, tokenAmount);

        // Transfer tranch from the user who requested the withdrawal to the depositor
        tranche.transferFrom(msg.sender, user, trancheAmount);
    }

    function _executeDepositOrder(uint256 tokenAmount, uint256 trancheAmount, address user) internal {
        // Transfer USDT from depositor to the user who requested the withdrawal
        token.transferFrom(user, msg.sender, tokenAmount);

        // Transfer tranch from the user who requested the withdrawal to the depositor
        tranche.transferFrom(msg.sender, user, trancheAmount);
    }

    function _executeWithdrawOrder(uint256 tokenAmount, uint256 trancheAmount, address user) internal {
        // Transfer USDT from the user who requested the deposit to the withdrawer
        token.transferFrom(msg.sender, user, tokenAmount);

        // Transfer tranch from the withdrawer to the user who requested the deposit
        tranche.transferFrom(user, msg.sender, trancheAmount);
    }

    // TO DEPRECATED: only used in tests
    function _executeWithdrawOrder(uint256 trancheAmount, address user) internal returns (uint256 tokenAmount) {
        tokenAmount = expectedTokenAmount(trancheAmount);

        // Transfer USDT from the user who requested the deposit to the withdrawer
        token.transferFrom(msg.sender, user, tokenAmount);

        // Transfer tranch from the withdrawer to the user who requested the deposit
        tranche.transferFrom(user, msg.sender, trancheAmount);
    }

    // set token
    function _setToken(IERC20 _token) internal {
        token = _token;
    }

    // set tranche
    function _setTranche(ITranchePool _tranche) internal {
        tranche = _tranche;
    }

    function _setPortfolio(IPortfolio _portfolio) internal {
        portfolio = _portfolio;
    }

    function _setDust(uint256 _dust) internal {
        dust = _dust;
        emit DustUpdated(_dust);
    }

    /**
     * @notice check user token allowance for corresponding order type
     */
    function _validateOrder(Order memory order, OrderType orderType) internal view returns (bool) {
        return
            _checkAllowance(order.user, order.amount, orderType) && _checkBalance(order.user, order.amount, orderType);
    }

    function _validateInputs(address user, uint256 amount, OrderType orderType) internal view {
        // double check for the case when dust = 0
        if (amount == 0 || amount < dust) revert InvalidAmount();
        if (!_checkBalance(user, amount, orderType)) revert InsufficientBalance();
        if (!_checkAllowance(user, amount, orderType)) revert InsufficientAllowance();
        if (_isStatus(Status.SeniorClosed) || _isStatus(Status.EquityClosed)) revert PortfolioClosed();
    }

    function _checkBalance(address user, uint256 amount, OrderType orderType) internal view returns (bool) {
        // check user balance
        if (orderType == OrderType.DEPOSIT) {
            return token.balanceOf(user) >= amount;
        } else {
            return tranche.balanceOf(user) >= amount;
        }
    }

    function _checkAllowance(address user, uint256 amount, OrderType orderType) internal view returns (bool) {
        // check user token allowance for corresponding order type
        if (orderType == OrderType.DEPOSIT) {
            return token.allowance(user, address(this)) >= amount;
        } else {
            return tranche.allowance(user, address(this)) >= amount;
        }
    }

    function _isStatus(Status allowedStatus) internal view virtual returns (bool) {
        Status status = portfolio.status();

        return status == allowedStatus;
    }
}