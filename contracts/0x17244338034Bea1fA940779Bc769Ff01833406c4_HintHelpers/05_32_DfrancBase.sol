// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "@openzeppelin/contracts/access/Ownable.sol";

import "./BaseMath.sol";
import "./DfrancMath.sol";
import "../Interfaces/IActivePool.sol";
import "../Interfaces/IDefaultPool.sol";
import "../Interfaces/IPriceFeed.sol";
import "../Interfaces/IDfrancBase.sol";

/*
 * Base contract for TroveManager, BorrowerOperations and StabilityPool. Contains global system constants and
 * common functions.
 */
contract DfrancBase is BaseMath, IDfrancBase, Ownable {
	using SafeMath for uint256;
	address public constant ETH_REF_ADDRESS = address(0);

	IDfrancParameters public override dfrancParams;

	function setDfrancParameters(address _vaultParams) public onlyOwner {
		dfrancParams = IDfrancParameters(_vaultParams);
		emit VaultParametersBaseChanged(_vaultParams);
	}

	// --- Gas compensation functions ---

	// Returns the composite debt (drawn debt + gas compensation) of a trove, for the purpose of ICR calculation
	function _getCompositeDebt(address _asset, uint256 _debt) internal view returns (uint256) {
		return _debt.add(dfrancParams.DCHF_GAS_COMPENSATION(_asset));
	}

	function _getNetDebt(address _asset, uint256 _debt) internal view returns (uint256) {
		return _debt.sub(dfrancParams.DCHF_GAS_COMPENSATION(_asset));
	}

	// Return the amount of ETH to be drawn from a trove's collateral and sent as gas compensation.
	function _getCollGasCompensation(address _asset, uint256 _entireColl)
		internal
		view
		returns (uint256)
	{
		return _entireColl / dfrancParams.PERCENT_DIVISOR(_asset);
	}

	function getEntireSystemColl(address _asset) public view returns (uint256 entireSystemColl) {
		uint256 activeColl = dfrancParams.activePool().getAssetBalance(_asset);
		uint256 liquidatedColl = dfrancParams.defaultPool().getAssetBalance(_asset);

		return activeColl.add(liquidatedColl);
	}

	function getEntireSystemDebt(address _asset) public view returns (uint256 entireSystemDebt) {
		uint256 activeDebt = dfrancParams.activePool().getDCHFDebt(_asset);
		uint256 closedDebt = dfrancParams.defaultPool().getDCHFDebt(_asset);

		return activeDebt.add(closedDebt);
	}

	function _getTCR(address _asset, uint256 _price) internal view returns (uint256 TCR) {
		uint256 entireSystemColl = getEntireSystemColl(_asset);
		uint256 entireSystemDebt = getEntireSystemDebt(_asset);

		TCR = DfrancMath._computeCR(entireSystemColl, entireSystemDebt, _price);

		return TCR;
	}

	function _checkRecoveryMode(address _asset, uint256 _price) internal view returns (bool) {
		uint256 TCR = _getTCR(_asset, _price);

		return TCR < dfrancParams.CCR(_asset);
	}

	function _requireUserAcceptsFee(
		uint256 _fee,
		uint256 _amount,
		uint256 _maxFeePercentage
	) internal view {
		uint256 feePercentage = _fee.mul(dfrancParams.DECIMAL_PRECISION()).div(_amount);
		require(feePercentage <= _maxFeePercentage, "FM");
	}
}