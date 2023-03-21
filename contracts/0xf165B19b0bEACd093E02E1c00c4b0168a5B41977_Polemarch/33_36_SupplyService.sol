// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IGToken} from "../../../interfaces/IGToken.sol";
import {ISToken} from "../../../interfaces/ISToken.sol";
import {IThurmanToken} from "../../../interfaces/IThurmanToken.sol";
import {Types} from "../types/Types.sol";
import {ExchequerService} from "./ExchequerService.sol";
import {StrategusService} from "./StrategusService.sol";
import {WadRayMath} from "../math/WadRayMath.sol";

library SupplyService {
	using WadRayMath for uint256;
	using ExchequerService for Types.Exchequer;

	event Supply(address indexed exchequer, address indexed user, uint256 amount);
	event GrantSupply(address indexed exchequer, address indexed user, uint256 amount);
	event Withdraw(address indexed exchequer, address indexed user, uint256 amount);

	function addSupply(
		mapping(address => Types.Exchequer) storage exchequers,
		address underlyingAsset,
		address governanceAsset,
		uint256 amount
	) internal {
		Types.Exchequer storage exchequer = exchequers[underlyingAsset];
		exchequer.update();
		StrategusService.guardAddSupply(exchequer, amount);

		IERC20(underlyingAsset).transferFrom(msg.sender, exchequer.sTokenAddress, amount);
		ISToken(exchequer.sTokenAddress).mint(
			msg.sender,
			amount,
			exchequer.supplyIndex
		);
		IThurmanToken(governanceAsset).mint(msg.sender, amount);
		exchequer.updateSupplyRate();

		emit Supply(underlyingAsset, msg.sender, amount);

	}

	function addGrantSupply(
		mapping(address => Types.Exchequer) storage exchequers,
		address underlyingAsset,
		address governanceAsset,
		uint256 amount
	) internal {
		Types.Exchequer storage exchequer = exchequers[underlyingAsset];
		// exchequer.update()
		StrategusService.guardAddGrantSupply(exchequer, amount);
		IERC20(underlyingAsset).transferFrom(msg.sender, exchequer.gTokenAddress, amount);
		IGToken(exchequer.gTokenAddress).mint(msg.sender, amount);
		IThurmanToken(governanceAsset).mint(msg.sender, amount);
		// exchequer.updateSupplyRate();

		emit GrantSupply(underlyingAsset, msg.sender, amount);
	}

	function withdraw(
		mapping(address => Types.Exchequer) storage exchequers,
		address underlyingAsset,
		address governanceAsset,
		uint256 amount
	) internal {
		Types.Exchequer storage exchequer = exchequers[underlyingAsset];
		exchequer.update();

		uint256 userBalance = ISToken(exchequer.sTokenAddress).scaledBalanceOf(msg.sender).rayMul(
			exchequer.supplyIndex
		);
		uint256 withdrawableBalance = ISToken(exchequer.sTokenAddress).withdrawableBalance(
			msg.sender,
			exchequer.totalDebt
		);
		StrategusService.guardWithdraw(
			exchequer, 
			userBalance, 
			withdrawableBalance, 
			amount
		);

		ISToken(exchequer.sTokenAddress).burn(
			msg.sender,
			amount,
			exchequer.supplyIndex
		);
		IThurmanToken(governanceAsset).burn(msg.sender, amount);
		exchequer.updateSupplyRate();

		emit Withdraw(underlyingAsset, msg.sender, amount);
	}
}