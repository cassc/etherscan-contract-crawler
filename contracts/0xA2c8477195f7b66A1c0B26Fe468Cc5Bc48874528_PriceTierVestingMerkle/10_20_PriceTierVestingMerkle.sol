// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import { AggregatorV3Interface } from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { PriceTierVesting, PriceTier } from "./abstract/PriceTierVesting.sol";
import { MerkleSet } from "./abstract/MerkleSet.sol";

contract PriceTierVestingMerkle is PriceTierVesting, MerkleSet {
	constructor(
		IERC20 _token,
		uint256 _total,
		string memory _uri, // information on the sale (e.g. merkle proofs)
		uint256 _voteFactor,
		// when price tier vesting opens (seconds past epoch)
		uint256 _start,
		// when price tier vesting ends (seconds past epoch) and all tokens are unlocked
		uint256 _end,
		// source for pricing info
		AggregatorV3Interface _oracle,
		PriceTier[] memory _priceTiers,
		bytes32 _merkleRoot
	) PriceTierVesting(_token, _total, _uri, _voteFactor, _start, _end, _oracle, _priceTiers) MerkleSet(_merkleRoot) {}

	function NAME() external pure override returns (string memory) {
		return "PriceTierVestingMerkle";
	}

	function VERSION() external pure override returns (uint256) {
		return 2;
	}

	function initializeDistributionRecord(
		uint256 index, // the beneficiary's index in the merkle root
		address beneficiary, // the address that will receive tokens
		uint256 amount, // the total claimable by this beneficiary
		bytes32[] calldata merkleProof
	)
		external
		validMerkleProof(keccak256(abi.encodePacked(index, beneficiary, amount)), merkleProof)
	{
		_initializeDistributionRecord(beneficiary, amount);
	}

	function claim(
		uint256 index, // the beneficiary's index in the merkle root
		address beneficiary, // the address that will receive tokens
		uint256 amount, // the total claimable by this beneficiary
		bytes32[] calldata merkleProof
	)
		external
		validMerkleProof(keccak256(abi.encodePacked(index, beneficiary, amount)), merkleProof)
		nonReentrant
	{
		if (!records[beneficiary].initialized) {
			_initializeDistributionRecord(beneficiary, amount);
		}
		_executeClaim(beneficiary, uint120(getClaimableAmount(beneficiary)));
	}

	function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
		_setMerkleRoot(_merkleRoot);
	}
}