// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity ^0.8.4;

interface IPSCYHOLimitedErrors {
	error ExceedsGenerationLimit(uint256 _exceeds);

	error FundAccount(uint256 _amount);

	error StockRemaining(uint256 _stock);
}