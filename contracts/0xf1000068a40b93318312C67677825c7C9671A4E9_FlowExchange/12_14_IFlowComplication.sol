// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import { OrderTypes } from "../libs/OrderTypes.sol";

/**
 * @title IFlowComplication
 * @author nneverlander. Twitter @nneverlander
 * @notice Complication interface that must be implemented by all complications (execution strategies)
 */
interface IFlowComplication {
    function canExecMatchOneToOne(
        OrderTypes.MakerOrder calldata makerOrder1,
        OrderTypes.MakerOrder calldata makerOrder2
    ) external view returns (bool, bytes32, bytes32, uint256);

    function canExecMatchOneToMany(
        OrderTypes.MakerOrder calldata makerOrder,
        OrderTypes.MakerOrder[] calldata manyMakerOrders
    ) external view returns (bool, bytes32);

    function canExecMatchOrder(
        OrderTypes.MakerOrder calldata sell,
        OrderTypes.MakerOrder calldata buy,
        OrderTypes.OrderItem[] calldata constructedNfts
    ) external view returns (bool, bytes32, bytes32, uint256);

    function canExecTakeOneOrder(
        OrderTypes.MakerOrder calldata makerOrder
    ) external view returns (bool, bytes32);

    function canExecTakeOrder(
        OrderTypes.MakerOrder calldata makerOrder,
        OrderTypes.OrderItem[] calldata takerItems
    ) external view returns (bool, bytes32);

    function verifyMatchOneToManyOrders(
        bool verifySellOrder,
        OrderTypes.MakerOrder calldata sell,
        OrderTypes.MakerOrder calldata buy
    ) external view returns (bool, bytes32);
}