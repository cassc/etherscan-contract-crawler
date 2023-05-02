// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.4;

struct State {
    // a 96 fixpoint number describe the sqrt value of current price(tokenX/tokenY)
    uint160 sqrtPrice_96;
    // The current point of the pool, 1.0001 ^ currentPoint = price
    int24 currentPoint;
    // The index of the last oracle observation that was written,
    uint16 observationCurrentIndex;
    // The current maximum number of observations stored in the pool,
    uint16 observationQueueLen;
    // The next maximum number of observations, to be updated when the observation.
    uint16 observationNextQueueLen;
    // whether the pool is locked (only used for checking reentrance)
    bool locked;
    //Sum Vote fee * Liquidity
    uint240 feeTimesL;
    //current fee
    uint16 fee;
    // total liquidity on the currentPoint (currX * sqrtPrice + currY / sqrtPrice)
    uint128 liquidity;
    // liquidity of tokenX, liquidity of tokenY is liquidity - liquidityX
    uint128 liquidityX;
}

//Gas save Struct for event
struct StateEvent {
    int24 currentPoint;
    uint16 fee;
    uint128 liquidity;
    uint128 liquidityX;
}