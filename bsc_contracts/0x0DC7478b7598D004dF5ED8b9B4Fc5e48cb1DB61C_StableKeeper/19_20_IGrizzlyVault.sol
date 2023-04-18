// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.18;

import { IPancakeV3Pool } from "@pancakeswap/v3-core/contracts/interfaces/IPancakeV3Pool.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IGrizzlyVaultStorage } from "./IGrizzlyVaultStorage.sol";

interface IGrizzlyVault is IGrizzlyVaultStorage, IERC20 {
	function pool() external view returns (IPancakeV3Pool);

	function token0() external view returns (IERC20);

	function token1() external view returns (IERC20);

	function baseTicks() external view returns (Ticks memory);

	function tokenId() external view returns (uint256 tokenId);

	function getMintAmounts(
		uint256 amount0Max,
		uint256 amount1Max
	) external returns (uint256 amount0, uint256 amount1, uint256 mintAmount);

	function mint(
		uint256 mintAmount,
		address receiver
	) external returns (uint256 amount0, uint256 amount1, uint128 liquidityMinted);

	function burn(
		uint256 burnAmount,
		address receiver
	) external returns (uint256 amount0, uint256 amount1, uint128 liquidityBurned);

	function positionRebalance(
		int24 newLowerTick,
		int24 newUpperTick,
		uint128 minLiquidity
	) external;

	function autoCompound() external;

	function liquidityOfPool(uint256 nftId) external view returns (uint128 liquidity);

	function getUnderlyingBalances()
		external
		view
		returns (uint256 amount0Current, uint256 amount1Current);
}