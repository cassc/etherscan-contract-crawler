// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

struct DistributionRecord {
	bool initialized; // has the claim record been initialized
	uint120 total; // total token quantity claimable
	uint120 claimed; // token quantity already claimed
}

interface IDistributor {
	event InitializeDistributor(
		IERC20 indexed token,
		uint256 total,
		string uri,
		uint256 fractionDenominator
	);
	event InitializeDistributionRecord(address indexed beneficiary, uint256 amount);
	event Claim(address indexed beneficiary, uint256 amount);

	function getDistributionRecord(address beneficiary)
		external
		view
		returns (DistributionRecord memory);

	function getClaimableAmount(address beneficiary) external view returns (uint256);

	function getFractionDenominator() external view returns (uint256);

	function token() external view returns (IERC20);
	
	function total() external view returns (uint256);

	function uri() external view returns (string memory);

	function NAME() external view returns (string memory);

	function VERSION() external view returns (uint256);
}