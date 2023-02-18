// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.9;

import { BeaconProxy } from "@openzeppelin/contracts/proxy/beacon/BeaconProxy.sol";
import { UpgradeableBeacon } from "@openzeppelin/contracts/proxy/beacon/UpgradeableBeacon.sol";
import { Address } from "@openzeppelin/contracts/utils/Address.sol";
import { Create2 } from "@openzeppelin/contracts/utils/Create2.sol";

import { IVaultFactory } from "./IVaultFactory.sol";
import { VaultBase } from "./VaultBase.sol";

abstract contract VaultFactoryBase is UpgradeableBeacon, IVaultFactory
{
	using Address for address;

	bytes32 private immutable hash_;

	constructor() UpgradeableBeacon(_newVault())
	{
		hash_ = keccak256(abi.encodePacked(type(BeaconProxy).creationCode, abi.encode(address(this), new bytes(0))));
	}

	function _newVault() internal virtual returns (address _vault);

	function taggedVault(address _account, bytes32 _tag) external view override returns (address _vault, bool _exists)
	{
		bytes32 _salt = keccak256(abi.encodePacked(_account, _tag));
		_vault = Create2.computeAddress(_salt, hash_);
		_exists = _vault.isContract();
		return (_vault, _exists);
	}

	function createVault(bytes32 _tag, string memory _name, string memory _symbol, bytes memory _data) external override returns (address _vault)
	{
		bytes32 _salt = keccak256(abi.encodePacked(msg.sender, _tag));
		_vault = address(new BeaconProxy{salt: _salt}(address(this), new bytes(0)));
		VaultBase(_vault).initialize(_name, _symbol, _data);
		VaultBase(_vault).transferOwnership(msg.sender);
		emit NewVaultCreated(_vault, msg.sender);
		return _vault;
	}

	event NewVaultCreated(address indexed _vault, address indexed _owner);
}