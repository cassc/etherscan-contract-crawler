// SPDX-License-Identifier: MIT

pragma solidity ^0.8.14;

interface ICommunityIssuance {
	// --- Events ---

	event MONTokenAddressSet(address _MONTokenAddress);
	event StabilityPoolAddressSet(address _stabilityPoolAddress);
	event TotalMONIssuedUpdated(address indexed stabilityPool, uint256 _totalMONIssued);

	// --- Functions ---

	function setAddresses(
		address _MONTokenAddress,
		address _stabilityPoolAddress,
		address _adminContract
	) external;

	function issueMON() external returns (uint256);

	function sendMON(address _account, uint256 _MONamount) external;

	function addFundToStabilityPool(address _pool, uint256 _assignedSupply) external;

	function addFundToStabilityPoolFrom(
		address _pool,
		uint256 _assignedSupply,
		address _spender
	) external;

	function transferFundToAnotherStabilityPool(
		address _target,
		address _receiver,
		uint256 _quantity
	) external;

	function setWeeklyDfrancDistribution(address _stabilityPool, uint256 _weeklyReward) external;
}