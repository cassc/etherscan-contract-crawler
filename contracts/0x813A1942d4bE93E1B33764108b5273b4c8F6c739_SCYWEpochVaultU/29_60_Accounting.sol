// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import { FixedPointMathLib } from "../libraries/FixedPointMathLib.sol";
import { IERC4626Accounting } from "../interfaces/ERC4626/IERC4626Accounting.sol";

// import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

// import "hardhat/console.sol";

abstract contract Accounting is IERC4626Accounting {
	using FixedPointMathLib for uint256;

	function totalAssets() public view virtual returns (uint256);

	function totalSupply() public view virtual returns (uint256);

	function toSharesAfterDeposit(uint256 assets) public view virtual returns (uint256) {
		uint256 supply = totalSupply(); // Saves an extra SLOAD if totalSupply is non-zero.
		uint256 _totalAssets = totalAssets() - assets;
		if (_totalAssets == 0) return assets;
		return supply == 0 ? assets : assets.mulDivDown(supply, _totalAssets);
	}

	function convertToShares(uint256 assets) public view virtual returns (uint256) {
		uint256 supply = totalSupply();

		return supply == 0 ? assets : assets.mulDivDown(supply, totalAssets());
	}

	function convertToAssets(uint256 shares) public view virtual returns (uint256) {
		uint256 supply = totalSupply(); // Saves an extra SLOAD if totalSupply is non-zero.

		return supply == 0 ? shares : shares.mulDivDown(totalAssets(), supply);
	}

	error ZeroAmount();

	uint256[50] private __gap;
}