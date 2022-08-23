// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.2;

import "TimeLock.sol";

contract ApeRegistry is TimeLock {
	address public feeRegistry;
	address public router;
	address public distributor;
	address public factory;
	address public treasury;

	event FeeRegistryChanged(address feeRegistry);
	event RouterChanged(address router);
	event DistributorChanged(address distributor);
	event FactoryChanged(address factory);
	event TreasuryChanged(address treasury);

	constructor(address _treasury, uint256 _minDelay) TimeLock(_minDelay) {
		treasury = _treasury;
		emit TreasuryChanged(_treasury);
	}

	function setFeeRegistry(address _registry) external itself {
		feeRegistry = _registry;
		emit FeeRegistryChanged(_registry);
	}

	function setRouter(address _router) external itself {
		router = _router;
		emit RouterChanged(_router);
	}

	function setDistributor(address _distributor) external itself {
		distributor = _distributor;
		emit DistributorChanged(_distributor);
	}

	function setFactory(address _factory) external itself {
		factory = _factory;
		emit FactoryChanged(_factory);
	}

	function setTreasury(address _treasury) external itself {
		treasury = _treasury;
		emit TreasuryChanged(_treasury);
	}
}