// SPDX-License-Identifier: MIT

pragma solidity 0.8.11;

interface IYearnTokenVault {
    function balanceOf(address user) external view returns (uint256);

    function pricePerShare() external view returns (uint256);

    function deposit(uint256 lp, address user) external;

    function withdraw(
        uint256 amount,
        address user,
        uint256 slippage
    ) external;

    function decimals() external view returns (uint8);
}