// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

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
    ) external;

    function getReserveData(address asset) external view returns (
        uint,
        uint128,
        uint128,
        uint128,
        uint128,
        uint128,
        uint40,
        address
        // comment out subsequent return value to aviod stack too deep error
        // address,
        // address,
        // address,
        // uint8
    );
}