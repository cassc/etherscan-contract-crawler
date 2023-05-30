pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./Refundable.sol";
import "./ExchangeCore.sol";

contract NiftyProtocol is
    Ownable,
    Refundable,
    ExchangeCore
{
    string public name = "Nifty Protocol";

    constructor (uint256 chainId) LibEIP712ExchangeDomain(chainId) {}
    
    /// @dev Fills the input order.
    /// @param order Order struct containing order specifications.
    /// @param signature Proof that order has been created by maker.
    /// @return fulfilled boolean
    function fillOrder(
        LibOrder.Order memory order,
        bytes memory signature,
        bytes32 marketplaceIdentifier
    )
        override
        external
        payable
        refundFinalBalanceNoReentry
        returns (bool fulfilled)
    {
        return _fillOrder(
            order,
            signature,
            msg.sender,
            marketplaceIdentifier
        );
    }

    /// @dev Fills the input order.
    /// @param order Order struct containing order specifications.
    /// @param signature Proof that order has been created by maker.
    /// @param takerAddress address to fulfill the order for / gift.
    /// @return fulfilled boolean
    function fillOrderFor(
        LibOrder.Order memory order,
        bytes memory signature,
        bytes32 marketplaceIdentifier,
        address takerAddress
    )
        override
        external
        payable
        refundFinalBalanceNoReentry
        returns (bool fulfilled)
    {
        return _fillOrder(
            order,
            signature,
            takerAddress,
            marketplaceIdentifier
        );
    }

    /// @dev After calling, the order can not be filled anymore.
    /// @param order Order struct containing order specifications.
    function cancelOrder(LibOrder.Order memory order)
        override
        external
    {
        _cancelOrder(order);
    }

    /// @dev Cancels all orders created by makerAddress with a salt less than or equal to the targetOrderEpoch
    ///      and senderAddress equal to msg.sender (or null address if msg.sender == makerAddress).
    /// @param targetOrderEpoch Orders created with a salt less or equal to this value will be cancelled.
    function cancelOrdersUpTo(uint256 targetOrderEpoch)
        override
        external
    {
        address makerAddress = msg.sender;
        // orderEpoch is initialized to 0, so to cancelUpTo we need salt + 1
        uint256 newOrderEpoch = targetOrderEpoch + 1;
        uint256 oldOrderEpoch = orderEpoch[makerAddress];

        // Ensure orderEpoch is monotonically increasing
        if (newOrderEpoch <= oldOrderEpoch) {
            revert('EXCHANGE: order epoch error');
        }

        // Update orderEpoch
        orderEpoch[makerAddress] = newOrderEpoch;
        emit CancelUpTo(
            makerAddress,
            newOrderEpoch
        );
    }

    /// @dev Gets information about an order: status, hash, and amount filled.
    /// @param order Order to gather information on.
    /// @return orderInfo Information about the order and its state.
    ///         See LibOrder.OrderInfo for a complete description.
    function getOrderInfo(LibOrder.Order memory order)
        override
        public
        view
        returns (LibOrder.OrderInfo memory orderInfo)
    {
        return _getOrderInfo(order);
    }

    function returnAllETHToOwner() external payable onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function returnERC20ToOwner(address ERC20Token) external payable onlyOwner {
        IERC20 CustomToken = IERC20(ERC20Token);
        CustomToken.transferFrom(address(this), msg.sender, CustomToken.balanceOf(address(this)));
    }

    receive() external payable {}
}