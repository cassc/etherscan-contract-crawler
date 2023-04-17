// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {IArrakisV2} from "./IArrakisV2.sol";
import {RangeWeight, Rebalance} from "../structs/SArrakisV2.sol";

interface IArrakisV2Resolver {
    function standardRebalance(
        RangeWeight[] memory rangeWeights_,
        IArrakisV2 vaultV2_
    ) external view returns (Rebalance memory rebalanceParams);

    function getMintAmounts(
        IArrakisV2 vaultV2_,
        uint256 amount0Max_,
        uint256 amount1Max_
    )
        external
        view
        returns (
            uint256 amount0,
            uint256 amount1,
            uint256 mintAmount
        );

    function getAmountsForLiquidity(
        int24 currentTick_,
        int24 lowerTick_,
        int24 upperTick_,
        uint128 liquidity_
    ) external pure returns (uint256 amount0, uint256 amount1);

    function getPositionId(
        address addr_,
        int24 lowerTick_,
        int24 upperTick_
    ) external pure returns (bytes32 positionId);
}