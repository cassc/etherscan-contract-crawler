// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.13;

interface IveSCH {
    function depositFees(uint256 _amount, uint256 _period) external payable;
    function getVotingPower(address _voter) external view returns (uint256);
}