// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import { OrderTypes } from "../libs/OrderTypes.sol";

/**
 * @title IFlowExchange
 * @author Joe
 * @notice Exchange interface that must be implemented by the Flow Exchange
 */
interface IFlowExchange {
    function matchOneToOneOrders(
        OrderTypes.MakerOrder[] calldata makerOrders1,
        OrderTypes.MakerOrder[] calldata makerOrders2
    ) external;

    function matchOneToManyOrders(
        OrderTypes.MakerOrder calldata makerOrder,
        OrderTypes.MakerOrder[] calldata manyMakerOrders
    ) external;

    function matchOrders(
        OrderTypes.MakerOrder[] calldata sells,
        OrderTypes.MakerOrder[] calldata buys,
        OrderTypes.OrderItem[][] calldata constructs
    ) external;

    function takeMultipleOneOrders(
        OrderTypes.MakerOrder[] calldata makerOrders
    ) external payable;

    function takeOrders(
        OrderTypes.MakerOrder[] calldata makerOrders,
        OrderTypes.OrderItem[][] calldata takerNfts
    ) external payable;

    function transferMultipleNFTs(
        address to,
        OrderTypes.OrderItem[] calldata items
    ) external;

    function cancelAllOrders(uint256 minNonce) external;

    function cancelMultipleOrders(uint256[] calldata orderNonces) external;

    function isNonceValid(
        address user,
        uint256 nonce
    ) external view returns (bool);
}