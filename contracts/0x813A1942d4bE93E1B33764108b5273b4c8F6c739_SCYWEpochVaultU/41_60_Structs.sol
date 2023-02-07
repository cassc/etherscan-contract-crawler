// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

enum CallType {
	ADD_LIQUIDITY_AND_MINT,
	BORROWB,
	REMOVE_LIQ_AND_REPAY
}

enum VaultType {
	Strategy,
	Aggregator
}

enum EpochType {
	None,
	Withdraw,
	Full
}

enum NativeToken {
	None,
	Underlying,
	Short
}

struct CalleeData {
	CallType callType;
	bytes data;
}
struct AddLiquidityAndMintCalldata {
	uint256 uAmnt;
	uint256 sAmnt;
}
struct BorrowBCalldata {
	uint256 borrowAmount;
	bytes data;
}
struct RemoveLiqAndRepayCalldata {
	uint256 removeLpAmnt;
	uint256 repayUnderlying;
	uint256 repayShort;
	uint256 borrowUnderlying;
	// uint256 amountAMin;
	// uint256 amountBMin;
}

struct HarvestSwapParams {
	address[] path; //path that the token takes
	uint256 min; // min price of in token * 1e18 (computed externally based on spot * slippage + fees)
	uint256 deadline;
	bytes pathData; // uniswap3 path data
}

struct IMXConfig {
	address vault;
	address underlying;
	address short;
	address uniPair;
	address poolToken;
	address farmToken;
	address farmRouter;
}

struct HLPConfig {
	string symbol;
	string name;
	address underlying;
	address short;
	address cTokenLend;
	address cTokenBorrow;
	address uniPair;
	address uniFarm;
	address farmToken;
	uint256 farmId;
	address farmRouter;
	address comptroller;
	address lendRewardRouter;
	address lendRewardToken;
	address vault;
	NativeToken nativeToken;
}

struct EAction {
	address target;
	uint256 value;
	bytes data;
}