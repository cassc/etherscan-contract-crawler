// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import {IERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {DataTypes} from "./libraries/DataTypes.sol";
import {DepositLogic} from "./libraries/DepositLogic.sol";
import {PoolLogic} from "./libraries/PoolLogic.sol";
import {ReserveLogic} from "./libraries/ReserveLogic.sol";
import {ThToken} from "./thToken.sol";
import {IThToken} from "./IThToken.sol";
import {IPool} from "./IPool.sol";
import {PoolStorage} from "./PoolStorage.sol";

contract Pool is Initializable, OwnableUpgradeable, PoolStorage, IPool {
	using ReserveLogic for DataTypes.Reserve;

	function initialize() external initializer {
		_repayPeriod = 30 days;
		__Ownable_init();
	}

	function initReserve(
		address underlyingAsset,
		address thTokenAddress
	) external onlyOwner returns (bool) {
		bool initialized = PoolLogic.initReserve(_reserves, _reservesList, underlyingAsset, thTokenAddress);
		return initialized;
	}

	function deposit(
		address underlyingAsset,
		uint256 amount
	) public virtual override {
		DepositLogic.deposit(_reserves, underlyingAsset, amount);
	}
	
	function withdraw(
		address underlyingAsset,
		uint256 amount
	) public virtual override {
		DepositLogic.withdraw(_reserves, underlyingAsset, amount);
	}

	function getReserve(address asset) external view returns(DataTypes.Reserve memory) {
		return _reserves[asset];
	}
}