// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

interface ILSDRPVault {
    function depositEther() external payable;

    function getBalanceOfRocketToken() external view returns (uint256);

    function getETHBalance() external view returns (uint256);

    function withdrawEther(uint256 _ethAmount) external;
}