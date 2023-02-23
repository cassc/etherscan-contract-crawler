// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.17;

interface IStrategyPancake {

    function deposit(address[] memory pathTokenInToToken0) external returns (uint256);

    function withdraw(uint256 _amountLP, address[] memory token0toTokenOut, address[] memory token1toTokenOut) external returns (uint256);

    function withdrawAll() external;

    function autocompound() external;

    ///@dev Emitted when deposit is called.
    event Deposited(uint256 amount);

    ///@dev Emitted when reards get autocompounded.
    event Compounded(uint256 rewardAmount, uint256 fee, uint256 time);

    ///@dev Emtted when withdrawal is called.
    event Withdrawn(uint256 amountLP, uint256 amountBaseToken);
}