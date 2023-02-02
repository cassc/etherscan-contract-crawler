// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.14;


interface IYtri {
    function deposit(uint256 amount) external;
    function withdraw(uint256 amount) external;
    function balanceOf(address account) external view returns (uint256);
    function pricePerShare() external view returns (uint256);
}