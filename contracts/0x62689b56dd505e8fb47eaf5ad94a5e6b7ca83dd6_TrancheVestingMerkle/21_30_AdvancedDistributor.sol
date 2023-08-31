// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "@openzeppelin/contracts/access/Ownable.sol";
import { ERC20Votes, ERC20Permit, ERC20 } from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import { Distributor, DistributionRecord, IERC20 } from "./Distributor.sol";
import { IAdjustable } from "../../interfaces/IAdjustable.sol";
import { IVoting } from "../../interfaces/IVoting.sol";
import { Sweepable } from "../../utilities/Sweepable.sol";

abstract contract AdvancedDistributor is Ownable, Sweepable, ERC20Votes, Distributor, IAdjustable, IVoting {
	using SafeERC20 for IERC20;

	uint256 private voteFactor;

	constructor(
		IERC20 _token,
		uint256 _total,
		string memory _uri,
		uint256 _voteFactor,
		uint256 _fractionDenominator
	) Distributor(_token, _total, _uri, _fractionDenominator) ERC20Permit("Internal vote tracker") ERC20("Internal vote tracker", "IVT") Sweepable(payable(msg.sender)) {
		voteFactor = _voteFactor;
		emit SetVoteFactor(voteFactor);
	}

	function tokensToVotes(uint256 tokenAmount) private view returns (uint256) {
		// convert a token quantity to a vote quantity
		return tokenAmount * voteFactor / fractionDenominator;
	}

	function _initializeDistributionRecord(address beneficiary, uint256 totalAmount) internal override {
		super._initializeDistributionRecord(beneficiary, totalAmount);

		// add voting power through ERC20Votes extension
		_mint(beneficiary, tokensToVotes(totalAmount));
	}

	function _executeClaim(address beneficiary, uint256 totalAmount) internal override returns (uint256 _claimed) {
		_claimed = super._executeClaim(beneficiary, totalAmount);

		// reduce voting power through ERC20Votes extension
		_burn(beneficiary, tokensToVotes(_claimed));
	}

	function adjust(address beneficiary, int256 amount) external onlyOwner {
		DistributionRecord memory distributionRecord = records[beneficiary];
		require(distributionRecord.initialized, "must initialize before adjusting");

		uint256 diff = uint256(amount > 0 ? amount : -amount);
		require(diff < type(uint120).max, "adjustment > max uint120");

		if (amount < 0) {
			// decreasing claimable tokens
			require(total >= diff, "decrease greater than distributor total");
			require(distributionRecord.total >= diff, "decrease greater than distributionRecord total");
			total -= diff;
			records[beneficiary].total -= uint120(diff);
			token.safeTransfer(owner(), diff);
			// reduce voting power
			_burn(beneficiary, tokensToVotes(diff));
		} else {
			// increasing claimable tokens
			total += diff;
			records[beneficiary].total += uint120(diff);
			// increase voting pwoer
			_mint(beneficiary, tokensToVotes(diff));
		}

		emit Adjust(beneficiary, amount);
	}

	// Set the token being distributed
	function setToken(IERC20 _token) external onlyOwner {
		require(address(_token) != address(0), "Adjustable: token is address(0)");
		token = _token;
		emit SetToken(token);
	}

	// Set the total to distribute
	function setTotal(uint256 _total) external onlyOwner {
		total = _total;
		emit SetTotal(total);
	}

	// Set the distributor metadata URI
	function setUri(string memory _uri) external onlyOwner {
		uri = _uri;
		emit SetUri(uri);
	}

	// set the recipient of swept funds
	function setSweepRecipient(address payable _recipient) external onlyOwner {
		_setSweepRecipient(_recipient);
	}

	function getTotalVotes() external view returns (uint256) {
		// supply of internal token used to track voting power
		return totalSupply();
	}

	function getVoteFactor(address) external view returns (uint256) {
		return voteFactor;
	}

	// Set the voting power of undistributed tokens
	function setVoteFactor(uint256 _voteFactor) external onlyOwner {
		voteFactor = _voteFactor;
		emit SetVoteFactor(voteFactor);
	}

	// disable unused ERC20 methods: the token is only used to track voting power
	function _approve(address, address, uint256) internal pure override {
		revert("disabled for voting power");
  }

	function _transfer(address, address, uint256) internal pure override {
		revert("disabled for voting power");
  }
}