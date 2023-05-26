pragma solidity ^0.6.12;

interface IVesting {
	function ygg() external view returns(address);

	function vehicules(address _user, uint256 _index) external view returns (
		uint256 start,
		uint256 end,
		uint256 upfront,
		uint256 amount,
		uint256 claimed,
		uint256 claimedUpfront);
	function vehiculeCount(address _user) external view returns (uint256);
	function claim(uint256 _index) external;
	function pendingReward(address _user, uint256 _index) external view returns(uint256);
	function claimed(address _user, uint256 _index) external view returns(uint256);
}