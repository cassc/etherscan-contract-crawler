// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "../../libraries/Tiers.sol";
import "../../libraries/Ticks.sol";
import "../../libraries/Positions.sol";

interface IMuffinHubView {
    /// @notice Return whether the given fee rate is allowed in the given pool
    /// @param poolId       Pool id
    /// @param sqrtGamma    Fee rate, expressed in sqrt(1 - %fee) (precision: 1e5)
    /// @return allowed     True if the % fee is allowed
    function isSqrtGammaAllowed(bytes32 poolId, uint24 sqrtGamma) external view returns (bool allowed);

    /// @notice Return pool's default tick spacing and protocol fee
    /// @return tickSpacing     Default tick spacing applied to new pools. Note that there is also pool-specific default
    ///                         tick spacing which overrides the global default if set.
    /// @return protocolFee     Default protocol fee applied to new pools
    function getDefaultParameters() external view returns (uint8 tickSpacing, uint8 protocolFee);

    /// @notice Return the pool's tick spacing and protocol fee
    /// @return tickSpacing     Pool's tick spacing
    /// @return protocolFee     Pool's protocol fee
    function getPoolParameters(bytes32 poolId) external view returns (uint8 tickSpacing, uint8 protocolFee);

    /// @notice Return a tier state
    function getTier(bytes32 poolId, uint8 tierId) external view returns (Tiers.Tier memory tier);

    /// @notice Return the number of existing tiers in the given pool
    function getTiersCount(bytes32 poolId) external view returns (uint256 count);

    /// @notice Return a tick state
    function getTick(
        bytes32 poolId,
        uint8 tierId,
        int24 tick
    ) external view returns (Ticks.Tick memory tickObj);

    /// @notice Return a position state.
    /// @param poolId           Pool id
    /// @param owner            Address of the position owner
    /// @param positionRefId    Reference id for the position set by the owner
    /// @param tierId           Tier index
    /// @param tickLower        Lower tick boundary of the position
    /// @param tickUpper        Upper tick boundary of the position
    /// @param position         Position struct
    function getPosition(
        bytes32 poolId,
        address owner,
        uint256 positionRefId,
        uint8 tierId,
        int24 tickLower,
        int24 tickUpper
    ) external view returns (Positions.Position memory position);

    /// @notice Return the value of a slot in MuffinHub contract
    function getStorageAt(bytes32 slot) external view returns (bytes32 word);
}