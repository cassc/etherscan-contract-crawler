// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./AssetLib.sol";

/**
 * @title OrderLib
 * @notice Library for handling Order data structure
 */
library OrderLib {
    /*//////////////////////////////////////////////////////////////
                            ORDER CONSTANTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Bytes4 representations of the protocol version.
    bytes4 public constant VERSION = bytes4(keccak256("V1"));

    /// @notice Bytes4 representations of allowed operations.
    bytes4 public constant CREATE_ORDER_TYPE = bytes4(keccak256("CREATE"));
    bytes4 public constant UPDATE_ORDER_TYPE = bytes4(keccak256("UPDATE"));
    bytes4 public constant CANCEL_ORDER_TYPE = bytes4(keccak256("CANCEL"));
    bytes4 public constant FINALIZE_ORDER_TYPE = bytes4(keccak256("FINALIZE"));

    /// @notice OrderData typehash for EIP712 compatibility.
    bytes32 public constant ORDER_TYPEHASH =
        keccak256(
            "OrderData(address maker,address taker,address arbitrator,AssetData[] makeAssets,AssetData[] takeAssets,AssetData[] extraAssets,bytes32 message,uint256 salt,uint256 start,uint256 end,bytes4 orderType,bytes4 version)AssetData(AssetType assetType,uint256 value,address recipient)AssetType(bytes4 assetClass,bytes data)"
        );

    /// @notice OrderUpdateData typehash for EIP712 compatibility.
    bytes32 public constant ORDER_UPDATE_TYPEHASH =
        keccak256(
            "OrderUpdateData(OrderData orderOld,OrderData orderNew)AssetData(AssetType assetType,uint256 value,address recipient)AssetType(bytes4 assetClass,bytes data)OrderData(address maker,address taker,address arbitrator,AssetData[] makeAssets,AssetData[] takeAssets,AssetData[] extraAssets,bytes32 message,uint256 salt,uint256 start,uint256 end,bytes4 orderType,bytes4 version)"
        );

    /*//////////////////////////////////////////////////////////////
                          ORDER DATA STRUCTURE
    //////////////////////////////////////////////////////////////*/

    /// @notice Struct holding the specification of an escrow order.
    struct OrderData {
        // Address that delivers the goods/services.
        address maker;
        // Address that deposits the payment assets.
        address taker;
        // Address given the right to arbitrate in case of dispute.
        address arbitrator;
        // Assets that will be delivered at the end of escrow.
        AssetLib.AssetData[] makeAssets;
        // Assets that will be deposited at the start of escrow.
        AssetLib.AssetData[] takeAssets;
        // Extra (bonus) assets that will be delivered at the end of escrow.
        AssetLib.AssetData[] extraAssets;
        // Hash of the request message content.
        bytes32 message;
        // Number to provide uniqueness to the order.
        uint256 salt;
        // The start time of an order.
        uint256 start;
        // The expiry time of an order.
        uint256 end;
        // Type of order to execute.
        bytes4 orderType;
        // Current protocol version.
        bytes4 version;
    }

    /// @notice Struct holding the specification of an order update.
    struct OrderUpdateData {
        // Old order data to cancel.
        OrderData orderOld;
        // New order data to create.
        OrderData orderNew;
    }

    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/

    error InvalidMaker();
    error InvalidTaker();
    error InvalidTakeAssets();
    error InvalidStart();
    error InvalidEnd();
    error InvalidOrderType();
    error InvalidVersion();

    /*//////////////////////////////////////////////////////////////
                             HASH FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Hash OrderData to generate unique order id.
     * @param order OrderData of the order.
     * @return hash of the order.
     */
    function hashKey(OrderData calldata order) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    order.maker,
                    order.taker,
                    order.takeAssets,
                    order.message,
                    order.salt,
                    order.start,
                    order.end,
                    order.arbitrator,
                    order.version
                )
            );
    }

    /**
     * @notice EIP712-compatible hash of OrderData.
     * @param order OrderData of the order.
     * @return hash of the order.
     */
    function hash(OrderData calldata order) internal pure returns (bytes32) {
        // Split to avoid stack too deep error
        return
            keccak256(
                bytes.concat(
                    abi.encode(
                        ORDER_TYPEHASH,
                        order.maker,
                        order.taker,
                        order.arbitrator,
                        AssetLib.packAssets(order.makeAssets),
                        AssetLib.packAssets(order.takeAssets),
                        AssetLib.packAssets(order.extraAssets)
                    ),
                    abi.encodePacked(
                        order.message,
                        order.salt,
                        order.start,
                        order.end,
                        bytes32(order.orderType),
                        bytes32(order.version)
                    )
                )
            );
    }

    /**
     * @notice EIP712-compatible hash of OrdersData.
     * @param orderUpdate OrderUpdateData orders.
     * @return hash of the orders.
     */
    function hash(OrderUpdateData calldata orderUpdate)
        internal
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encode(
                    ORDER_UPDATE_TYPEHASH,
                    OrderLib.hash(orderUpdate.orderOld),
                    OrderLib.hash(orderUpdate.orderNew)
                )
            );
    }

    /**
     * @notice EIP712-compatible hash packing of OrderData.
     * @param orders OrderData orders to pack.
     * @return hash of the orders.
     */
    function packOrders(OrderData[] calldata orders)
        internal
        pure
        returns (bytes32)
    {
        bytes32[] memory orderHashes = new bytes32[](orders.length);
        for (uint256 i = 0; i < orders.length; i++) {
            orderHashes[i] = hash(orders[i]);
        }
        return keccak256(abi.encodePacked(orderHashes));
    }

    /*//////////////////////////////////////////////////////////////
                            VALIDATION LOGIC
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Check validity of an order.
     * @param order OrderData order to check.
     * @return True if order is valid.
     */
    function validate(OrderData calldata order) internal pure returns (bool) {
        if (order.maker == address(0)) {
            revert InvalidMaker();
        } else if (order.taker == address(0)) {
            revert InvalidTaker();
        } else if (order.takeAssets.length == 0) {
            revert InvalidTakeAssets();
        } else if (order.start == 0) {
            revert InvalidStart();
        } else if (order.end == 0) {
            revert InvalidEnd();
        } else if (
            !(order.orderType == CREATE_ORDER_TYPE ||
                order.orderType == UPDATE_ORDER_TYPE ||
                order.orderType == CANCEL_ORDER_TYPE ||
                order.orderType == FINALIZE_ORDER_TYPE)
        ) {
            revert InvalidOrderType();
        } else if (order.version != VERSION) {
            revert InvalidVersion();
        }

        return true;
    }
}