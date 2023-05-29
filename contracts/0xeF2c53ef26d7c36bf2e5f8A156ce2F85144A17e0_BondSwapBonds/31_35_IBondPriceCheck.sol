// SPDX-License-Identifier: UNLICENSED
// Created by DegenLabs https://bondswap.org

pragma solidity ^0.8.15;

interface IBondPriceCheck {
	function getRewardAmountForETH(address bondToken, uint256 value) external view returns (uint256);

	function getRewardAmountForToken(
		address bondToken,
		address paymentToken,
		uint256 value
	) external view returns (uint256);
}