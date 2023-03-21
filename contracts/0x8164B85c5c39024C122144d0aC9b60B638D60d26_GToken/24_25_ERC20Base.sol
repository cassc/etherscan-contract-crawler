// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import {ERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import {SafeCast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import {WadRayMath} from "../libraries/math/WadRayMath.sol";
import {IPolemarch} from "../../interfaces/IPolemarch.sol";

abstract contract ERC20Base is ERC20Upgradeable {
	using WadRayMath for uint256;
	using SafeCast for uint256;

	modifier onlyPolemarch() {
		require(_msgSender() == address(POLEMARCH), "CALLER_MUST_BE_POLEMARCH");
		_;
	}
	// additional user data holds the rate for debt and the lastUpdateTimeStamp for supply
	mapping(address => uint128) internal _additionalUserData;
	uint internal _totalSupply;
	uint8 private _decimals;
	IPolemarch public POLEMARCH;

	function initialize(
		IPolemarch polemarch,
		string memory name,
		string memory symbol,
		uint8 sTokenDecimals
	) internal virtual onlyInitializing {
		__ERC20_init(name, symbol);
		POLEMARCH = polemarch;
		_setDecimals(sTokenDecimals);
	}

	function decimals() public view virtual override returns (uint8) {
		return _decimals;
	}

	function _setDecimals(uint8 newDecimals) internal {
		_decimals = newDecimals;
	}
}