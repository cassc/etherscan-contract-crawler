// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.16;

interface IMXRouter2 {
	function mint(
		address collateralToken,
		uint256 amount,
		address to,
		uint256 deadline
	) external returns (uint256 tokens);

	function borrow(
		address borrowable,
		uint256 amount,
		address to,
		uint256 deadline,
		bytes memory permitData
	) external;

	function borrowETH(
		address borrowable,
		uint256 amountETH,
		address to,
		uint256 deadline,
		bytes memory permitData
	) external;
}

interface IPoolToken {
	function totalBalance() external view returns (uint256);

	function mint(address minter) external returns (uint256 mintTokens);

	function underlying() external view returns (address);

	function exchangeRate() external view returns (uint256);

	function redeem(address redeemer) external returns (uint256 redeemAmount);
}

interface IBorrowable {
	function borrow(
		address borrower,
		address receiver,
		uint256 borrowAmount,
		bytes calldata data
	) external;

	function borrowApprove(address spender, uint256 value) external returns (bool);

	function accrueInterest() external;

	function borrowBalance(address borrower) external view returns (uint256);

	function underlying() external view returns (address);

	function exchangeRate() external returns (uint256);

	function exchangeRateLast() external view returns (uint256);

	function totalSupply() external view returns (uint256);

	function totalBorrows() external view returns (uint256);

	function totalBalance() external view returns (uint256);

	function borrowTracker() external view returns (address);
}

interface ICollateral {
	function safetyMarginSqrt() external view returns (uint256);

	function liquidationIncentive() external view returns (uint256);

	function underlying() external view returns (address);

	function borrowable0() external view returns (address);

	function borrowable1() external view returns (address);

	function accountLiquidity(address account)
		external
		view
		returns (uint256 liquidity, uint256 shortfall);

	function flashRedeem(
		address redeemer,
		uint256 redeemAmount,
		bytes calldata data
	) external;

	function mint(address minter) external returns (uint256 mintTokens);

	function exchangeRate() external view returns (uint256);

	function getPrices() external view returns (uint256 price0, uint256 price1);

	function balanceOf(address) external view returns (uint256);

	function getTwapPrice112x112() external view returns (uint224 twapPrice112x112);

	function simpleUniswapOracle() external view returns (address);

	function tarotPriceOracle() external view returns (address);
}

interface ImpermaxChef {
	function pendingReward(address borrowable, address _user) external view returns (uint256);

	function harvest(address borrowable, address to) external;

	function massHarvest(address[] calldata borrowables, address to) external;
}