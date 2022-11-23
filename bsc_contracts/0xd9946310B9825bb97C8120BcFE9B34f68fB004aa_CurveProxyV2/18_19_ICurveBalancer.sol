// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

interface ICurveBalancer {

    function addLiqBalancedOut(
        address pool,
        uint256 slotsCount,
        uint256 incomePosition,
        uint256 amountIn
    ) external returns (bool success);

    function removeLiqBalancedOut(
        address pool,
        address lp,
        uint256 slotsCount,
        uint256 incomePosition,
        uint256 amountInLp
    ) external returns (bool success);

}