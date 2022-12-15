// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IPoolHelper {
    function wombatStaking() external view returns (address);

    function lpToken() external view returns (address);

    function totalStaked() external view returns (uint256);

    function balance(address _address) external view returns (uint256);

    function deposit(uint256 amount, uint256 minimumAmount) external;

    function withdraw(uint256 amount, uint256 minimumAmount) external;
}