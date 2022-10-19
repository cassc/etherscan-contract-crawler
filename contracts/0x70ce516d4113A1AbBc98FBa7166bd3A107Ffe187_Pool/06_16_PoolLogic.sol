// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;
import {DataTypes} from "./DataTypes.sol";
import {ReserveLogic} from "./ReserveLogic.sol";

error RESERVE_ALREADY_ADDED();
// error RESERVE_ALREADY_INITIALIZED();

library PoolLogic {
	using ReserveLogic for DataTypes.Reserve;

	function initReserve(
		mapping(address => DataTypes.Reserve) storage reserves,
		address[] storage reservesList,
		address underlyingAsset,
		address thTokenAddress
	) internal returns (bool) {
		bool alreadyAdded = reserves[underlyingAsset].id != 0 || reserves[underlyingAsset].thTokenAddress != address(0); // || reservesList[0] == underlyingAsset;
		if (alreadyAdded) {
			revert RESERVE_ALREADY_ADDED();
		}
		reserves[underlyingAsset].init(thTokenAddress);
		reservesList.push(underlyingAsset);
		reserves[underlyingAsset].id = uint16(reservesList.length - 1);		
		return true;
	}
}