// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IDAOInvestors {
    function vestingDeposit(
        uint256 amount,
        address investor,
        uint256 vestingDuration,
        uint256 vestingStartDate
    ) external;
}