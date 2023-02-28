/**
 * @author Musket
 */
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./IPositionNondisperseLiquidity.sol";

interface IUpdateStakingManager {
    // TODO add guard
    function updateStakingLiquidity(
        address user,
        uint256 tokenId,
        address poolId,
        uint128 deltaLiquidityModify,
        ILiquidityManager.ModifyType modifyType
    ) external returns (address caller);
}