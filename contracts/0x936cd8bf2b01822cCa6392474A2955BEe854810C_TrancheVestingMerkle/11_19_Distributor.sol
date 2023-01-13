// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import { IDistributor, DistributionRecord } from "../interfaces/IDistributor.sol";

abstract contract Distributor is IDistributor, ReentrancyGuard {
	using SafeERC20 for IERC20;

	mapping(address => DistributionRecord) internal records; // track distribution records per user
	IERC20 public token; // the token being claimed
	uint256 public total; // total tokens allocated for claims
	uint256 public claimed; // tokens already claimed
	string public uri; // ipfs link on distributor info
	uint256 immutable fractionDenominator; // denominator for vesting fraction (e.g. if vested fraction is 100 and fractionDenominator is 10000, 1% of tokens have vested)

	// provide context on the contract name and version
	function NAME() external virtual returns (string memory);

	function VERSION() external virtual returns (uint256);

	constructor(
		IERC20 _token,
		uint256 _total,
		string memory _uri,
		uint256 _fractionDenominator
	) {
		require(address(_token) != address(0), "Distributor: token is address(0)");
		require(_total > 0, "Distributor: total is 0");

		token = _token;
		total = _total;
		uri = _uri;
		fractionDenominator = _fractionDenominator;
		emit InitializeDistributor(token, total, uri, fractionDenominator);
	}

	function _initializeDistributionRecord(address beneficiary, uint256 amount) internal {
		// CALLER MUST VERIFY THE BENEFICIARY AND AMOUNT ARE VALID!

		// Checks
		require(amount <= type(uint120).max, "Distributor: amount > type(uint120).max");
		require(amount > 0, "Distributor: amount == 0");
		require(!records[beneficiary].initialized, "Distributor: already initialized");

		// Effects
		records[beneficiary] = DistributionRecord(true, uint120(amount), 0);
		emit InitializeDistributionRecord(beneficiary, amount);
	}

	function _executeClaim(address beneficiary, uint256 _amount) internal {
		// Checks: NONE! THIS FUNCTION DOES NOT CHECK PERMISSIONS: CALLER MUST VERIFY THE CLAIM IS VALID!
		uint120 amount = uint120(_amount);
		require(amount > 0, "Distributor: no more tokens claimable right now");

		// effects
		records[beneficiary].claimed += amount;
		claimed += amount;

		// interactions
		token.safeTransfer(beneficiary, amount);
		emit Claim(beneficiary, amount);
	}

	function getDistributionRecord(address beneficiary)
		external
		view
		virtual
		returns (DistributionRecord memory)
	{
		return records[beneficiary];
	}

	// Get tokens vested as fraction of fractionDenominator
	function getVestedFraction(address beneficiary, uint256 time)
		public
		view
		virtual
		returns (uint256);

	function getFractionDenominator() public view returns (uint256) {
		return fractionDenominator;
	}

	// get the number of tokens currently claimable by a specific use
	function getClaimableAmount(address beneficiary) public view virtual returns (uint256) {
		require(records[beneficiary].initialized, "Distributor: claim not initialized");

		DistributionRecord memory record = records[beneficiary];

		uint256 claimable = (record.total * getVestedFraction(beneficiary, block.timestamp)) /
			fractionDenominator;
		return
			record.claimed >= claimable
				? 0 // no more tokens to claim
				: claimable - record.claimed; // claim all available tokens
	}
}