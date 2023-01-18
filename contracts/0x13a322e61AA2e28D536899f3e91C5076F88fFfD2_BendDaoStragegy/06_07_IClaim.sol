pragma solidity ^0.8.2;

interface IClaim {
	function claimRewards(address[] calldata _assets, uint256 _amount) external returns (uint256);
	function getUserUnclaimedRewards(address _user) external view returns (uint256);
	function getRewardsBalance(address[] calldata _assets, address _user) external view returns (uint256);
}