// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IPYESlice {
    function burnPYESlice(address _staker, uint256 _amount) external;
    function mintPYESlice(address _depositor, uint256 amount) external;
}