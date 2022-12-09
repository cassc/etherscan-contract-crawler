// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface IStrategy {
    function totalAssets() external view returns (uint256);

    function deposit(address user, uint256 amount) external;

    function withdraw(address user, uint256 amount) external;

    function withdrawFee()
        external
        view
        returns (address recipient, uint256 percent);
}