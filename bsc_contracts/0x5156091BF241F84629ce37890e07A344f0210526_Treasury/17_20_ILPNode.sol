// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

interface ILPNode {
    function getPoolBalance() external view returns (uint256);
    function getTotalDeposited() external view returns (uint256);
    function getTotalClaimed() external view returns (uint256);
    function getTotalUsers() external view returns (uint256);
    function deposit(uint256 amount) external;
    function compound() external;
    function claim() external;
    function getEstimateMedalToken(uint256 _amount) external view returns (uint256);
}