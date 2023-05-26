// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.0;

interface IPremiumPool {
    function collectPremium(address _premiumCurrency, uint256 _premiumAmount) external;

    function collectPremiumInETH() external payable;

    function withdrawPremium(
        address _currency,
        address _to,
        uint256 _amount
    ) external;
}