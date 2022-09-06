// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IAPPLESlice {
    function burnAPPLESlice(address _staker, uint256 _amount) external;
    function mintAPPLESlice(address _depositor, uint256 amount) external;
}