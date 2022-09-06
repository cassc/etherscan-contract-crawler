pragma solidity ^0.8.2;

interface IClaim {
	function claimRewards(address[] calldata _assets, uint256 _amount) external returns (uint256);
}