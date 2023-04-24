// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IHashflowQuote} from "../interfaces/IHashflowQuote.sol";
import {Sweepable} from "../utilities/Sweepable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract Trader is IHashflowQuote, Ownable, Sweepable, ReentrancyGuard {
	using SafeERC20 for IERC20;

	event SetConfig(
		IHashflowQuote router,
		uint256 feeBips
	);

	event HashflowTradeSingleHop(IHashflowQuote.RFQTQuote quote);
	event HashflowTradeXChain(IHashflowQuote.XChainRFQTQuote quote, XChainMessageProtocol protocol);

	IHashflowQuote private router;
	uint256 private feeBips;

	constructor(IHashflowQuote _router, uint256 _feeBips, address payable _feeRecipient) Sweepable(_feeRecipient) {
		_setConfig(_router, _feeBips, _feeRecipient);
	}

	function getSplit(uint256 initialTotal) public view returns(uint256 baseTokenTotal, uint256 baseTokenAmount, uint256 baseTokenFee) {
		// calculate total, base, and fee token amounts exactly like they will be calculated during the trade
		baseTokenAmount = initialTotal * (10000 - feeBips) / 10000;
		baseTokenFee = getFee(baseTokenAmount);
		baseTokenTotal = baseTokenAmount + baseTokenFee;
		return (baseTokenTotal, baseTokenAmount, baseTokenFee);
	}

	function getFee(uint256 baseTokenAmount) public view returns(uint256 baseTokenFee) {
		baseTokenFee = baseTokenAmount * feeBips  / (10000 - feeBips);
	}

	function tradeSingleHop(RFQTQuote calldata quote) public payable nonReentrant {
		// calculate the trade fee
		uint256 fee = getFee(quote.effectiveBaseTokenAmount);

		// transfer fee + effectiveBaseTokenAmount to contract so it can then transfer effectiveBaseTokenAmount to the maker
		if (quote.baseToken != address(0)) {
			// this is an ERC20 transfer: get all ERC20 tokens and approve the Hashflow router to withdraw the correct quantity
			IERC20(quote.baseToken).safeTransferFrom(msg.sender, address(this), quote.effectiveBaseTokenAmount + fee);
			IERC20(quote.baseToken).approve(address(router), quote.effectiveBaseTokenAmount);
			router.tradeSingleHop(quote);
		} else {
			// this is a native token transfer
			require(msg.value == quote.effectiveBaseTokenAmount + fee, "incorrect value");
			// low level call to send along ETH in the internal tx
			(bool success,) = address(router).call{value: quote.effectiveBaseTokenAmount}(abi.encodeWithSignature("tradeSingleHop((address,address,address,address,address,address,uint256,uint256,uint256,uint256,uint256,bytes32,bytes))", quote));
			require(success, "native base token trade failed");
		}

		emit HashflowTradeSingleHop(quote);
	}

	function tradeXChain(
		XChainRFQTQuote calldata quote,
		XChainMessageProtocol protocol
	) public payable nonReentrant {
		// calculate the trade fee
		uint256 fee = getFee(quote.baseTokenAmount);

		// transfer the trade fee to the fee recipient
		if (quote.baseToken != address(0)) {
			// this is an ERC20 transfer - pull in the base token including fee and approve Hashflow to pull the baseTokenAmount
			IERC20(quote.baseToken).safeTransferFrom(msg.sender, address(this), fee + quote.baseTokenAmount);
			IERC20(quote.baseToken).approve(address(router), quote.baseTokenAmount);

			// NOTE: for ERC20 base token trades, msg.value == xChainFeeEstimate (the fee is in ERC20)
			router.tradeXChain{value: msg.value}(quote, protocol);
		} else {
			// this is a native token transfer
			// NOTE: for native base token trades, msg.value == xChainFeeEstimate + quote.baseTokenAmount + fee
			router.tradeXChain{value: msg.value - fee}(quote, protocol);
		}
		emit HashflowTradeXChain(quote, protocol);
	}

	function _setConfig(
		IHashflowQuote _router,
		uint256 _feeBips,
		address payable _feeRecipient
	) private {
		router = _router;
		feeBips = _feeBips;
		_setSweepRecipient(_feeRecipient);
		emit SetConfig(router, feeBips);
	}

	function setConfig (
		IHashflowQuote _router,
		uint256 _feeBips,
		address payable _feeRecipient
	) external onlyOwner {
		_setConfig(_router, _feeBips, _feeRecipient);
	}

	function getConfig () external view returns (IHashflowQuote, uint256, address payable) {
		return (router, feeBips, getSweepRecipient());
	}
}