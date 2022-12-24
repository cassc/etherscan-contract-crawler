// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.0;


import "./../storage/MultiVaultStorageInitializable.sol";
import "../../libraries/AddressUpgradeable.sol";


abstract contract MultiVaultHelperInitializable {
    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * Similar to `reinitializer(1)`, except that functions marked with `initializer` can be nested in the context of a
     * constructor.
     *
     * Emits an {Initialized} event.
     */
    modifier initializer() {
        MultiVaultStorageInitializable.InitializableStorage storage s = MultiVaultStorageInitializable._storage();

        bool isTopLevelCall = !s._initializing;
        require(
            (isTopLevelCall && s._initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && s._initialized == 1),
            "Initializable: contract is already initialized"
        );
        s._initialized = 1;
        if (isTopLevelCall) {
            s._initializing = true;
        }
        _;
        if (isTopLevelCall) {
            s._initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * A reinitializer may be used after the original initialization step. This is essential to configure modules that
     * are added through upgrades and that require initialization.
     *
     * When `version` is 1, this modifier is similar to `initializer`, except that functions marked with `reinitializer`
     * cannot be nested. If one is invoked in the context of another, execution will revert.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     *
     * WARNING: setting the version to 255 will prevent any future reinitialization.
     *
     * Emits an {Initialized} event.
     */
    modifier reinitializer(uint8 version) {
        MultiVaultStorageInitializable.InitializableStorage storage s = MultiVaultStorageInitializable._storage();

        require(!s._initializing && s._initialized < version, "Initializable: contract is already initialized");
        s._initialized = version;
        s._initializing = true;
        _;
        s._initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        MultiVaultStorageInitializable.InitializableStorage storage s = MultiVaultStorageInitializable._storage();
        require(s._initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     *
     * Emits an {Initialized} event the first time it is successfully executed.
     */
    function _disableInitializers() internal virtual {
        MultiVaultStorageInitializable.InitializableStorage storage s = MultiVaultStorageInitializable._storage();
        require(!s._initializing, "Initializable: contract is initializing");
        if (s._initialized < type(uint8).max) {
            s._initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /**
     * @dev Internal function that returns the initialized version. Returns `_initialized`
     */
    function _getInitializedVersion() internal view returns (uint8) {
        MultiVaultStorageInitializable.InitializableStorage storage s = MultiVaultStorageInitializable._storage();

        return s._initialized;
    }

    /**
     * @dev Internal function that returns the initialized version. Returns `_initializing`
     */
    function _isInitializing() internal view returns (bool) {
        MultiVaultStorageInitializable.InitializableStorage storage s = MultiVaultStorageInitializable._storage();

        return s._initializing;
    }
}