//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "../libraries/DataTypes.sol";

interface IFeeModel {
    /// @notice Calculates fees for a given trade
    /// @param trader The trade trader
    /// @param positionId The trade position id
    /// @param cost The trade cost
    /// @return calculatedFee The calculated fee of the trade cost
    function calculateFee(address trader, PositionId positionId, uint256 cost)
        external
        view
        returns (uint256 calculatedFee);
}