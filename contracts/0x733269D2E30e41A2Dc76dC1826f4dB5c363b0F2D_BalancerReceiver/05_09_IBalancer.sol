// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IBalancer {
    function flashLoan(
        address recipient,
        address[] calldata tokens,
        uint256[] calldata amounts,
        bytes calldata userData
    ) external;

    function getFlashLoanFeePercentage() external view returns (uint256); //18 decimal
}