//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.19;

interface IInterestRate {
    event TokenAdded(
        address indexed token,
        uint256 optimalUtilizationRate,
        uint256 baseBorrowRate,
        uint256 lowSlope,
        uint256 highSlope
    );
    event TokenRemoved(address indexed token);

    event InterestRateConfigSet(
        address indexed token,
        uint256 optimalUtilizationRate,
        uint256 baseBorrowRate,
        uint256 lowSlope,
        uint256 highSlope,
        uint256 optimalBorrowRate
    );

    function calculateBorrowRate(
        address token,
        uint256 assets,
        uint256 debt
    ) external view returns (uint256);

    function calculateUtilizationRate(
        address token,
        uint256 assets,
        uint256 debt
    ) external view returns (uint256);

    function isTokenSupported(address token) external view returns (bool);
}