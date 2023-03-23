// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import { UniswapV3Pool } from "src/interfaces/uniswapV3/UniswapV3Pool.sol";
import { LimitOrderRegistry } from "src/LimitOrderRegistry.sol";

/**
 * @title Limit Order Registry Lens
 * @notice Stores additional view functions for limit order registry.
 * @author crispymangoes
 */
contract LimitOrderRegistryLens {
    /*//////////////////////////////////////////////////////////////
                             STRUCTS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Stores batch order information and underlying LP position token id.
     * @param id the underling LP position token id
     * @param batchOrder see BatchOrder above
     */
    struct BatchOrderViewData {
        uint256 id;
        LimitOrderRegistry.BatchOrder batchOrder;
    }

    LimitOrderRegistry public registry;

    constructor(LimitOrderRegistry _registry) {
        registry = _registry;
    }

    /*//////////////////////////////////////////////////////////////
                            VIEW LOGIC
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Walks the `orderBook` in a specific `direction`, returning an array of BatchOrderViewData with length of up to `returnCount`.
     * @param pool UniswapV3 pool whose order book you want to query
     * @param startingNode the node to start walking from
     * @param returnCount the max number of values in return array
     * @param direction to walk the order book
     */
    function walkOrders(
        UniswapV3Pool pool,
        uint256 startingNode,
        uint256 returnCount,
        bool direction
    ) external view returns (BatchOrderViewData[] memory orders) {
        orders = new BatchOrderViewData[](returnCount);
        (uint256 centerHead, uint256 centerTail, , , ) = registry.poolToData(pool);
        if (direction) {
            // Walk toward head.
            uint256 targetId = startingNode == 0 ? centerHead : startingNode;
            LimitOrderRegistry.BatchOrder memory target = registry.getOrderBook(targetId);
            for (uint256 i; i < returnCount; ++i) {
                orders[i] = BatchOrderViewData({ id: targetId, batchOrder: target });
                targetId = target.head;
                if (targetId != 0) target = registry.getOrderBook(targetId);
                else break;
            }
        } else {
            // Walk toward tail.
            uint256 targetId = startingNode == 0 ? centerTail : startingNode;
            LimitOrderRegistry.BatchOrder memory target = registry.getOrderBook(targetId);
            for (uint256 i; i < returnCount; ++i) {
                orders[i] = BatchOrderViewData({ id: targetId, batchOrder: target });
                targetId = target.tail;
                if (targetId != 0) target = registry.getOrderBook(targetId);
                else break;
            }
        }
    }

    /**
     * @notice Helper function that finds the appropriate spot in the linked list for a new order.
     * @param pool the Uniswap V3 pool you want to create an order in
     * @param startingNode the UniV3 position Id to start looking
     * @param targetTick the targetTick of the order you want to place
     * @return proposedHead , proposedTail pr the correct head and tail for the new order
     * @dev if both head and tail are zero, just pass in zero for the `startingNode`
     *      otherwise pass in either the nonzero head or nonzero tail for the `startingNode`
     */
    function findSpot(
        UniswapV3Pool pool,
        uint256 startingNode,
        int24 targetTick
    ) external view returns (uint256 proposedHead, uint256 proposedTail) {
        (proposedHead, proposedTail) = registry.findSpot(pool, startingNode, targetTick);
    }

    /**
     * @notice Helper function to get the fee per user for a specific order.
     */
    function getFeePerUser(uint128 batchId) external view returns (uint128) {
        return registry.getClaim(batchId).feePerUser;
    }

    /**
     * @notice Helper function to view if a BatchOrder is ready to claim.
     */
    function isOrderReadyForClaim(uint128 batchId) external view returns (bool) {
        return registry.getClaim(batchId).isReadyForClaim;
    }
}