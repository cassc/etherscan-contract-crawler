// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import {ERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import {IERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import {IThToken} from "./IThToken.sol";
import {IPool} from "./IPool.sol";

error CALLER_IS_NOT_POOL_ADMIN();

contract ThToken is ERC20Upgradeable, IThToken {
	address internal _underlyingAsset;
	uint8 private _decimals;
	IPool public POOL;

	modifier onlyPool() {
		if (_msgSender() != address(POOL)) {
			revert CALLER_IS_NOT_POOL_ADMIN();
		}
		_;
	}

	function initialize(
		IPool pool,
		string memory name,
		string memory symbol,
		address underlyingAsset,
		uint8 thTokenDecimals
		) external initializer {
		__ERC20_init(name, symbol);
		POOL = pool;
		_underlyingAsset = underlyingAsset;
		_setDecimals(thTokenDecimals);
		emit Initialized(underlyingAsset, address(POOL), thTokenDecimals);
	}

	function mint(address _account, uint256 _amount) external onlyPool {
		_mint(_account, _amount);
	}

	function burn(address _account, uint256 _amount) external onlyPool {
		_burn(_account, _amount);
		if (_account != address(this)) {
			IERC20Upgradeable(_underlyingAsset).transfer(_account, _amount);
		}
	}

	function _setDecimals(uint8 newDecimals) internal {
	  _decimals = newDecimals;
	}

	function decimals() public view override returns (uint8) {
	  return _decimals;
	}


	function getUnderlyingAsset() public view returns(address) { return _underlyingAsset; }
}