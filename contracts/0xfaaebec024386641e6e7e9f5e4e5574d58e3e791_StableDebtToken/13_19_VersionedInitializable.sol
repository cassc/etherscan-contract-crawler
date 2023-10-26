// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.12;

/**
 * @title VersionedInitializable
 *
 * @dev Helper contract to implement initializer functions. To use it, replace
 * the constructor with a function that has the `initializer` modifier.
 * WARNING: Unlike constructors, initializer functions must be manually
 * invoked. This applies both to deploying an Initializable contract, as well
 * as extending an Initializable contract via inheritance.
 * WARNING: When used with inheritance, manual care must be taken to not invoke
 * a parent initializer twice, or ensure that all initializers are idempotent,
 * because this is not dealt with automatically as with constructors.
 *
 * @author Aave, inspired by the OpenZeppelin Initializable contract
 */
abstract contract VersionedInitializable {
	/**
	 * @dev Indicates that the contract has been initialized.
	 */
	uint256 private lastInitializedRevision = 0;

	/**
	 * @dev Indicates that the contract is in the process of being initialized.
	 */
	bool private initializing;

	/**
	 * @dev Indicates that the contract has been initialized.
	 */
	bool private initialized;

	/**
	 * @dev Modifier to use in the initializer function of a contract.
	 */
	modifier initializer() {
		uint256 revision = getRevision();
		bool isTopLevelCall = !initializing;

		require(
			isTopLevelCall && (revision > lastInitializedRevision || !initialized),
			"Contract instance has already been initialized"
		);

		if (isTopLevelCall) {
			initializing = true;
			initialized = true;
			lastInitializedRevision = revision;
		}

		_;

		if (isTopLevelCall) {
			initializing = false;
		}
	}

	/**
	 * @dev returns the revision number of the contract
	 * Needs to be defined in the inherited class as a constant.
	 **/
	function getRevision() internal pure virtual returns (uint256);

	function _disableInitializers() internal virtual {
		require(!initializing, "Initializable: contract is initializing");
		if (!initialized) {
			initialized = true;
		}
	}

	// Reserved storage space to allow for layout changes in the future.
	uint256[50] private ______gap;
}