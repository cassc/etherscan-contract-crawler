// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import {ERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {SafeCast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import {ERC20Base} from "./ERC20Base.sol";
import {WadRayMath} from "../libraries/math/WadRayMath.sol";
import {IGToken} from "../../interfaces/IGToken.sol";
import {IPolemarch} from "../../interfaces/IPolemarch.sol";

contract GToken is ERC20Base, OwnableUpgradeable, IGToken {
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
 		__Ownable_init();
 		ERC20Base.initialize(polemarch, name, symbol, decimals);
 		_exchequerSafe = exchequerSafe;
 		_underlyingAsset = underlyingAsset;
 		// emit Initialized(underlyingAsset, decimals);
 	}

 	function mint(address caller, uint256 amount) external onlyPolemarch {
 		_mint(caller, amount);
 	}

 	// function approve(address spender, uint256 amount) external virtual override(ERC20Upgradeable, IERC20Upgradeable) onlyPolemarch {
 	// 	super.approve(spender, amount);
 	// }

 	function approvePolemarch(uint256 amount) external onlyOwner {
 		IERC20(_underlyingAsset).approve(address(POLEMARCH), amount);
 	}

 	function transferUnderlyingToExchequerSafe(uint256 amount) external virtual override onlyPolemarch {
		IERC20(_underlyingAsset).transfer(_exchequerSafe, amount);
	}

}