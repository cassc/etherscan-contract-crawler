// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract MerkleAirdrop is Ownable {
	IERC20 public immutable TOKEN;
	bytes32 public ROOT;
	uint public START_TIME;
	uint public VESTING_TIME;

	mapping(address => uint) public claimed;

	modifier isInitialized() {
		require(START_TIME != 0, "Not initialized");
		_;
	}

	constructor(IERC20 token) {
		TOKEN = token;
	}

	function init(bytes32 root, uint delta, uint vestingTime) external onlyOwner {
		require(START_TIME == 0, "Already initialized");
		require(vestingTime <= 30 days, "Too long");
		ROOT = root;
		// delta defines an amount users can claim at launch
		START_TIME = block.timestamp - delta;
		VESTING_TIME = vestingTime + delta;
	}

	function claim(uint amount, bytes32[] calldata proof) external isInitialized {
		bytes32 leaf = keccak256(abi.encodePacked(msg.sender, amount));
		require(MerkleProof.verify(proof, ROOT, leaf), "Invalid proof");
		uint amountOut = claimable(msg.sender, amount);
		claimed[msg.sender] += amountOut;
		TOKEN.transfer(msg.sender, amountOut);
	}

	function delayedEmergencyWithdraw() external onlyOwner {
		require(block.timestamp >= START_TIME + 60 days, "Too early");
		TOKEN.transfer(msg.sender, TOKEN.balanceOf(address(this)));
		START_TIME = 0; // not initialized
	}

	function claimable(address user, uint amount) public view isInitialized returns (uint) {
		uint total = amount * (block.timestamp - START_TIME) / VESTING_TIME;
		if (total > amount) total = amount;
		return total - claimed[user];
	}
}