//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

interface IUniswapV2Pair {
    function balanceOf(address account) external view returns (uint256);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function approve(address spender, uint256 amount) external;
    function totalSupply() external view returns (uint256);
}

interface IMasterChef {
    function userInfo(uint256 _1, address _2) external view returns (uint256 amount, int256 rewardDebt);
    function deposit(uint256 pid, uint256 amount, address to) external;
}

interface IUniswapV2Router02 {
    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external payable returns (uint256 amountToken, uint256 amountETH, uint256 liquidity);
}