// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {OrderTypes} from "./libraries/OrderTypes.sol";
import {IExecutionStrategy} from "./interfaces/IExecutionStrategy.sol";
import {IProtocolFeeManager} from "./interfaces/IProtocolFeeManager.sol";

/**
 * @title StrategyAnyItemFromCollectionForFixedPrice
 * @notice Strategy to send an order at a fixed price that can be
 * matched by any tokenId for the collection.
 */
contract StrategyAnyItemFromCollectionForFixedPrice is IExecutionStrategy {
    /**
     * @notice Check whether a taker ask order can be executed against a maker bid
     * @param takerAsk taker ask order
     * @param makerBid maker bid order
     * @return (whether strategy can be executed, tokenId to execute, amount of tokens to execute)
     */
    function canExecuteTakerAsk(
        OrderTypes.TakerOrder calldata takerAsk,
        OrderTypes.MakerOrder calldata makerBid
    )
        external
        view
        override
        returns (
            bool,
            uint256,
            uint256
        )
    {
        return (
            ((makerBid.price == takerAsk.price) &&
                (makerBid.endTime >= block.timestamp) &&
                (makerBid.startTime <= block.timestamp)),
            takerAsk.tokenId,
            makerBid.amount
        );
    }

    /**
     * @notice Check whether a taker bid order can be executed against a maker ask
     * @return (whether strategy can be executed, tokenId to execute, amount of tokens to execute)
     * @dev It cannot execute but it is left for compatibility purposes with the interface.
     */
    function canExecuteTakerBid(
        OrderTypes.TakerOrder calldata,
        OrderTypes.MakerOrder calldata
    )
        external
        pure
        override
        returns (
            bool,
            uint256,
            uint256
        )
    {
        return (false, 0, 0);
    }
}