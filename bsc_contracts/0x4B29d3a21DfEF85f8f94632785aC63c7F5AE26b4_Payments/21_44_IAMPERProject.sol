// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

interface IAMPERProject {
    
    function distributed() external view returns(uint);
    
    function estimateAmountOut(uint _userId, uint _amountIn) external view returns(uint, uint);
    
    function estimateAmountIn(uint _userId, uint _amountOut) external view returns(uint, uint);

}