// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

struct Tranche {
	uint128 time; // block.timestamp upon which the tranche vests
	uint128 vestedFraction; // fraction of tokens unlockable as basis points (e.g. 100% of vested tokens is the fraction denominator, defaulting to 10000)
}

interface ITrancheVesting {
	event SetTranche(uint256 indexed index, uint128 time, uint128 VestedFraction);

	function getTranche(uint256 i) external view returns (Tranche memory);

	function getTranches() external view returns (Tranche[] memory);

	function setTranches(Tranche[] memory _tranches) external;
}