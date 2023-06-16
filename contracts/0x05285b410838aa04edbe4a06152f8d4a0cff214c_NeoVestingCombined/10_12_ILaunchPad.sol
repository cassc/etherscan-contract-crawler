// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

interface ILaunchPad{
    // func getProjectInfo
    function projectToLaunchpads(string memory)external  view returns (
        uint256 startTime,
        uint256 endTime,
        uint256 entryPrice,
        uint256 minAllocation,
        uint256 maxAllocation,
        uint256 initialPrice,
        address depositFundAddress,
        uint256 hardcap,
        uint256 totalDeposited,
        address depositCurrency);
    function projectDeposits(string memory,address) external view returns(
        uint256 depositedTime,
        uint256 depositedAmount,
        uint256 claimableAmount
    );
}