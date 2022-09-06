// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.10;

import "../../interfaces/lens/IPositionLens.sol";
import "../../libraries/math/PoolMath.sol";
import "../../libraries/math/TickMath.sol";
import "./LensBase.sol";

/**
 * @dev This contract providers utility functions to help derive information for position.
 */
abstract contract PositionLens is IPositionLens, LensBase {
    // PositionInfo struct, defined in IPositionLens.sol.
    // ```
    // struct PositionInfo {
    //     address owner;
    //     address token0;
    //     address token1;
    //     uint8 tierId;
    //     int24 tickLower;
    //     int24 tickUpper;
    // }
    // ```

    /// @inheritdoc IPositionLens
    function getPosition(uint256 tokenId)
        public
        view
        returns (PositionInfo memory info, Positions.Position memory position)
    {
        (info.owner, info.token0, info.token1, info.tierId, info.tickLower, info.tickUpper, position) = manager
            .getPosition(tokenId);
    }

    /// @inheritdoc IPositionLens
    function getDerivedPosition(uint256 tokenId)
        external
        view
        returns (
            PositionInfo memory info,
            Positions.Position memory position,
            bool settled,
            uint256 amount0,
            uint256 amount1,
            uint256 feeAmount0,
            uint256 feeAmount1
        )
    {
        (info, position) = getPosition(tokenId);
        settled = isSettled(info, position);
        (amount0, amount1) = getUnderlyingAmounts(info, position, settled);
        (feeAmount0, feeAmount1) = getFeeAmounts(tokenId, info, position);
    }

    /// @inheritdoc IPositionLens
    function getFeeAmounts(
        uint256 tokenId,
        PositionInfo memory info,
        Positions.Position memory position
    ) public view returns (uint256 feeAmount0, uint256 feeAmount1) {
        (uint80 feeGrowthInside0, uint80 feeGrowthInside1) = hub.getPositionFeeGrowthInside(
            getPoolId(info.token0, info.token1),
            address(manager),
            tokenId,
            info.tierId,
            info.tickLower,
            info.tickUpper
        );
        unchecked {
            feeAmount0 = (uint256(position.liquidityD8) * (feeGrowthInside0 - position.feeGrowthInside0Last)) >> 56;
            feeAmount1 = (uint256(position.liquidityD8) * (feeGrowthInside1 - position.feeGrowthInside1Last)) >> 56;
            position.feeGrowthInside0Last = feeGrowthInside0;
            position.feeGrowthInside1Last = feeGrowthInside1;
        }
    }

    /// @inheritdoc IPositionLens
    function isSettled(PositionInfo memory info, Positions.Position memory position)
        public
        view
        returns (bool settled)
    {
        if (position.limitOrderType != Positions.NOT_LIMIT_ORDER) {
            bool zeroForOne = position.limitOrderType == Positions.ZERO_FOR_ONE;
            (, , uint32 nextSnapshotId) = hub.getSettlement(
                getPoolId(info.token0, info.token1),
                info.tierId,
                zeroForOne ? info.tickUpper : info.tickLower,
                zeroForOne
            );
            settled = position.settlementSnapshotId < nextSnapshotId;
        }
    }

    uint96 internal constant MAX_INT96 = uint96(type(int96).max);

    /// @inheritdoc IPositionLens
    function getUnderlyingAmounts(
        PositionInfo memory info,
        Positions.Position memory position,
        bool settled
    ) public view returns (uint256 amount0, uint256 amount1) {
        uint128 sqrtPriceLower = TickMath.tickToSqrtPrice(info.tickLower);
        uint128 sqrtPriceUpper = TickMath.tickToSqrtPrice(info.tickUpper);

        uint128 sqrtPrice = settled
            ? position.limitOrderType == Positions.ZERO_FOR_ONE ? sqrtPriceUpper : sqrtPriceLower
            : hub.getTier(getPoolId(info.token0, info.token1), info.tierId).sqrtPrice;

        uint96 remaining = position.liquidityD8;
        while (remaining > 0) {
            uint96 liquidityD8Step;
            (liquidityD8Step, remaining) = remaining > MAX_INT96 ? (MAX_INT96, remaining - MAX_INT96) : (remaining, 0);
            (uint256 amount0Step, uint256 amount1Step) = PoolMath.calcAmtsForLiquidity(
                sqrtPrice,
                sqrtPriceLower,
                sqrtPriceUpper,
                -int96(liquidityD8Step)
            );
            amount0 += amount0Step;
            amount1 += amount1Step;
        }
    }

    /// @inheritdoc IPositionLens
    function getPoolId(address token0, address token1) public pure returns (bytes32) {
        return keccak256(abi.encode(token0, token1));
    }
}