// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity ^0.8.4;

interface IPSCYHOLimitedErrors {
	error ExceedsMintLimit(uint256 _excess);

	error ExceedsStockLimit(uint256 _excess);

	error FundAccount(uint256 _required);
}