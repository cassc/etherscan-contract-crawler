// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Interface to Liquidity state
 */
interface ILiquidity {
    /**************************************************************************/
    /* Structures */
    /**************************************************************************/

    /**
     * @notice Node source
     * @param tick Tick
     * @param used Amount used
     */
    struct NodeSource {
        uint128 tick;
        uint128 used;
    }

    /**
     * @notice Flattened liquidity node returned by getter
     * @param tick Tick
     * @param value Liquidity value
     * @param shares Liquidity shares outstanding
     * @param available Liquidity available
     * @param pending Liquidity pending (with interest)
     * @param redemptions Total pending redemptions
     * @param prev Previous liquidity node
     * @param next Next liquidity node
     */
    struct NodeInfo {
        uint128 tick;
        uint128 value;
        uint128 shares;
        uint128 available;
        uint128 pending;
        uint128 redemptions;
        uint128 prev;
        uint128 next;
    }

    /**************************************************************************/
    /* API */
    /**************************************************************************/

    /**
     * Get liquidity nodes spanning [startTick, endTick] range
     * @param startTick Start tick
     * @param endTick End tick
     * @return Liquidity nodes
     */
    function liquidityNodes(uint128 startTick, uint128 endTick) external view returns (NodeInfo[] memory);

    /**
     * Get liquidity node at tick
     * @param tick Tick
     * @return Liquidity node
     */
    function liquidityNode(uint128 tick) external view returns (NodeInfo memory);
}