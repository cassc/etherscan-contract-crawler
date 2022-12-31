// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
interface IInvestment {
    function updateDepositAmountTotal(uint256 _amount) external;
    function updateWithdrawalAmountTotal(uint256 _amount) external;
}