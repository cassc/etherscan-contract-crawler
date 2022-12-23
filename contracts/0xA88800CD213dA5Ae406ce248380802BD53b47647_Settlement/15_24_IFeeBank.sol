// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

interface IFeeBank {
    function deposit(uint256 amount) external returns (uint256 totalAvailableCredit);
}