pragma solidity 0.8.6;

interface CErc20Storage {
	function underlying() external returns (address);
}

interface ICErc20 is CErc20Storage {
	function mint(uint256 mintAmount) external returns (uint256);

	function redeem(uint256 redeemTokens) external returns (uint256);

	function redeemUnderlying(uint256 redeemAmount) external returns (uint256);

	function borrow(uint256 borrowAmount) external returns (uint256);

	function repayBorrow(uint256 repayAmount) external returns (uint256);

	function repayBorrowBehalf(address borrower, uint256 repayAmount) external returns (uint256);

	function liquidateBorrow(
		address borrower,
		uint256 repayAmount,
		address cTokenCollateral
	) external returns (uint256);

	function transfer(address receiver, uint256 amount) external;

	function balanceOfUnderlying(address account) external returns (uint256);

	function borrowBalanceCurrent(address account) external returns (uint256);

	function exchangeRateCurrent() external returns (uint256);

	function exchangeRateStored() external returns (uint256);

	function accrueInterest() external returns (uint256);

	function balanceOf(address account) external view returns (uint256);

	function getCash() external view returns (uint256);

	function totalSupply() external view returns (uint256);

	function borrowRatePerBlock() external view returns (uint256);

	function supplyRatePerBlock() external view returns (uint256);

	function totalReserves() external view returns (uint256);

	function totalBorrows() external view returns (uint256);

	function totalBorrowsCurrent() external returns (uint256);

	// function getCash() external view returns (uint);
	function comptroller() external view returns (address);

	function isCToken() external view returns (bool);
}