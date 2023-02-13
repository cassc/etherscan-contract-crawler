// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "../LimitOrderSwapRouter.sol";

interface ILimitOrderQuoter {
    function findBestTokenToTokenExecutionPrice(
        LimitOrderSwapRouter.TokenToTokenExecutionPrice[]
            memory executionPrices,
        bool buyOrder
    ) external pure returns (uint256 bestPriceIndex);

    function simulateTokenToTokenPriceChange(
        uint128 alphaX,
        LimitOrderSwapRouter.TokenToTokenExecutionPrice memory executionPrice
    ) external returns (LimitOrderSwapRouter.TokenToTokenExecutionPrice memory);

    function simulateTokenToWethPriceChange(
        uint128 alphaX,
        LimitOrderSwapRouter.TokenToWethExecutionPrice memory executionPrice
    ) external returns (LimitOrderSwapRouter.TokenToWethExecutionPrice memory);

    function findBestTokenToWethExecutionPrice(
        LimitOrderSwapRouter.TokenToWethExecutionPrice[] memory executionPrices,
        bool buyOrder
    ) external pure returns (uint256 bestPriceIndex);

    function calculateAmountOutMinAToWeth(
        address lpAddressAToWeth,
        uint256 amountInOrder,
        uint16 taxIn,
        uint24 feeIn,
        address tokenIn
    ) external returns (uint256 amountOutMinAToWeth);

    function initializeTokenToWethExecutionPrices(
        LimitOrderSwapRouter.SpotReserve[] memory spotReserveAToWeth,
        address[] memory lpAddressesAToWeth
    )
        external
        view
        returns (LimitOrderSwapRouter.TokenToWethExecutionPrice[] memory);

    function initializeTokenToTokenExecutionPrices(
        address tokenIn,
        LimitOrderSwapRouter.SpotReserve[] memory spotReserveAToWeth,
        address[] memory lpAddressesAToWeth,
        LimitOrderSwapRouter.SpotReserve[] memory spotReserveWethToB,
        address[] memory lpAddressWethToB
    )
        external
        view
        returns (LimitOrderSwapRouter.TokenToTokenExecutionPrice[] memory);
}