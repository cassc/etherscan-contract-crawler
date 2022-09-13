// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.6;
pragma abicoder v2;

interface IVault {
    function setBalance(address _voter, uint256 _amount) external;
    function deposit(uint256 _amount) external;
    function claimUSDH(address _voter) external returns (uint256);
}