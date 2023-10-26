// SPDX-License-Identifier: MIT

pragma solidity 0.8.12;

interface IBountyManager {
	function quote(address _param) external returns (uint256 bounty);

	function claim(address _param) external returns (uint256 bounty);

	function minDLPBalance() external view returns (uint256 amt);

	function executeBounty(
		address _user,
		bool _execute,
		uint256 _actionType
	) external returns (uint256 bounty, uint256 actionType);
}