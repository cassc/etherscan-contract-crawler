// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.15;

/**
* @title Interface that can be used to interact with the SnacksPool contract.
*/
interface ISnacksPool {
    function getLunchBoxParticipantsTotalSupply() external view returns (uint256);
    function isLunchBoxParticipant(address user) external view returns (bool);
    function getNotExcludedHoldersSupply() external view returns (uint256);
    function getTotalSupply() external view returns (uint256);
    function updateTotalSupplyFactor(uint256 totalSupplyBefore) external;
}