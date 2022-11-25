// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.9;

import "../libraries/LongTermOrders.sol";

interface IPair {
    function factory() external view returns (address);

    function tokenA() external view returns (address);

    function tokenB() external view returns (address);

    function rootKLast() external view returns (uint256);

    function LP_FEE() external pure returns (uint256);

    function orderBlockInterval() external pure returns (uint256);

    function reserveMap(address) external view returns (uint256);

    function tokenAReserves() external view returns (uint256);

    function tokenBReserves() external view returns (uint256);

    function getTotalSupply() external view returns (uint256);

    event InitialLiquidityProvided(
        address indexed addr,
        uint256 lpTokenAmount,
        uint256 amountA,
        uint256 amountB
    );
    event LiquidityProvided(
        address indexed addr,
        uint256 lpTokenAmount,
        uint256 amountAIn,
        uint256 amountBIn
    );
    event LiquidityRemoved(
        address indexed addr,
        uint256 lpTokenAmount,
        uint256 amountAOut,
        uint256 amountBOut
    );
    event InstantSwapAToB(
        address indexed addr,
        uint256 amountAIn,
        uint256 amountBOut
    );
    event InstantSwapBToA(
        address indexed addr,
        uint256 amountBIn,
        uint256 amountAOut
    );
    event LongTermSwapAToB(
        address indexed addr,
        uint256 amountAIn,
        uint256 orderId
    );
    event LongTermSwapBToA(
        address indexed addr,
        uint256 amountBIn,
        uint256 orderId
    );
    event CancelLongTermOrder(
        address indexed addr,
        uint256 orderId,
        uint256 unsoldAmount,
        uint256 purchasedAmount
    );
    event WithdrawProceedsFromLongTermOrder(
        address indexed addr,
        uint256 orderId,
        uint256 proceeds
    );

    function provideInitialLiquidity(
        address to,
        uint256 amountA,
        uint256 amountB
    ) external returns (uint256 lpTokenAmount);

    function provideLiquidity(
        address to,
        uint256 lpTokenAmount
    ) external returns (uint256 amountAIn, uint256 amountBIn);

    function removeLiquidity(
        address to,
        uint256 lpTokenAmount
    ) external returns (uint256 amountAOut, uint256 amountBOut);

    function instantSwapFromAToB(
        address sender,
        uint256 amountAIn
    ) external returns (uint256 amountBOut);

    function longTermSwapFromAToB(
        address sender,
        uint256 amountAIn,
        uint256 numberOfBlockIntervals
    ) external returns (uint256 orderId);

    function instantSwapFromBToA(
        address sender,
        uint256 amountBIn
    ) external returns (uint256 amountAOut);

    function longTermSwapFromBToA(
        address sender,
        uint256 amountBIn,
        uint256 numberOfBlockIntervals
    ) external returns (uint256 orderId);

    function cancelLongTermSwap(
        address sender,
        uint256 orderId
    ) external returns (uint256 unsoldAmount, uint256 purchasedAmount);

    function withdrawProceedsFromLongTermSwap(
        address sender,
        uint256 orderId
    ) external returns (uint256 proceeds);

    function getPairOrdersAmount() external view returns (uint256);

    function getOrderDetails(
        uint256 orderId
    ) external view returns (LongTermOrdersLib.Order memory);

    function getOrderRewardFactor(
        uint256 orderId
    )
        external
        view
        returns (
            uint256 orderRewardFactorAtSubmission,
            uint256 orderRewardFactorAtExpiring
        );

    function getTWAMMState()
        external
        view
        returns (
            uint256 lastVirtualOrderBlock,
            uint256 tokenASalesRate,
            uint256 tokenBSalesRate,
            uint256 orderPoolARewardFactor,
            uint256 orderPoolBRewardFactor
        );

    function getTWAMMSalesRateEnding(
        uint256 blockNumber
    )
        external
        view
        returns (
            uint256 orderPoolASalesRateEnding,
            uint256 orderPoolBSalesRateEnding
        );

    function getExpiriesSinceLastExecuted()
        external
        view
        returns (uint256[] memory);

    function userIdsCheck(
        address userAddress
    ) external view returns (uint256[] memory);

    function orderIdStatusCheck(uint256 orderId) external view returns (bool);

    function executeVirtualOrders(uint256 blockNumber) external;
}