// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

interface IMPartyRewardsDistributor {
	function claimRewardsForNftsHeld(uint256[] calldata ids) external;
    function calcNftHoldingRewards(uint256[] calldata ids) external view returns (uint256 rewards);
}