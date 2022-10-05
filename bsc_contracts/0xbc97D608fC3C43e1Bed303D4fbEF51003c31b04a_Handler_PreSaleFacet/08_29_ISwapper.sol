// SPDX-License-Identifier: BSD-3-Clause

pragma solidity ^0.8.0;

interface ISwapper {
	function swapCreateNodesWithTokens(
		address tokenIn, 
		address user, 
		uint price,
		string memory sponso
	) external;
	
	function swapCreateNodesWithPending(
		address tokenOut, 
		address user, 
		uint rewardsTotal, 
		uint feesTotal
	) external;
	
	function swapCreateLuckyBoxesWithTokens(
		address tokenIn, 
		address user, 
		uint price,
		string memory sponso
	) external;

	function swapClaimRewardsAll(
		address tokenOut, 
		address user, 
		uint rewardsTotal, 
		uint feesTotal
	) external;

	function swapClaimRewardsBatch(
		address tokenOut, 
		address user, 
		uint rewardsTotal, 
		uint feesTotal
	) external;
	
	function swapClaimRewardsNodeType(
		address tokenOut, 
		address user, 
		uint rewardsTotal, 
		uint feesTotal
	) external;

	function swapApplyWaterpack(
		address tokenIn,
		address user,
		uint amount,
		string memory sponso
	) external;

	function swapApplyFertilizer(
		address tokenIn,
		address user,
		uint amount,
		string memory sponso
	) external;

	function swapNewPlot(
		address tokenIn,
		address user,
		uint amount,
		string memory sponso
	) external;
}