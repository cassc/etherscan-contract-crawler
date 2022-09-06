// SPDX-License-Identifier: MPL-2.0
pragma solidity 0.8.4;

interface ILockup {
	function calculateWithdrawableInterestAmountByPosition(uint256 _tokenId)
		external
		view
		returns (uint256);
}