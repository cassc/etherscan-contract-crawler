// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import {
    IUniswapV3Pool
} from "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import {Range} from "../structs/SArrakisV2.sol";

library Position {
    function getLiquidityByRange(
        IUniswapV3Pool pool_,
        address self_,
        int24 lowerTick_,
        int24 upperTick_
    ) public view returns (uint128 liquidity) {
        (liquidity, , , , ) = pool_.positions(
            getPositionId(self_, lowerTick_, upperTick_)
        );
    }

    function getPositionId(
        address self_,
        int24 lowerTick_,
        int24 upperTick_
    ) public pure returns (bytes32 positionId) {
        return keccak256(abi.encodePacked(self_, lowerTick_, upperTick_));
    }

    function rangeExists(Range[] memory currentRanges_, Range memory range_)
        public
        pure
        returns (bool ok, uint256 index)
    {
        for (uint256 i; i < currentRanges_.length; i++) {
            ok =
                range_.lowerTick == currentRanges_[i].lowerTick &&
                range_.upperTick == currentRanges_[i].upperTick &&
                range_.feeTier == currentRanges_[i].feeTier;
            if (ok) {
                index = i;
                break;
            }
        }
    }
}