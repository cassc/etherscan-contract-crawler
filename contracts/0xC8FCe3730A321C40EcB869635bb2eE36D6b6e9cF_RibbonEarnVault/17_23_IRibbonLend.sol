// SPDX-License-Identifier: MIT
pragma solidity =0.8.4;

interface IRibbonLend {
    function balanceOf(address account) external view returns (uint256);

    function getCurrentExchangeRate() external view returns (uint256);

    function redeem(uint256 tokens) external;

    function redeemCurrency(uint256 currencyAmount) external;

    function provide(uint256 currencyAmount, address referral) external;
}