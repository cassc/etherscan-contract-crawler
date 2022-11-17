// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

// For interacting with our own strategy
interface IStrategy {
	function stakedToken() external view returns (IERC20);

	function earnedToken() external view returns (IERC20);

	function stakedTokenPrice() external view returns (uint256);

	// Total staked tokens managed by strategy
	function stakedLockedTotal() external view returns (uint256);

	// Main staked token compounding function
	function earn() external;

	// Transfer want tokens ChargeMaster -> IFOStrategy
	function deposit(uint256 _amount) external returns (uint256);

	// Transfer want tokens IFOStrategy -> ChargeMaster
	function withdraw(uint256 _amount) external returns (uint256);

	function recoverWrongTokens(address _tokenAddress, uint256 _tokenAmount)
		external;
}