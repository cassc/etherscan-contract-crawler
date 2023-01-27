// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.9;

import { BeaconProxy } from "@openzeppelin/contracts/proxy/beacon/BeaconProxy.sol";
import { UpgradeableBeacon } from "@openzeppelin/contracts/proxy/beacon/UpgradeableBeacon.sol";
import { Create2 } from "@openzeppelin/contracts/utils/Create2.sol";

import { BaseStakingPool } from "./BaseStakingPool.sol";
import { FeeCollectionManager } from "./FeeCollectionManager.sol";

abstract contract BaseStakingPoolFactory is UpgradeableBeacon, FeeCollectionManager
{
	bytes32 private immutable hash_;

	constructor() UpgradeableBeacon(_createPoolImpl())
	{
		hash_ = keccak256(abi.encodePacked(type(BeaconProxy).creationCode, abi.encode(address(this), new bytes(0))));
	}

	function _createPoolImpl() internal virtual returns (address _pool);

	function computePoolAddress(address _account, uint96 _index) external view returns (address _pool)
	{
		bytes32 _salt = bytes32(uint256(_index) << 160 | uint256(uint160(_account)));
		return Create2.computeAddress(_salt, hash_);
	}

	function createPool(uint96 _index, address _token) external returns (address _pool)
	{
		bytes32 _salt = bytes32(uint256(_index) << 160 | uint256(uint160(msg.sender)));
		_pool = address(new BeaconProxy{salt: _salt}(address(this), new bytes(0)));
		BaseStakingPool(_pool).initialize(msg.sender, _token);
		emit CreatePool(msg.sender, _index, _pool, _token);
		return _pool;
	}

	event CreatePool(address indexed _account, uint96 _index, address indexed _pool, address indexed _token);
}