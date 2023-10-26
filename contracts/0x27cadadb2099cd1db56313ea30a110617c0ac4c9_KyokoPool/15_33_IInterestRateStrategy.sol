// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.18;

import "../libraries/utils/DataTypes.sol";

interface IInterestRateStrategy {
    event SetMinBorrowTime(uint40 newTime);

    event VariableRateUpdated(
        uint256 indexed reserveId,
        uint256 newBaseStableRate,
        uint256 newVariableSlope1,
        uint256 newVariableSlope2
    );

    event StableRateUpdated(
        uint256 indexed reserveId,
        uint256 newBaseStableRate,
        uint256 newVariableSlope1,
        uint256 newVariableSlope2
    );

    event AddNewRate(uint256 reserveId);

    function getRate(uint256 reserveId)
        external
        view
        returns (DataTypes.Rate memory);

    function getMaxVariableBorrowRate(uint256 reserveId)
        external
        view
        returns (uint256);

    function calculateInterestRates(
        uint256 reserveId,
        address reserve,
        address kToken,
        uint256 liquidityAdded,
        uint256 liquidityTaken,
        uint256 totalStableDebt,
        uint256 totalVariableDebt,
        uint256 averageStableBorrowRate,
        uint256 reserveFactor
    )
        external
        view
        returns (
            uint256,
            uint256,
            uint256
        );

    function calculateInterestRates(
        DataTypes.Rate memory rate,
        uint256 availableLiquidity,
        uint256 totalStableDebt,
        uint256 totalVariableDebt,
        uint256 averageStableBorrowRate,
        uint256 reserveFactor
    )
        external
        view
        returns (
            uint256,
            uint256,
            uint256
        );
    
    function setRate(
        uint256 reserveId,
        uint256 _optimalUtilizationRate,
        uint256 _baseVariableBorrowRate,
        uint256 _variableSlope1,
        uint256 _variableSlope2,
        uint256 _baseStableBorrowRate,
        uint256 _stableSlope1,
        uint256 _stableSlope2
    ) external;

    function setVariableRate(
        uint256 reserveId,
        uint256 _baseVariableRate,
        uint256 _variableSlope1,
        uint256 _variableSlope2
    ) external;

    function setStableRate(
        uint256 reserveId,
        uint256 _baseStableRate,
        uint256 _stableSlope1,
        uint256 _stableSlope2
    ) external;
}