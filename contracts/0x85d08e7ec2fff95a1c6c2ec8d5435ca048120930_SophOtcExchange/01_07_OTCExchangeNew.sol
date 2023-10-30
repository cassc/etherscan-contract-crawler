// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/// @title SOPH OTC Exchange
/// @author hodl.esf.eth
contract SophOtcExchange is Ownable {

    using SafeERC20 for IERC20;

    struct Order {
        uint128 amount;
        uint128 price;
        address seller;
        uint64 validUntil;
        bool filled;
        bool cancelled;
        address paymentToken;
    }
    mapping(IERC20 => bool) public paymentTokens;  // Mapping to store approved payment tokens
    mapping(uint256 => Order) public orders;
    uint256 public nextOrderId = 1;
    uint256 public tokenBalance;
    uint256 public constant FEE_RATE = 250;  // 0.25%
    IERC20 public immutable allowedToken;

    /// @notice Event emitted when a new order is created
    event OrderCreated(uint256 indexed orderId, address indexed seller, uint128 amount, uint128 price, uint64 validUntil, address paymentToken);
    /// @notice Event emitted when an order is cancelled
    event OrderCancelled(uint256 indexed orderId);
    /// @notice Event emitted when an order is filled
    event OrderFilled(uint256 indexed orderId, address indexed buyer, address indexed seller, uint128 amount, uint128 price, address currency);
    /// @notice Event emitted when a payment token is added
    event PaymentTokenAdded(IERC20 indexed newPaymentToken);
    /// @notice Event emitted when a payment token is removed
    event PaymentTokenRemoved(IERC20 indexed removedPaymentToken);


    error TransferFailed(address from, uint128 amount);
    error CancellationFailed(address from, uint256 orderId);
    error FillFailed(address from, uint256 orderId);
    error WithdrawFailed(address to, uint256 amount);
    error OrderCreationFailed(uint128 amount, uint128 price, uint64 validUntil);
    error PaymentTokenOperationFailed(address token);
    error InvalidPaymentToken(IERC20 token);


    /// @notice Contract constructor
    /// @param _allowedToken The address of the token that is allowed for trading
constructor(IERC20 _allowedToken) {
    allowedToken = _allowedToken;
}

    /// @notice Creates a new order
    /// @param amount The amount of tokens to sell
    /// @param price The price per token
    /// @param validUntil The time until the order is valid
    /// @param paymentToken The token to use for payment
function createOrder(uint128 amount, uint128 price, uint64 validUntil, address paymentToken) external {
    if (validUntil <= block.timestamp || amount == 0 || price == 0) {
        revert OrderCreationFailed(amount, price, validUntil);
    }
  
    allowedToken.safeTransferFrom(msg.sender, address(this), amount);

    uint256 orderId;

    unchecked{
        orderId = nextOrderId++;
    }

    orders[orderId] = Order(amount, price, msg.sender, validUntil, false, false, paymentToken);
    tokenBalance += amount;

    emit OrderCreated(orderId, msg.sender, amount, price, validUntil, paymentToken);
}

    /// @notice Cancels an existing order
    /// @param orderId The ID of the order to cancel
function cancelOrder(uint256 orderId) external {
    Order storage order = orders[orderId];

    // Check multiple conditions: if the caller is the seller, if the order is not already cancelled, and if it's not already filled
    if (order.seller != msg.sender || order.cancelled || order.filled) {
        revert CancellationFailed(msg.sender, orderId);
    }

    // Mark the order as cancelled
    order.cancelled = true;

    // Transfer the tokens back to the seller
    allowedToken.safeTransfer(msg.sender, order.amount);

    // Update the token balance stored in the contract
    tokenBalance -= order.amount;

    emit OrderCancelled(orderId);
}

    /// @notice Fills an existing order
    /// @param orderId The ID of the order to fill
function fillOrder(uint256 orderId) external payable {
    Order storage order = orders[orderId];

    if (order.filled || order.cancelled || order.validUntil < block.timestamp) {
        revert FillFailed(msg.sender, orderId);
    }

    // For ETH payments, validate msg.value
    if (order.paymentToken == address(0) && msg.value != order.price) {
        revert FillFailed(msg.sender, orderId);
    }

    order.filled = true;

    // Case: Payment in ETH
    if (order.paymentToken == address(0)) {
        uint256 fee = (msg.value * FEE_RATE) / 10000;
        uint256 sellerShare = msg.value - fee;

        // Fee remains in the contract, so no need to explicitly transfer

        // Transfer remaining amount to the seller
        (bool success,) = order.seller.call{value: sellerShare}("");
        if (!success) {
            revert FillFailed(order.seller, orderId);
        }

    // Case: Payment in ERC-20
    } else if (paymentTokens[IERC20(order.paymentToken)]) {
        IERC20 token = IERC20(order.paymentToken);

        uint256 fee = (order.price * FEE_RATE) / 10000;
        uint256 sellerShare = order.price - fee;

        // this will revert if fails
        token.safeTransferFrom(msg.sender, owner(), fee);
        token.safeTransferFrom(msg.sender, order.seller, sellerShare);

    } else {
        revert("Payment token not supported");
    }

    allowedToken.transfer(msg.sender, order.amount);

    // Update the token balance stored in the contract
    tokenBalance -= order.amount;

    emit OrderFilled(orderId, msg.sender, order.seller, order.amount, order.price, order.paymentToken);
}


    /// @notice Withdraws tokens from the contract
    /// @param token The token to withdraw
    function withdrawToken(IERC20 token) external onlyOwner {

        if (address(token) == address(allowedToken)) {
            revert WithdrawFailed(msg.sender, tokenBalance);
        }

        uint256 amount = token.balanceOf(address(this));
        token.safeTransfer(msg.sender, amount);
    }

    /// @notice Withdraws excess allowed tokens from the contract
function withdrawAllowedToken() external onlyOwner {
    uint256 actualBalance = allowedToken.balanceOf(address(this));
    uint256 excess = actualBalance - tokenBalance;

    require(excess > 0, "No excess tokens to withdraw");

    allowedToken.safeTransfer(msg.sender, excess);
}

    /// @notice Withdraws ETH from the contract
    function withdrawETH() external onlyOwner {
        uint256 amount = address(this).balance;
        (bool success,) = msg.sender.call{value: amount}("");
        if (!success) {
            revert WithdrawFailed(msg.sender, amount);
        }
    }

    /// @notice Adds a payment token
    /// @param _paymentToken The token to add as a payment option
function addPaymentToken(IERC20 _paymentToken) external onlyOwner {
    if (address(_paymentToken) == address(allowedToken) || address(_paymentToken) == address(0)) {
        revert InvalidPaymentToken(_paymentToken);
    }

    paymentTokens[_paymentToken] = true;

    emit PaymentTokenAdded(_paymentToken);
}

    /// @notice Removes a payment token
    /// @param _paymentToken The payment token to remove
function removePaymentToken(IERC20 _paymentToken) external onlyOwner {
    if (!paymentTokens[_paymentToken]) {
        revert InvalidPaymentToken(_paymentToken);
    }

    delete paymentTokens[_paymentToken];

    emit PaymentTokenRemoved(_paymentToken);
}

}