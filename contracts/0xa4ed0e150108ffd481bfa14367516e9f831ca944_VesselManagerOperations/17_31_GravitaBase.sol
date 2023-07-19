// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

import "./BaseMath.sol";
import "./GravitaMath.sol";
import "../Interfaces/IActivePool.sol";
import "../Interfaces/IDefaultPool.sol";
import "../Interfaces/IGravitaBase.sol";
import "../Interfaces/IAdminContract.sol";
import "../Interfaces/IDefaultPool.sol";
import "../Addresses.sol";

/*
 * Base contract for VesselManager, BorrowerOperations and StabilityPool. Contains global system constants and
 * common functions.
 */
abstract contract GravitaBase is IGravitaBase, BaseMath, OwnableUpgradeable, Addresses {
	// --- Gas compensation functions ---

	// Returns the composite debt (drawn debt + gas compensation) of a vessel, for the purpose of ICR calculation
	function _getCompositeDebt(address _asset, uint256 _debt) internal view returns (uint256) {
		return _debt + IAdminContract(adminContract).getDebtTokenGasCompensation(_asset);
	}

	function _getNetDebt(address _asset, uint256 _debt) internal view returns (uint256) {
		return _debt - IAdminContract(adminContract).getDebtTokenGasCompensation(_asset);
	}

	// Return the amount of ETH to be drawn from a vessel's collateral and sent as gas compensation.
	function _getCollGasCompensation(address _asset, uint256 _entireColl) internal view returns (uint256) {
		return _entireColl / IAdminContract(adminContract).getPercentDivisor(_asset);
	}

	function getEntireSystemColl(address _asset) public view returns (uint256 entireSystemColl) {
		uint256 activeColl = IActivePool(activePool).getAssetBalance(_asset);
		uint256 liquidatedColl = IDefaultPool(defaultPool).getAssetBalance(_asset);
		return activeColl + liquidatedColl;
	}

	function getEntireSystemDebt(address _asset) public view returns (uint256 entireSystemDebt) {
		uint256 activeDebt = IActivePool(activePool).getDebtTokenBalance(_asset);
		uint256 closedDebt = IDefaultPool(defaultPool).getDebtTokenBalance(_asset);
		return activeDebt + closedDebt;
	}

	function _getTCR(address _asset, uint256 _price) internal view returns (uint256 TCR) {
		uint256 entireSystemColl = getEntireSystemColl(_asset);
		uint256 entireSystemDebt = getEntireSystemDebt(_asset);
		TCR = GravitaMath._computeCR(entireSystemColl, entireSystemDebt, _price);
	}

	function _checkRecoveryMode(address _asset, uint256 _price) internal view returns (bool) {
		uint256 TCR = _getTCR(_asset, _price);
		return TCR < IAdminContract(adminContract).getCcr(_asset);
	}

	function _requireUserAcceptsFee(uint256 _fee, uint256 _amount, uint256 _maxFeePercentage) internal view {
		uint256 feePercentage = (_fee * IAdminContract(adminContract).DECIMAL_PRECISION()) / _amount;
		require(feePercentage <= _maxFeePercentage, "Fee exceeded provided maximum");
	}
}