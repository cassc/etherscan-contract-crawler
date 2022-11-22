// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import { IOperatorFilterRegistry } from "../lib/operator-filter-registry/src/IOperatorFilterRegistry.sol";

/**
 * @dev This is an upgradeable version of OperatorFilterer from https://github.com/ProjectOpenSea/operator-filter-registry/blob/45bbc6955b7f89a8d4bba3473882cd6c1e3b9c94/src/OperatorFilterer.sol.
 * This only takes care of registration of the contract with the OperatorFilterRegistry upon setting the registry contract address.
 * Adding and removing filters has to be done manually on the OperatorFilterRegistry contract.
 */
abstract contract OperatorFiltererUpgradeable is Initializable {
	error OperatorNotAllowed(address operator);

	IOperatorFilterRegistry public operatorFilterRegistry;

	function __OperatorFilterer_init(
		IOperatorFilterRegistry operatorFilterRegistry_
	) internal onlyInitializing {
		__OperatorFilterer_init_unchained(operatorFilterRegistry_);
	}

	function __OperatorFilterer_init_unchained(
		IOperatorFilterRegistry operatorFilterRegistry_
	) internal onlyInitializing {
		_setOperatorFilterRegistry(operatorFilterRegistry_);
	}

	function _setOperatorFilterRegistry(
		IOperatorFilterRegistry operatorFilterRegistry_
	) internal {
		operatorFilterRegistry = operatorFilterRegistry_;

		operatorFilterRegistry.register(address(this));
	}

	modifier onlyAllowedOperator() virtual {
		// Check registry code length to facilitate testing in environments without a deployed registry.
		if (address(operatorFilterRegistry).code.length > 0) {
			if (
				!operatorFilterRegistry.isOperatorAllowed(
					address(this),
					msg.sender
				)
			) {
				revert OperatorNotAllowed(msg.sender);
			}
		}
		_;
	}

	uint256[49] __gap;
}