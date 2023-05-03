// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.18;

enum OrderType {
    NONE,
    DEPOSIT,
    WITHDRAW
}

struct Order {
    uint256 id;
    uint256 amount;
    uint256 prev;
    uint256 next;
    uint256 createdAt;
    address user;
    OrderType orderType;
}

interface IOrderController {
    // Custom errors for _validateInputs
    error InvalidAmount();
    error InvalidOrderType();
    error InvalidOrderId();
    error InsufficientBalance();
    error InsufficientAllowance();
    error PortfolioClosed();

    event DustUpdated(uint256 newDust);

    /// @notice Allows a user to deposit tokens and create a DEPOSIT order. It doesn't gurantee deposit
    /// @dev The order can be executed if there's a matching withdrawal request. The caller should approve tokens prior
    /// to calling this function.
    /// @param tokenAmount The amount of tokens to deposit.
    /// @param iterationLimit The maximum number of orders to process in a single call.
    function deposit(uint256 tokenAmount, uint256 iterationLimit) external;

    /// @notice Allows a user to withdraw tranches and create a WITHDRAW order.
    /// @dev The order can be executed if there's a matching deposit request. The caller should approve tranches prior
    /// to calling this function.
    /// @param trancheAmount The amount of tranches to withdraw.
    /// @param iterationLimit The maximum number of orders to process in a single call.
    function withdraw(uint256 trancheAmount, uint256 iterationLimit) external;

    /// @notice Allows a user to cancel their pending order.
    /// @dev This can be called by the user who placed the order only.
    function cancelOrder() external;

    /// @notice Allows any users to cancel dust order.
    /// @param orderId The order id to cancel.
    function cancelDustOrder(uint256 orderId) external;

    /// @notice Calculate the expected token amount for a given tranche amount.
    /// @param trancheAmount The amount of tranches to convert.
    /// @return The expected token amount.
    function expectedTokenAmount(uint256 trancheAmount) external view returns (uint256);

    /// @notice Calculate the expected tranche amount for a given token amount.
    /// @param tokenAmount The amount of tokens to convert.
    /// @return The expected tranche amount.
    function expectedTrancheAmount(uint256 tokenAmount) external view returns (uint256);

    /// @notice Return the type of the current order in the linked list of orders
    function currentOrderType() external view returns (OrderType);

    /// @notice Return the count of valid orders and the current order type.
    /// @return count The count of valid orders.
    /// @return orderType The type of the current order.
    function getValidOrderCount() external view returns (uint256 count, OrderType orderType);

    /// @notice Return the valid orders and the current order type.
    /// @return orders The valid orders.
    /// @return orderType The type of the order.
    function getValidOrders() external view returns (Order[] memory, OrderType);

    /// @notice Return the count of all orders.
    /// @return The count of all orders.
    function getOrderCount() external view returns (uint256);

    /// @notice Return all orders.
    /// @return The orders.
    function getOrders() external view returns (Order[] memory);

    /// @notice Return the order of the given user.
    /// @param user The user address.
    /// @return The order.
    function getUserOrder(address user) external view returns (Order memory);

    /// @notice Return the min amount of an order.
    /// @return The minimum value.
    function dust() external view returns (uint256);
}