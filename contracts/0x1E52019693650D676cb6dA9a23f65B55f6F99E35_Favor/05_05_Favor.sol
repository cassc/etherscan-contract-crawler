// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./ABDKMath64x64.sol";

contract Favor is Ownable {
	using ABDKMath64x64 for *;

	IERC20 public immutable TOKEN;
	address public STAKING;

	uint public DAILY_DECAY = 5000; // 50%
	uint public SALES_PER_DAY = 200;
	uint public STARTING_PRICE = 5000 ether;
	uint public MIN_PRICE = 250 ether;
	uint public START_TIME;
	uint private constant DENOMINATOR = 10000;

	uint public MAX_FAVOR = 2500; // 25%
	
	uint public sales;
	mapping(address => uint) public balanceOf;

	uint public contributionBank1;
	uint public contributionBank2;

	address public receiver;

	constructor(IERC20 token, address receiver_) {
		TOKEN = token;
		receiver = receiver_;
	}

	function init(address staking) external onlyOwner {
		require(STAKING == address(0), "Already initialized");
		STAKING = staking;
	}

	function start() external {
		require(msg.sender == STAKING, "Only Staking");
		START_TIME = block.timestamp;
	}

	function mint(uint amount) external {
		require(START_TIME != 0, "Didn't start yet");
		require(amount > 0, "Amount must be greater than zero");
		uint price = getPrice();
		sales += amount;
		TOKEN.transferFrom(msg.sender, receiver, price * amount);
		balanceOf[msg.sender] += amount;
	}

	function contribute(bool bank, uint amount) external {
		require(amount > 0, "Amount must be greater than zero");
		balanceOf[msg.sender] -= amount;
		if (!bank) contributionBank1 += amount;
		else contributionBank2 += amount;
	}
	
	function resetContributions() external {
		require(msg.sender == STAKING, "Only Staking");
		contributionBank1 = 0;
		contributionBank2 = 0;
	}

	function airdrop(address[] calldata tos, uint[] calldata amounts, bool update) external onlyOwner {
		require(tos.length == amounts.length, "Length");

		uint total;
		for (uint i; i < tos.length; i++) {
			balanceOf[tos[i]] += amounts[i];
			total += amounts[i];
		}

		if (update) sales += total;
	}

	function setReceiver(address receiver_) external onlyOwner {
		receiver = receiver_;
	}

	function updateStorage(uint[5] calldata array) external onlyOwner {
		DAILY_DECAY = array[0];
		SALES_PER_DAY = array[1];
		STARTING_PRICE = array[2];
		MIN_PRICE = array[3];
		MAX_FAVOR = array[4];
	}

	function getFavors() public view returns (uint favor1, uint favor2) {
		uint contributionBank1Cached = contributionBank1;
		uint contributionBank2Cached = contributionBank2;

		if (contributionBank1Cached > contributionBank2Cached) {
			if (contributionBank2Cached == 0) return (MAX_FAVOR, 0);
			favor1 = _computeFavor(contributionBank1Cached, contributionBank2Cached);
		} else if (contributionBank2Cached > contributionBank1Cached) {
			if (contributionBank1Cached == 0) return (0, MAX_FAVOR);
			favor2 = _computeFavor(contributionBank2Cached, contributionBank1Cached);
		}
	}

	function _computeFavor(uint contributionA, uint contributionB) internal view returns (uint) {
		// 2500 * (1 - 2**(-ratio))
		uint ratio = contributionA * DENOMINATOR / contributionB - DENOMINATOR;
		int128 exp = ratio.divu(DENOMINATOR).neg().exp_2();
		int128 substraction = uint(1).fromUInt().sub(exp);
		return substraction.mulu(MAX_FAVOR);
	}

	function getPrice() public view returns (uint) {
		int128 one = uint(1).fromUInt();
		int128 k = DAILY_DECAY.divu(DENOMINATOR * SALES_PER_DAY);
		int128 substraction = one.sub(k);

		uint sn = sales;
		uint t = (block.timestamp - START_TIME) / (1 days / SALES_PER_DAY);
		if (sn > t) return STARTING_PRICE;
		
		int128 calculation = substraction.pow(t - sn);
		uint out = calculation.mulu(STARTING_PRICE);
		return out > MIN_PRICE ? out : MIN_PRICE;
	}
}