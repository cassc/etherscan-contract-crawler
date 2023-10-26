// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface IRepaymentController {
    function repay(uint256 loanId) external;
}