// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.13;

interface IVault {
    function setBalance(address _voter, uint256 _amount) external;
    function deposit(uint256 _amount) external;
    function claimFees(address _voter) external returns (uint256);
}