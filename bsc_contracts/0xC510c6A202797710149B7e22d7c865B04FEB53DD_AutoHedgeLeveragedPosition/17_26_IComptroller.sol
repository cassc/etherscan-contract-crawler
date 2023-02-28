pragma solidity 0.8.6;

interface IComptrollerStorage {
	function cTokensByUnderlying(address underlying) external view returns (address);
}

interface IComptroller is IComptrollerStorage {
	/// @notice Indicator that this is a Comptroller contract (for inspection)
	//    bool public constant isComptroller = true; TODO Variables cannot be declared in interfaces.

	/*** Assets You Are In ***/

	function enterMarkets(address[] calldata cTokens) external returns (uint256[] memory);

	function exitMarket(address cToken) external returns (uint256);

	/*** Policy Hooks ***/

	function mintAllowed(
		address cToken,
		address minter,
		uint256 mintAmount
	) external returns (uint256);

	function mintWithinLimits(
		address cToken,
		uint256 exchangeRateMantissa,
		uint256 accountTokens,
		uint256 mintAmount
	) external returns (uint256);

	function mintVerify(
		address cToken,
		address minter,
		uint256 mintAmount,
		uint256 mintTokens
	) external;

	function redeemAllowed(
		address cToken,
		address redeemer,
		uint256 redeemTokens
	) external returns (uint256);

	function redeemVerify(
		address cToken,
		address redeemer,
		uint256 redeemAmount,
		uint256 redeemTokens
	) external;

	function borrowAllowed(
		address cToken,
		address borrower,
		uint256 borrowAmount
	) external returns (uint256);

	function borrowWithinLimits(address cToken, uint256 accountBorrowsNew)
		external
		returns (uint256);

	function borrowVerify(
		address cToken,
		address borrower,
		uint256 borrowAmount
	) external;

	function repayBorrowAllowed(
		address cToken,
		address payer,
		address borrower,
		uint256 repayAmount
	) external returns (uint256);

	function repayBorrowVerify(
		address cToken,
		address payer,
		address borrower,
		uint256 repayAmount,
		uint256 borrowerIndex
	) external;

	function liquidateBorrowAllowed(
		address cTokenBorrowed,
		address cTokenCollateral,
		address liquidator,
		address borrower,
		uint256 repayAmount
	) external returns (uint256);

	function liquidateBorrowVerify(
		address cTokenBorrowed,
		address cTokenCollateral,
		address liquidator,
		address borrower,
		uint256 repayAmount,
		uint256 seizeTokens
	) external;

	function seizeAllowed(
		address cTokenCollateral,
		address cTokenBorrowed,
		address liquidator,
		address borrower,
		uint256 seizeTokens
	) external returns (uint256);

	function seizeVerify(
		address cTokenCollateral,
		address cTokenBorrowed,
		address liquidator,
		address borrower,
		uint256 seizeTokens
	) external;

	function transferAllowed(
		address cToken,
		address src,
		address dst,
		uint256 transferTokens
	) external returns (uint256);

	function transferVerify(
		address cToken,
		address src,
		address dst,
		uint256 transferTokens
	) external;

	/*** Liquidity/Liquidation Calculations ***/

	function liquidateCalculateSeizeTokens(
		address cTokenBorrowed,
		address cTokenCollateral,
		uint256 repayAmount
	) external view returns (uint256, uint256);

	/*** Pool-Wide/Cross-Asset Reentrancy Prevention ***/

	function _beforeNonReentrant() external;

	function _afterNonReentrant() external;

	function _deployMarket(
		bool isCEther,
		bytes memory constructorData,
		uint256 collateralFactorMantissa
	) external;

	function getAccountLiquidity(address account)
		external
		view
		virtual
		returns (
			uint256,
			uint256,
			uint256
		);
}