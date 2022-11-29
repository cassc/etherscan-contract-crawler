// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface IInterestRateModel {
    function getBorrowRate(
        uint256 balance,
        uint256 totalBorrows,
        uint256 totalReserves
    ) external view returns (uint256);

    function utilizationRate(
        uint256 balance,
        uint256 borrows,
        uint256 reserves
    ) external pure returns (uint256);

    function getSupplyRate(
        uint256 balance,
        uint256 borrows,
        uint256 reserves,
        uint256 reserveFactor
    ) external view returns (uint256);

    function kink() external view returns (uint256);
}