// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

interface IStrategy {
    function deposit() external;

    function withdraw(address _to, address _asset) external;

    function withdraw(address _to, uint256 _amount) external;

    function withdrawAll() external;

    function totalAssets() external view returns (uint256);
}