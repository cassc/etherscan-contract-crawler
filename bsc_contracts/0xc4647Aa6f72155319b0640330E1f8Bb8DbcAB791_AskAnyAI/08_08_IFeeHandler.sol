// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IFeeHandler {
    function getFeeInfo(address sender, address recipient, uint256 amount) external returns (uint256);

    function onFeeReceived(address sender, address recipient, uint256 amount, uint256 fee) external;
}