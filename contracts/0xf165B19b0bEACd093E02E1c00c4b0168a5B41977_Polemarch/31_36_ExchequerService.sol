// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import {AddressUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import {SafeCast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import {ISToken} from "../../../interfaces/ISToken.sol";
import {IDToken} from "../../../interfaces/IDToken.sol";
import {MathUtils} from "../math/MathUtils.sol";
import {WadRayMath} from "../math/WadRayMath.sol";
import {Types} from "../types/Types.sol";
import {DebtService} from "./DebtService.sol";
import {StrategusService} from "./StrategusService.sol";


library ExchequerService {
	using WadRayMath for uint256;
	using SafeCast for uint256;
	using ExchequerService for Types.Exchequer;
	
	function addExchequer(
		mapping(address => Types.Exchequer) storage exchequers,
		mapping(uint256 => address) storage exchequersList,
		address underlyingAsset,
		address sTokenAddress,
		address dTokenAddress,
		address gTokenAddress,
		uint8 decimals,
		uint256 protocolBorrowFee,
		uint16 exchequersCount,
		uint16 maxExchequersCount
	) internal returns (bool) {
		require(AddressUpgradeable.isContract(underlyingAsset), "NOT_CONTRACT");
		require(exchequers[underlyingAsset].sTokenAddress == address(0), "EXCHEQUER_ALREADY_INITIALIZED");

		exchequers[underlyingAsset].supplyIndex = uint128(WadRayMath.RAY);
		exchequers[underlyingAsset].collateralFactor = WadRayMath.RAY;
		exchequers[underlyingAsset].sTokenAddress = sTokenAddress;
		exchequers[underlyingAsset].dTokenAddress = dTokenAddress;
		exchequers[underlyingAsset].gTokenAddress = gTokenAddress;
		exchequers[underlyingAsset].decimals = decimals;

		bool exchequerAlreadyAdded = exchequers[underlyingAsset].id != 0 ||
			exchequersList[0] == underlyingAsset;
		require(!exchequerAlreadyAdded, "EXCHEQUER_ALREADY_ADDED");

		for (uint16 i = 0; i < exchequersCount; i++) {
			if (exchequersList[i] == address(0)) {
				exchequers[underlyingAsset].id = i;
				exchequersList[i] = underlyingAsset;
				return false;
			}
		}

		require(exchequersCount < maxExchequersCount, "NO_MORE_RESERVES_ALLOWED");
		exchequers[underlyingAsset].id = exchequersCount;
		exchequersList[exchequersCount] = underlyingAsset;
		exchequers[underlyingAsset].protocolBorrowFee = protocolBorrowFee;
		exchequers[underlyingAsset].active = true;
		return true;
	}

	function deleteExchequer(
		mapping(address => Types.Exchequer) storage exchequers,
		mapping(uint256 => address) storage exchequersList,
		address underlyingAsset
	) internal {
		Types.Exchequer storage exchequer = exchequers[underlyingAsset];
		StrategusService.guardDeleteExchequer(exchequersList, exchequer, underlyingAsset);
		exchequersList[exchequers[underlyingAsset].id] = address(0);
		delete exchequers[underlyingAsset];
	}

	function update(Types.Exchequer storage exchequer) internal {
		_updateIndexes(exchequer);
		// _accrueToExchequerSafe();
		// create accrual to exchequerSafe if desired
		
	}

	function _updateIndexes(Types.Exchequer storage exchequer) internal {
		// actually create logic to update indexes and related state based on repayments
		uint nextSupplyIndex = exchequer.supplyIndex;

		if (exchequer.supplyRate != 0) {
			uint256 cumulatedInterest = MathUtils.calculateLinearInterest(
				exchequer.supplyRate,
				exchequer.lastUpdateTimestamp
			);
			exchequer.supplyIndex = uint128(cumulatedInterest.rayMul(nextSupplyIndex));
		}
		exchequer.lastUpdateTimestamp = uint40(block.timestamp);
	}

	// function _accrueToExchequerSafe(Types.Exchequer storage exchequer) internal {
	// 	if (exchequer.exchequerFactor == 0) {
	// 		return;
	// 	}


	// }

	function calculateProtocolFee(
		Types.Exchequer storage exchequer,
		uint256 borrowMax,
		uint40 termDays
	) internal view returns (uint256) {
		uint256 termSeconds = uint256(termDays) * 1 days;
		uint256 protocolBorrowFee = exchequer.protocolBorrowFee.wadToRay();
		// protocolBorrowFee = protocolBorrowFee.wadToRay();
		return uint256(borrowMax.rayMul(uint256(protocolBorrowFee)).
			rayMul((termSeconds).rayDiv(MathUtils.SECONDS_PER_YEAR)));
	}

	function _getSupplyRate(
		uint256 totalDebt, 
		uint256 totalSupply,
		uint256 currentAverageRate
	) internal pure returns (uint128) {
		uint256 currentSupplyRate = 0;		
		uint256 usageRate = totalDebt.rayDiv(totalSupply);
		currentSupplyRate = currentAverageRate.rayMul(usageRate);
		return uint128(currentSupplyRate);
	}

	function getNormalizedReturn(Types.Exchequer storage exchequer) internal view returns (uint256) {
		uint40 timestamp = exchequer.lastUpdateTimestamp;

		if (timestamp == block.timestamp) {
			return exchequer.supplyIndex;
		} else {
			return MathUtils.calculateLinearInterest(exchequer.supplyRate, timestamp).rayMul(
				exchequer.supplyIndex
			);
		}
	}

	function updateSupplyRate(Types.Exchequer storage exchequer) internal {
		uint256 totalDebt = IDToken(exchequer.dTokenAddress).totalSupply();
		uint256 totalSupply = ISToken(exchequer.sTokenAddress).totalSupply();
		uint256 averageRate = IDToken(exchequer.dTokenAddress).getAverageRate();
		exchequer.supplyRate = _getSupplyRate(totalDebt, totalSupply, averageRate);
	}
}