// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

interface ICustomBill {
    function principalToken() external view returns (address);

    function deposit(uint256 _amount, uint256 _maxPrice, address _depositor) external returns (uint256 payout);
}