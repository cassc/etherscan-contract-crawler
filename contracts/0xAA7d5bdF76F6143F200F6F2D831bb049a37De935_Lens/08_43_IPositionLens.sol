// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "../../libraries/Positions.sol";
import "./ILensBase.sol";

/**
 * @dev This contract providers utility functions to help derive information for position.
 */
interface IPositionLens is ILensBase {
    struct PositionInfo {
        address owner;
        address token0;
        address token1;
        uint8 tierId;
        int24 tickLower;
        int24 tickUpper;
    }

    /// @notice Return a position state by token id
    function getPosition(uint256 tokenId)
        external
        view
        returns (PositionInfo memory info, Positions.Position memory position);

    /// @notice Return a position state and additional information about the position
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
        );

    /// @notice Return the position currently collectable fee amounts
    function getFeeAmounts(
        uint256 tokenId,
        PositionInfo memory info,
        Positions.Position memory position
    ) external view returns (uint256 feeAmount0, uint256 feeAmount1);

    /// @notice Return whether position is already settled
    function isSettled(PositionInfo memory info, Positions.Position memory position)
        external
        view
        returns (bool settled);

    /// @notice Return the position's underlying token amounts
    function getUnderlyingAmounts(
        PositionInfo memory info,
        Positions.Position memory position,
        bool settled
    ) external view returns (uint256 amount0, uint256 amount1);

    /// @notice Return pool id
    function getPoolId(address token0, address token1) external view returns (bytes32);
}