// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "./ILensBase.sol";

interface ITickLens is ILensBase {
    /**
     * @notice Get ticks of a tier.
     * @param poolId    Pool id
     * @param tierId    Tier id
     * @param tickStart First tick to get. This tick must be initialized.
     * @param tickEnd   Ticks beyond "tickEnd" is not included in the return data. Can be uninitialized.
     * @param maxCount  Max number of ticks to retrieve
     * @return count    Number of ticks retrieved
     * @return ticks    List of ticks concatenated into bytes.
     * Each tick consists of 256 bits:
     * - int24  tickIdx
     * - uint96 liquidityLowerD8
     * - uint96 liquidityUpperD8
     * - bool   needSettle0
     * - bool   needSettle1
     * To parse it in ether.js, see the example https://github.com/muffinfi/muffin/blob/master/test/lens/03_tick_lens.ts#L11
     *
     * @dev Estimated gas costs:
     * - 1 tick:     33659 gas
     * - 10 ticks:   74157 gas
     * - 100 ticks:  476268 gas
     * - 1000 ticks: 5045298 gas
     * - 2000 ticks: 12886983 gas
     */
    function getTicks(
        bytes32 poolId,
        uint8 tierId,
        int24 tickStart,
        int24 tickEnd,
        uint24 maxCount
    ) external view returns (uint256 count, bytes memory ticks);
}