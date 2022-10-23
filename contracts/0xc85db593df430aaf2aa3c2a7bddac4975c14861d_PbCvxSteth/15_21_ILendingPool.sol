// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface ILendingPool {
    function deposit(
        address asset,
        uint256 amount,
        address onBehalfOf,
        uint16 referralCode
    ) external;

    function withdraw(
        address asset,
        uint256 amount,
        address to
    ) external returns (uint256);

    function getReserveData(address asset) external view returns (
        uint,
        uint128,
        uint128,
        uint128,
        uint128,
        uint128,
        uint40,
        address,
        address,
        address,
        address,
        uint8
    );
}