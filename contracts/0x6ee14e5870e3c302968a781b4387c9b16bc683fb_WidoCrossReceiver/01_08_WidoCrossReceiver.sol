// SPDX-License-Identifier: MIT.
pragma solidity 0.8.7;

import "./interfaces/IWidoRouter.sol";
import "solmate/src/utils/SafeTransferLib.sol";

contract WidoCrossReceiver {
    using SafeTransferLib for ERC20;
    using SafeTransferLib for address;

    IWidoRouter public immutable widoRouter;

    /// @notice Event emitted when the order is fulfilled
    /// @param order The order that was fulfilled
    /// @param sender The msg.sender
    /// @param recipient Recipient of the final tokens of the order
    /// @param partner Partner address
    event CrossOrderFulfilled(
        IWidoRouter.Order order,
        address sender,
        address indexed recipient,
        address indexed partner
    );

    error ZeroAddressWidoRouter();
    error SingleTokenInputExpected();

    constructor(IWidoRouter _widoRouter) {
        if (address(_widoRouter) == address(0)) revert ZeroAddressWidoRouter();

        widoRouter = _widoRouter;
    }

    /// @notice Receives an order initiated from WidoCrossRouter on source chain
    /// @param order The order to be executed on destination chain
    /// @param route The route of the order
    /// @param recipient Recipient of the final tokens of the order
    /// @param partner Partner address
    function receiveCrossOrder(
        IWidoRouter.Order calldata order,
        IWidoRouter.Step[] calldata route,
        address recipient,
        address partner
    ) external payable {
        if (order.inputs.length != 1) revert SingleTokenInputExpected();

        _sendTokens(order.inputs[0]);

        IWidoRouter.Order memory modifiedOrder = order;
        modifiedOrder.user = address(this);
        delete modifiedOrder.inputs;

        widoRouter.executeOrder{value: msg.value}(modifiedOrder, route, recipient, 0, partner);

        emit CrossOrderFulfilled(modifiedOrder, msg.sender, recipient, partner);
    }

    /// @notice Transfers tokens
    /// @param input The order input
    function _sendTokens(IWidoRouter.OrderInput memory input) private {
        if (input.tokenAddress != address(0)) {
            uint256 _amount = ERC20(input.tokenAddress).balanceOf(msg.sender);
            ERC20(input.tokenAddress).safeTransferFrom(msg.sender, address(widoRouter), _amount);
        }
    }
}