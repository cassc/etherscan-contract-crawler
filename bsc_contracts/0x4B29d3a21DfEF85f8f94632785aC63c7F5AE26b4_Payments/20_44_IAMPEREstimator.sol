// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

interface IAMPEREstimator {
    
    function estimateAmountOut(uint _userId, uint _amountIn) external view returns(uint, uint);

    function estimateOnceBonus(uint _userId, uint _amountIn) external view returns(uint);

    function giveOnceBonus(uint _userId, uint _amountOut) external returns(uint);

}