// SPDX-License-Identifier: MIT

pragma solidity =0.8.15;

struct EventData {
	uint256[2] chains; // [chainId, chainId]
	address[2] tokens; // where, ETH - address(0)
	address[2] parties; // address from - to [account, account on other side]
	uint256 amountIn; // token in amount
	string swapType;
	address operator; // adapter address
	uint256 exchangeId;
	uint256 aggregatorId;
	string details;
}

struct Swap {
	address operator;
	address token; // ERC20 or Wrapped core token
	address from;
	address to;
	uint256 amount;
	uint256 toChainID;
}