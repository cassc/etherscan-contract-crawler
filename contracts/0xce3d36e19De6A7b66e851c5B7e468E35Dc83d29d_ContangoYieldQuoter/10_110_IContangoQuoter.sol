//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "../libraries/QuoterDataTypes.sol";

/// @title Interface to allow for quoting position operations
interface IContangoQuoter {
    /// @notice Quotes the position status
    /// @param positionId The id of a position
    /// @param uniswapFee The fee (pool) to be used for the quote
    /// @return position status
    function positionStatus(PositionId positionId, uint24 uniswapFee) external returns (PositionStatus memory);

    /// @notice Quotes the cost to open a position with the respective collateral used
    /// @param params opening cost parameters
    /// @return opening cost result
    /// Will either be the same as minCollateral in case the collateral passed is insufficient, the same as the collateral passed or capped to the maximum collateralisation possible
    function openingCostForPosition(OpeningCostParams calldata params) external returns (ModifyCostResult memory);

    /// @notice Quotes the cost to modify a position with the respective qty change and collateral
    /// @param params modify cost parameters
    /// @return modify cost result
    function modifyCostForPosition(ModifyCostParams calldata params) external returns (ModifyCostResult memory);

    /// @notice Quotes the cost to deliver an expired position
    /// @param positionId the id of an expired position
    /// @return Cost to deliver position
    function deliveryCostForPosition(PositionId positionId) external returns (uint256);
}