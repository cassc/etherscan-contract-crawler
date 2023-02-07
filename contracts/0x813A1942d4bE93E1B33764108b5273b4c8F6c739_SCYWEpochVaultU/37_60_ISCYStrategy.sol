// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.16;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { HarvestSwapParams } from "../../interfaces/Structs.sol";
import { SectorErrors } from "../../interfaces/SectorErrors.sol";

interface ISCYStrategy {
	function underlying() external view returns (IERC20);

	function deposit(uint256 amount) external returns (uint256);

	function redeem(address to, uint256 amount) external returns (uint256 amntOut);

	function closePosition(uint256 slippageParam) external returns (uint256);

	function getAndUpdateTvl() external returns (uint256);

	function getTvl() external view returns (uint256);

	function getMaxTvl() external view returns (uint256);

	function collateralToUnderlying() external view returns (uint256);

	function harvest(
		HarvestSwapParams[] calldata farm1Params,
		HarvestSwapParams[] calldata farm2Parms
	) external returns (uint256[] memory harvest1, uint256[] memory harvest2);

	function getWithdrawAmnt(uint256 lpTokens) external view returns (uint256);

	function getDepositAmnt(uint256 uAmnt) external view returns (uint256);

	function getLpBalance() external view returns (uint256);

	function getLpToken() external view returns (address);
}