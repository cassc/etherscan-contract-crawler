// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import { IUniswapV2Router02 } from '@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol';

library Constants {
	string public constant NAME = 'Cut It Off';
	string public constant SYMBOL = 'CUT';

	uint256 public constant TOTAL_SUPPLY = 420_000_000_000;

	IUniswapV2Router02 public constant UNISWAP_V2_ROUTER = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
}