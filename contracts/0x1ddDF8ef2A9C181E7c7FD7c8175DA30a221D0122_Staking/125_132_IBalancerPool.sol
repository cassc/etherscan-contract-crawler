// SPDX-License-Identifier: MIT

pragma solidity 0.6.11;

/// @title Interface for a Balancer Labs BPool
/// @dev https://docs.balancer.fi/v/v1/smart-contracts/interfaces
interface IBalancerPool {
    event Approval(address indexed src, address indexed dst, uint256 amt);
    event Transfer(address indexed src, address indexed dst, uint256 amt);

    function totalSupply() external view returns (uint256);

    function balanceOf(address whom) external view returns (uint256);

    function allowance(address src, address dst) external view returns (uint256);

    function approve(address dst, uint256 amt) external returns (bool);

    function transfer(address dst, uint256 amt) external returns (bool);

    function transferFrom(
        address src,
        address dst,
        uint256 amt
    ) external returns (bool);

    function joinPool(uint256 poolAmountOut, uint256[] calldata maxAmountsIn) external;

    function exitPool(uint256 poolAmountIn, uint256[] calldata minAmountsOut) external;

    function getBalance(address token) external view returns (uint256);

    function decimals() external view returns (uint8);

    function isFinalized() external view returns (bool);

    function getFinalTokens() external view returns (address[] memory tokens);
}