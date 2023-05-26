pragma solidity 0.8.19;

// SPDX-License-Identifier: MIT

interface IDCAStrategy {
    function fill(
        address tokenA,
        address tokenB,
        uint32 period,
        bytes memory params
    ) external;

    function deposit(
        address tokenA,
        address tokenB,
        uint32 period,
        uint amount,
        uint64 numRounds
    ) external payable;

    function withdraw(
        address tokenA,
        address tokenB,
        uint32 period,
        bool onlyFilled,
        bool unwrapEth,
        address feeToken
    ) external;

    function modify(
        address tokenA,
        address tokenB,
        uint32 period,
        uint amount,
        uint32 newPeriod,
        uint64 numRounds,
        bool unwrapEth,
        address feeToken
    ) external payable;

    function getAmounts(
        address tokenA,
        address tokenB,
        uint32 period,
        address user
    ) external view returns (uint, uint);

    function getFillPair(
        address tokenA,
        address tokenB,
        uint32 period,
        uint round
    ) external view returns (
        address tokenToFill,
        uint nettAmountToFill,
        uint rate,
        uint totalAmountA,
        uint totalAmountB,
        uint tokenADecimals
    );

    function currentRoundMap(
        address tokenA,
        address tokenB,
        uint32 period
    ) external view returns (
        uint64 round
    );

    function amountToDeductMap(
        address tokenA,
        address tokenB,
        uint32 period,
        uint roundNumber
    ) external view returns (
        uint amountToDeduct
    );

    function numPairs() external view returns (
        uint32 numPairs
    );

    function pairIdMap(
        uint pairId
    ) external view returns (
        address tokenA,
        address tokenB,
        uint8 decimalA,
        uint8 decimalB,
        uint32 period
    );

    function amountToFillMap(
        address tokenA,
        address tokenB,
        uint32 period
    ) external view returns (
        uint amountToFill
    );

    function pairDataMap(
        address tokenA,
        address tokenB,
        uint32 period
    ) external view returns (
        uint pairId
    );

    function lastFillTime(
        address tokenA,
        address tokenB,
        uint32 period
    ) external view returns (
        uint lastFillTime
    );

    function fillingFee() external view returns (
        uint fillingFee
    );
}