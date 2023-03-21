// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import {ERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import {SafeCast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import {ERC20Base} from "./ERC20Base.sol";
import {WadRayMath} from "../libraries/math/WadRayMath.sol";
import {IPolemarch} from "../../interfaces/IPolemarch.sol";
import {ISToken} from "../../interfaces/ISToken.sol";
import {ScaledBalanceTokenBase} from "./ScaledBalanceTokenBase.sol";

contract SToken is ScaledBalanceTokenBase, ISToken {
 	using WadRayMath for uint256;
 	using SafeCast for uint256;

 	address internal _exchequerSafe;
 	address internal _underlyingAsset;


	function initialize(
		IPolemarch polemarch,
		string memory name,
		string memory symbol,
		uint8 decimals,
		address exchequerSafe,
		address underlyingAsset
	) external initializer {
		ScaledBalanceTokenBase.initialize(polemarch, name, symbol, decimals);
		require(polemarch == POLEMARCH, "POLEMARCH_ADDRESSES_DO_NOT_MATCH");
		_exchequerSafe = exchequerSafe;
		_underlyingAsset = underlyingAsset;
		// emit Initialized(underlyingAsset, decimals);
	}

	function mint(address account, uint256 amount, uint256 index) external onlyPolemarch {
		_mintScaled(account, amount, index);
	}

	// function mintToExchequerSafe(uint256 amount, uint256 index) external onlyPolemarch {
	// 	if (amount == 0) {
	// 	  return;
	// 	}
	// 	_mintScaled(_exchequerSafe, amount, index);
	// }

	function burn(address account, uint256 amount, uint256 index) external onlyPolemarch {
		_burnScaled(account, amount, index);
		if (account != address(this)) {
			IERC20(_underlyingAsset).transfer(account, amount);
		}
	}

	function transferUnderlying(address to, uint256 amount) external virtual override onlyPolemarch {
		IERC20(_underlyingAsset).transfer(to, amount);
	}

	function transferUnderlyingToExchequerSafe(uint256 amount) external virtual override onlyPolemarch {
		IERC20(_underlyingAsset).transfer(_exchequerSafe, amount);
	}

	function availableUnderlyingSupply() public view returns (uint256) {
		return IERC20(_underlyingAsset).balanceOf(address(this));
	}

	function withdrawableTotalSupply(uint256 totalDebt) public view returns (uint256) {
		uint256 underlying = availableUnderlyingSupply();
		return underlying - totalDebt;
	} // should be the total supply minus the sum of the borrowMaxes for LoCs

	function withdrawableBalance(
		address user,
		uint256 totalDebt
	) public view returns (uint256) {
		uint256 availableSupply = withdrawableTotalSupply(totalDebt);
		uint256 currTotalSupply = totalSupply();
		return balanceOf(user).rayMul((availableSupply).rayDiv(currTotalSupply));
	} // times user's relative contribution to total supply

	function balanceOf(address user)
		public 
		view 
		virtual 
		override(ERC20Upgradeable, IERC20Upgradeable)
		returns (uint256) 
	{
		return super.balanceOf(user).rayMul(POLEMARCH.getNormalizedReturn(_underlyingAsset));
	}

	function totalSupply()
		public
		view
		override(ERC20Upgradeable, IERC20Upgradeable)
		returns (uint256)
	{
		uint256 scaledSupply = super.totalSupply();
		if (scaledSupply == 0) {
			return 0;
		}

		return scaledSupply.rayMul(POLEMARCH.getNormalizedReturn(_underlyingAsset));
	}

	function getExchequerSafe() public view returns (address) {
		return _exchequerSafe;
	}
}