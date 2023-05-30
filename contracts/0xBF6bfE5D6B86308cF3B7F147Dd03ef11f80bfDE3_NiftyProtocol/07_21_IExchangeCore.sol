pragma solidity ^0.8.4;

import "../libs/LibOrder.sol";


abstract contract IExchangeCore {

    // Fill event is emitted whenever an order is filled.
    event Fill(
        address indexed makerAddress,         // Address that created the order.
        address indexed royaltiesAddress,     // Address that received fees.
        bytes makerAssetData,                 // Encoded data specific to makerAsset.
        bytes takerAssetData,                 // Encoded data specific to takerAsset.
        bytes32 indexed orderHash,            // EIP712 hash of order (see LibOrder.getTypedDataHash).
        address takerAddress,                 // Address that filled the order.
        address senderAddress,                // Address that called the Exchange contract (msg.sender).
        uint256 makerAssetAmount,             // Amount of makerAsset sold by maker and bought by taker.
        uint256 takerAssetAmount,             // Amount of takerAsset sold by taker and bought by maker.
        uint256 royaltiesAmount,              // Amount of royalties paid to royaltiesAddress.
        uint256 protocolFeePaid,              // Amount paid to the protocol.
        bytes32 marketplaceIdentifier,        // marketplace identifier.
        uint256 marketplaceFeePaid            // Amount paid to the marketplace brought the taker.
    );

    // Cancel event is emitted whenever an individual order is cancelled.
    event Cancel(
        address indexed makerAddress,         // Address that created the order.
        bytes makerAssetData,                 // Encoded data specific to makerAsset.
        bytes takerAssetData,                 // Encoded data specific to takerAsset.
        address senderAddress,                // Address that called the Exchange contract (msg.sender).
        bytes32 indexed orderHash             // EIP712 hash of order (see LibOrder.getTypedDataHash).
    );

    // CancelUpTo event is emitted whenever `cancelOrdersUpTo` is executed succesfully.
    event CancelUpTo(
        address indexed makerAddress,         // Orders cancelled must have been created by this address.
        uint256 orderEpoch                    // Orders with a salt less than this value are considered cancelled.
    );

    /// @dev Cancels all orders created by makerAddress with a salt less than or equal to the targetOrderEpoch
    /// @param targetOrderEpoch Orders created with a salt less or equal to this value will be cancelled.
    function cancelOrdersUpTo(uint256 targetOrderEpoch)
        virtual
        external;

    /// @dev Fills the input order.
    /// @param order Order struct containing order specifications.
    /// @param signature Proof that order has been created by maker.
    /// @return fulfilled boolean
    function fillOrder(
        LibOrder.Order memory order,
        bytes memory signature,
        bytes32 marketIdentifier
    )
        virtual
        external
        payable
        returns (bool fulfilled);

    /// @dev Fills the input order.
    /// @param order Order struct containing order specifications.
    /// @param signature Proof that order has been created by maker.
    /// @param takerAddress address to fulfill the order for / gift.
    /// @return fulfilled boolean
    function fillOrderFor(
        LibOrder.Order memory order,
        bytes memory signature,
        bytes32 marketIdentifier,
        address takerAddress
    )
        virtual
        external
        payable
        returns (bool fulfilled);

    /// @dev After calling, the order can not be filled anymore.
    /// @param order Order struct containing order specifications.
    function cancelOrder(LibOrder.Order memory order)
        virtual
        external;

    /// @dev Gets information about an order: status, hash, and amount filled.
    /// @param order Order to gather information on.
    /// @return orderInfo Information about the order and its state.
    ///                   See LibOrder.OrderInfo for a complete description.
    function getOrderInfo(LibOrder.Order memory order)
        virtual
        external
        view
        returns (LibOrder.OrderInfo memory orderInfo);
}