// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IDepositBUSD {
    function pause() external;

    function unpause() external;

    function updateTreasury(address _newTreasury) external;

    function updateBUSD(address _busd) external;

    function updateMinDeposit(uint256 _min) external;

    function depositAsset(
        string calldata _userId,
        uint256 _amountIn,
        uint256 _assetOut
    ) external;

    event DepositBUSD(
        string userId,
        address indexed treasury,
        address indexed assetIn,
        uint256 amountIn,
        uint256 assetOut
    );
}