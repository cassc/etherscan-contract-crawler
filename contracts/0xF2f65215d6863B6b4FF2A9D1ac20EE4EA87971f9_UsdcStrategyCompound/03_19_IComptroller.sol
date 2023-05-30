// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface IComptroller {
	function markets(address cToken)
		external
		view
		returns (
			bool isListed,
			uint256 collateralFactorMantissa,
			bool isComped
		);

	function claimComp(address holder, address[] calldata cTokens) external;
}