// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import {IERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import {DataTypes} from "./DataTypes.sol";
import {ReserveLogic} from "./ReserveLogic.sol";
import {IThToken} from "../IThToken.sol";


error INVALID_AMOUNT();
error NOT_ENOUGH_IN_USER_BALANCE();

library DepositLogic {
	using ReserveLogic for DataTypes.Reserve;

	event Deposit(address indexed reserve, address user, uint256 amount);
	event Withdraw(address indexed reserve, address user, uint256 amount);

	function deposit(
		mapping(address => DataTypes.Reserve) storage reserves,
		address underlyingAsset,
		uint256 amount
	) internal {
		DataTypes.Reserve memory reserve = reserves[underlyingAsset];
		if (amount == 0) {
			revert INVALID_AMOUNT();
		}
		IERC20Upgradeable(underlyingAsset).transferFrom(msg.sender, reserve.thTokenAddress, amount);
		IThToken(reserve.thTokenAddress).mint(msg.sender, amount);
		emit Deposit(underlyingAsset, msg.sender, amount);
	}

	function withdraw(
		mapping(address => DataTypes.Reserve) storage reserves,
		address underlyingAsset,
		uint256 amount
	) internal {
		DataTypes.Reserve memory reserve = reserves[underlyingAsset];
		if (amount == 0) {
			revert INVALID_AMOUNT();
		}
		uint256 userBalance = IThToken(reserve.thTokenAddress).balanceOf(msg.sender);
		if (amount >= userBalance) {
			revert NOT_ENOUGH_IN_USER_BALANCE();
		}
		IThToken(reserve.thTokenAddress).burn(msg.sender, amount);
		emit Withdraw(underlyingAsset, msg.sender, amount);
	}
}