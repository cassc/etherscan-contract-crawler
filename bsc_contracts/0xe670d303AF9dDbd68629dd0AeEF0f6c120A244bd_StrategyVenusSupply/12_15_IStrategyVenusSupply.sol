// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.17;

interface IStrategyVenusSupply {
     function deposit(address[] memory pathTokenInToWant) external returns (uint256);

    function withdraw(uint256 _amountVUSDC, address[] memory _pathWantToTokenOut, address[] memory _nonUsed) external returns (uint256);

    function withdrawAll() external;

    function autocompound() external;

    ///@dev Emitted when deposit is called.
    event Deposited(uint256 amountDeposited, uint256 amountMinted);

    ///@dev Emitted when reards get autocompounded.
    event Compounded(uint256 rewardAmount, uint256 amountMinted, uint256 fee, uint256 time);

    ///@dev Emtted when withdrawal is called.
    event Withdrawn(uint256 amount);

    event WithdrawnAll(uint256 amount);
}