// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.0;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract IQ is ERC20, Ownable {
	bool public botBlockerActive;
	bool public limited;
	uint8 public feeDecimals;
	uint32 public feePercentage;
	uint256 public maxHoldAmount;
	uint256 public minHoldAmount;
	address public uniswapV2Pair;
	mapping(address => bool) public blacklist;

	constructor(uint256 _totalSupply) ERC20("IQ", "IQ") {
		_mint(msg.sender, _totalSupply);
	}

	function blackList(address _address, bool isBlackListed) external onlyOwner {
		blacklist[_address] = isBlackListed;
	}

	function setRules(
		bool _botBlockerEnabled,
		bool _limited,
		address _uniswapV2Pair,
		uint8 _feeDecimals,
		uint32 _feePercentage,
		uint256 _maxHoldAmount,
		uint256 _minHoldAmount
	) external onlyOwner {
		botBlockerActive = _botBlockerEnabled;
		limited = _limited;
		uniswapV2Pair = _uniswapV2Pair;
		feeDecimals = _feeDecimals;
		feePercentage = _feePercentage;
		maxHoldAmount = _maxHoldAmount;
		minHoldAmount = _minHoldAmount;
	}

	function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override {
		require(!blacklist[to] && !blacklist[from], "Blacklisted");

		//trading start protection
		if (uniswapV2Pair == address(0)) {
			require(from == owner() || to == owner(), "TradingNotStarted");
		}

		if (limited && from == uniswapV2Pair && to != address(this)) {
			require(
				super.balanceOf(to) + amount <= maxHoldAmount && super.balanceOf(to) + amount >= minHoldAmount,
				"Limited"
			);
		}
	}

	function _transfer(address sender, address recipient, uint256 amount) internal virtual override {
		_beforeTokenTransfer(sender, recipient, amount);

		if (botBlockerActive && sender == uniswapV2Pair) {
			uint256 collection = calculateTokenFee(amount);
			uint256 tokensToTransfer = amount - collection;

			super._transfer(sender, recipient, tokensToTransfer);
			super._transfer(sender, address(this), collection);
		} else {
			super._transfer(sender, recipient, amount);
		}
	}

	function calculateTokenFee(uint256 _amount) internal view returns (uint256 locked) {
		locked = (_amount * feePercentage) / (10 ** (uint256(feeDecimals) + 2));
	}

	// withdraw any stuck tokens sent here by mistake + fees
	function withdrawFees() external onlyOwner {
		uint256 balance = balanceOf(address(this));
		super._transfer(address(this), owner(), balance);
	}

	function burn(uint256 amount) external {
		_burn(msg.sender, amount);
	}
}