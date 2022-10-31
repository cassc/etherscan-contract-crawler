// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.11;

interface ITreasuryManager {
    function estimateFees(
        bool _isSelling,
        bool _isBuying,
        uint256 _amount
    ) external returns (uint256, uint256);

    function updateBuyFees(uint256 _burnFee) external;

    function updateSellFees(uint256 _burnFee) external;

    function updateTreasuryFees(uint256 _treasuryFees) external;

    function updateTokenAddress(address _newAddr) external;
}