// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.5;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ISportsIconPrivateVesting {

	event LogTokensClaimed(address claimer, uint256 tokensClaimed);

	function token() external view returns(IERC20);
	function vestedTokensOf(address) external view returns(uint256);
	function claimedOf(address) external view returns(uint256);

	function freeTokens(address) external view returns(uint256);

	function claim() external returns(uint256);

}