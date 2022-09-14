// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

interface ILiquidityManager {
    function repartitionCalculation(
        bool _isSelling,
        bool _isBuying,
        uint256 _amount
    ) external returns (uint256, uint256);

    function updateBuyFees(uint256 _burnFee, uint256 _devFee) external;

    function updateSellFees(uint256 _burnFee, uint256 _devFee) external;

    function updateTokenAddress(address _newAddr) external;
}