// SPDX-License-Identifier: MIT

pragma solidity ^0.8.14;
import "../Dependencies/ERC20Permit.sol";
import "../Interfaces/IStabilityPoolManager.sol";

abstract contract IDCHFToken is ERC20Permit {
	// --- Events ---

	event StabilityPoolAddressChanged(address _newStabilityPoolAddress);

	event DCHFTokenBalanceUpdated(address _user, uint256 _amount);

	function emergencyStopMinting(address _asset, bool status) external virtual;

	function addTroveManager(address _troveManager) external virtual;

	function removeTroveManager(address _troveManager) external virtual;

	function addBorrowerOps(address _borrowerOps) external virtual;

	function removeBorrowerOps(address _borrowerOps) external virtual;

	function mint(
		address _asset,
		address _account,
		uint256 _amount
	) external virtual;

	function burn(address _account, uint256 _amount) external virtual;

	function sendToPool(
		address _sender,
		address poolAddress,
		uint256 _amount
	) external virtual;

	function returnFromPool(
		address poolAddress,
		address user,
		uint256 _amount
	) external virtual;
}