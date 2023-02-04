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
    /// @param collateral How much quote ccy the user will post, if the value is too big/small, a calculated max/min will be used instead
    /// @return opening cost result
    /// Will either be the same as minCollateral in case the collateral passed is insufficient, the same as the collateral passed or capped to the maximum collateralisation possible
    function openingCostForPositionWithCollateral(OpeningCostParams calldata params, uint256 collateral)
        external
        returns (ModifyCostResult memory);

    /// @notice Quotes the cost to open a position with the respective leverage used
    /// @param params opening cost parameters
    /// @param leverage Ratio between collateral and debt, if the value is too big/small, a calculated max/min will be used instead. 18 decimals number, 1e18 = 1x
    /// @return opening cost result
    /// Will either be the same as minCollateral in case the collateral passed is insufficient, the same as the collateral passed or capped to the maximum collateralisation possible
    function openingCostForPositionWithLeverage(OpeningCostParams calldata params, uint256 leverage)
        external
        returns (ModifyCostResult memory);

    /// @notice Quotes the cost to modify a position with the respective qty change and collateral
    /// @param params modify cost parameters
    /// @param collateral How much the collateral of the position should change by, if the value is too big/small, a calculated max/min will be used instead
    /// @return modify cost result
    function modifyCostForPositionWithCollateral(ModifyCostParams calldata params, int256 collateral)
        external
        returns (ModifyCostResult memory);

    /// @notice Quotes the cost to modify a position with the respective qty change and leverage
    /// @param params modify cost parameters
    /// @param leverage Ratio between collateral and debt, if the value is too big/small, a calculated max/min will be used instead. 18 decimals number, 1e18 = 1x
    /// @return modify cost result
    function modifyCostForPositionWithLeverage(ModifyCostParams calldata params, uint256 leverage)
        external
        returns (ModifyCostResult memory);

    /// @notice Quotes the cost to deliver an expired position
    /// @param positionId the id of an expired position
    /// @return Cost to deliver position
    function deliveryCostForPosition(PositionId positionId) external returns (uint256);
}