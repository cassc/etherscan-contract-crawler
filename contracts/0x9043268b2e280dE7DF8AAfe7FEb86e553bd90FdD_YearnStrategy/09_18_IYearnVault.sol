// SPDX-License-Identifier: MIT
pragma solidity =0.8.10;

interface IYearnVault {
    function deposit(uint256 amount, address recipient)
        external
        returns (uint256);

    function pricePerShare() external view returns (uint256);

    function withdraw(
        uint256 maxShares,
        address recipient,
        uint256 maxLoss
    ) external returns (uint256);

    function totalAssets() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function decimals() external view returns (uint256);
}