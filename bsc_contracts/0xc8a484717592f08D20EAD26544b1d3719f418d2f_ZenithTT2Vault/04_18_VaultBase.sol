// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.9;

import { OwnableUpgradeable as Ownable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { ReentrancyGuardUpgradeable as ReentrancyGuard } from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import { ERC20Upgradeable as ERC20 } from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";

import { EmergencyControl } from "../utils/EmergencyControl.sol";
import { Whitelistable } from "../utils/Whitelistable.sol";

import { IVault } from "./IVault.sol";

abstract contract VaultBase is Initializable, Ownable, ReentrancyGuard, ERC20, EmergencyControl, Whitelistable, IVault
{
	uint256 public commission;

	function initialize(string memory _name, string memory _symbol, bytes memory _data) public initializer
	{
		__Ownable_init_unchained();
		__ReentrancyGuard_init_unchained();
		__ERC20_init_unchained(_name, _symbol);
		_initialize(_data);
	}

	function _initialize(bytes memory _data) internal virtual;

	function declareEmergency() external onlyOwner nonEmergency
	{
		_declareEmergency();
	}

	function setWhitelist(address _account, bool _enabled) external onlyOwner
	{
		_setWhitelist(_account, _enabled);
	}

	function setCommission(uint256 _commission) external onlyOwner
	{
		require(_commission <= 1e18, "invalid commission");
		commission = _commission;
		emit CommissionUpdated(_commission);
	}

	function _calcSharesFromAmount(uint256 _totalReserve, uint256 _totalSupply, uint256 _amount) internal pure virtual returns (uint256 _shares)
	{
		if (_totalReserve == 0) return _amount;
		return _amount * _totalSupply / _totalReserve;
	}

	function _calcAmountFromShares(uint256 _totalReserve, uint256 _totalSupply, uint256 _shares) internal pure virtual returns (uint256 _amount)
	{
		if (_totalSupply == 0) return _totalReserve;
		return _shares * _totalReserve / _totalSupply;
	}

	event CommissionUpdated(uint256 _commission);
}