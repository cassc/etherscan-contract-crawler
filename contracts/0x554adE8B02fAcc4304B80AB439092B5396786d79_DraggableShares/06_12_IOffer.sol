// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../ERC20/IERC20.sol";

interface IOffer {
	function makeCompetingOffer(IOffer newOffer) external;

	// if there is a token transfer while an offer is open, the votes get transfered too
	function notifyMoved(address from, address to, uint256 value) external;

	function currency() external view returns (IERC20);

	function price() external view returns (uint256);

	function isWellFunded() external view returns (bool);
}