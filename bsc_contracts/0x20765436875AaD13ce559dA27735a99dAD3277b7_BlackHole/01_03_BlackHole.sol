// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./openzeppelin/token/ERC20/IERC20.sol";
import "./interfaces/IBlackHole.sol";

contract BlackHole is IBlackHole {
	string private _name;

	constructor (string memory name) {
		_name = name;
	}

	function whoAmI() external view override returns (string memory) {
		return string(abi.encodePacked("I'm ", _name, " blackhole"));
	}

	function absorbedBalance(address token) external view override returns (uint256) {
		return IERC20(token).balanceOf(address(this));
	}

	function availableSupply(address token) external view override returns (uint256) {
		return IERC20(token).totalSupply() - IERC20(token).balanceOf(address(this));
	}
}