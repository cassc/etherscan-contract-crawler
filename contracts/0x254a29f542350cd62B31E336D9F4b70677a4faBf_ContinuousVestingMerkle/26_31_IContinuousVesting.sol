// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IVesting } from "./IVesting.sol";

interface IContinuousVesting is IVesting {
	event SetContinuousVesting(uint256 start, uint256 cliff, uint256 end);

	function getVestingConfig()
		external
		view
		returns (
			uint256,
			uint256,
			uint256
		);

	function setVestingConfig(
		uint256 _start,
		uint256 _cliff,
		uint256 _end
	) external;
}