// SPDX-License-Identifier: MIT

pragma solidity 0.6.11;

interface IBalancerPool {
    event Approval(address indexed src, address indexed dst, uint amt);
    event Transfer(address indexed src, address indexed dst, uint amt);

    function totalSupply() external view returns (uint);
    function balanceOf(address whom) external view returns (uint);
    function allowance(address src, address dst) external view returns (uint);

    function approve(address dst, uint amt) external returns (bool);
    function transfer(address dst, uint amt) external returns (bool);
    function transferFrom(
        address src, address dst, uint amt
    ) external returns (bool);
        
    function joinPool(uint poolAmountOut, uint[] calldata maxAmountsIn) external;   
    function exitPool(uint poolAmountIn, uint[] calldata minAmountsOut) external;

    function getBalance(address token) external view returns (uint);

    function decimals() external view returns(uint8);

    function isFinalized() external view returns (bool);

    function getFinalTokens()
        external view        
        returns (address[] memory tokens);
}