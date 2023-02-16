// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ICurrency {
    function currencyState(address _contractERC20) external returns (bool);
}