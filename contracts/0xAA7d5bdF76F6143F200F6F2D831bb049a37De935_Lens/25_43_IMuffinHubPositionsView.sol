// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "../../../libraries/Settlement.sol";
import "../../../libraries/Tiers.sol";

interface IMuffinHubPositionsView {
    /// @notice Return pool's default allowed fee rates
    /// @return sqrtGammas  List of fee rate, expressed in sqrt(1 - %fee) (precision: 1e5)
    function getDefaultAllowedSqrtGammas() external view returns (uint24[] memory sqrtGammas);

    /// @notice Return the pool's allowed fee rates
    /// @param poolId       Pool id
    /// @return sqrtGammas  List of fee rate, expressed in sqrt(1 - %fee) (precision: 1e5)
    function getPoolAllowedSqrtGammas(bytes32 poolId) external view returns (uint24[] memory sqrtGammas);

    /// @notice Return the pool's default tick spacing. If set, it overrides the global default tick spacing.
    /// @param poolId       Pool id
    /// @return tickSpacing Tick spacing. Zero means it is not set.
    function getPoolDefaultTickSpacing(bytes32 poolId) external view returns (uint8 tickSpacing);

    /// @notice Return the states of all the tiers in the given pool
    function getAllTiers(bytes32 poolId) external view returns (Tiers.Tier[] memory tiers);

    /// @notice Return the current fee-per-liquidity accumulator in the position's range.
    /// If the position was a limit order and already settled, return the values at when the position was settled.
    /// @return feeGrowthInside0 Accumulated token0 fee per liquidity since the creation of the pool
    /// @return feeGrowthInside1 Accumulated token1 fee per liquidity since the creation of the pool
    function getPositionFeeGrowthInside(
        bytes32 poolId,
        address owner,
        uint256 positionRefId,
        uint8 tierId,
        int24 tickLower,
        int24 tickUpper
    ) external view returns (uint80 feeGrowthInside0, uint80 feeGrowthInside1);

    /// @notice Return the state of a settlement
    /// @param poolId           Pool id
    /// @param tierId           Tier Index
    /// @param tick             Tick number at which the settlement occurs
    /// @param zeroForOne       Direction of the limit orders that the settlement handles
    /// @return liquidityD8     Amount of liquidity pending to settle
    /// @return tickSpacing     Width of the limit orders which the settlement will settle
    /// @return nextSnapshotId  Next data snapshot id that will be used
    function getSettlement(
        bytes32 poolId,
        uint8 tierId,
        int24 tick,
        bool zeroForOne
    )
        external
        view
        returns (
            uint96 liquidityD8,
            uint16 tickSpacing,
            uint32 nextSnapshotId
        );

    /// @notice Return a data snapshot of a settlement
    /// @param poolId       Pool id
    /// @param tierId       Tier Index
    /// @param tick         Tick number at which the settlement occurs
    /// @param zeroForOne   Direction of the limit orders that the settlement handles
    /// @param snapshotId   Snapshot id of your desired snapshot of this settlement
    function getSettlementSnapshot(
        bytes32 poolId,
        uint8 tierId,
        int24 tick,
        bool zeroForOne,
        uint32 snapshotId
    ) external view returns (Settlement.Snapshot memory snapshot);

    /// @notice Return the tick spacing multipliers for limit orders in the given pool's tiers,
    /// i.e. the list of required width of the limit range orders on each tier,
    /// e.g. 1 means "pool.tickSpacing * 1", 0 means disabled.
    function getLimitOrderTickSpacingMultipliers(bytes32 poolId)
        external
        view
        returns (uint8[] memory tickSpacingMultipliers);
}