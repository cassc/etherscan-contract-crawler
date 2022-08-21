// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";

/**
 * Author: Zac Denham
 *
 * This is a modification of Open Zeppelin's Initializable Util
 * that works with diamond storage, you must pass a unique string to the
 * modifier to avoid storage conflicts across contracts
 *
 * Usage: function yourInitializer() public initializer("super.unique.string") {}
 *
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract DiamondInitializable {
    struct DiamondInitializableStorage {
        bool _initialized;
        bool _initializing;
    }

    /**
     * @dev Warning, you must pass a unique storage string
     * for each facet that inherits diamondInitializeable
     * or you may risk storage conflicts
     */
    function getDiamondInitializableStorage(string memory uniqueStorageString) internal pure returns (DiamondInitializableStorage storage s) {
        bytes32 position = keccak256(abi.encodePacked("diamond.initializable.", uniqueStorageString));
        assembly {
            s.slot := position
        }
    }

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer(string memory uniqueStorageString) {
        DiamondInitializableStorage storage s = getDiamondInitializableStorage(uniqueStorageString);
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(s._initializing ? _isConstructor() : !s._initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !s._initializing;
        if (isTopLevelCall) {
            s._initializing = true;
            s._initialized = true;
        }

        _;

        if (isTopLevelCall) {
            s._initializing = false;
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing(string memory uniqueStorageString) {
        require(getDiamondInitializableStorage(uniqueStorageString)._initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}