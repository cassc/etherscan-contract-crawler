// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../ERC20/IERC20.sol";
import "./IOffer.sol";

interface IOfferFactory {

	function create(
		bytes32 salt, address buyer, uint256 pricePerShare,	IERC20 currency,	uint256 quorum,	uint256 votePeriod
	) external payable returns (IOffer);
}