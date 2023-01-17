// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IMFSwap {
    function swap(uint256 _amount, address _investor) external;
}