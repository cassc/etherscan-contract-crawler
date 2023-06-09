// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.7;

import { IProxied } from "./interfaces/IProxied.sol";

import { Proxy } from "./Proxy.sol";

/// @title A factory for Proxy contracts that proxy Proxied implementations.
abstract contract ProxyFactory {

    mapping(uint256 => address) internal _implementationOf;

    mapping(address => uint256) internal _versionOf;

    mapping(uint256 => mapping(uint256 => address)) internal _migratorForPath;

    /// @dev Returns the implementation of `proxy_`.
    function _getImplementationOfProxy(address proxy_) private view returns (bool success_, address implementation_) {
        bytes memory returnData;
        // Since `_getImplementationOfProxy` is a private function, no need to check `proxy_` is a contract.
        ( success_, returnData ) = proxy_.staticcall(abi.encodeWithSelector(IProxied.implementation.selector));
        implementation_ = abi.decode(returnData, (address));
    }

    /// @dev Initializes `proxy_` using the initializer for `version_`, given some initialization arguments.
    function _initializeInstance(address proxy_, uint256 version_, bytes memory arguments_) private returns (bool success_) {
        // The migrator, where fromVersion == toVersion, is an initializer.
        address initializer = _migratorForPath[version_][version_];

        // If there is no initializer, then no initialization is necessary, so long as no initialization arguments were provided.
        if (initializer == address(0)) return arguments_.length == uint256(0);

        // Call the migrate function on the proxy, passing any initialization arguments.
        // Since `_initializeInstance` is a private function, no need to check `proxy_` is a contract.
        ( success_, ) = proxy_.call(abi.encodeWithSelector(IProxied.migrate.selector, initializer, arguments_));
    }

    /// @dev Deploys a new proxy for some version, with some initialization arguments,
    ///      using `create` (i.e. factory's nonce determines the address).
    function _newInstance(uint256 version_, bytes memory arguments_) internal virtual returns (bool success_, address proxy_) {
        address implementation = _implementationOf[version_];

        if (implementation == address(0)) return (false, address(0));

        proxy_   = address(new Proxy(address(this), implementation));
        success_ = _initializeInstance(proxy_, version_, arguments_);
    }

    /// @dev Deploys a new proxy, with some initialization arguments, using `create2` (i.e. salt determines the address).
    ///      This factory needs to be IDefaultImplementationBeacon, since the proxy will pull its implementation from it.
    function _newInstance(bytes memory arguments_, bytes32 salt_) internal virtual returns (bool success_, address proxy_) {
        proxy_ = address(new Proxy{ salt: salt_ }(address(this), address(0)));

        // Fetch the implementation from the proxy. Don't care about success,
        // since the version of the implementation will be checked in the next step.
        ( , address implementation ) = _getImplementationOfProxy(proxy_);

        // Get the version of the implementation.
        uint256 version = _versionOf[implementation];

        // Successful if version is nonzero (i.e. implementation fetched successfully from proxy) and initializing the instance succeeds.
        success_ = (version != uint256(0)) && _initializeInstance(proxy_, version, arguments_);
    }

    /// @dev Registers an implementation for some version.
    function _registerImplementation(uint256 version_, address implementation_) internal virtual returns (bool success_) {
        // Version 0 is not allowed since its the default value of all _versionOf[implementation_].
        // Implementation cannot already be registered and cannot be empty account (and thus also not address(0)).
        if (
            version_ == uint256(0) ||
            _implementationOf[version_] != address(0) ||
            _versionOf[implementation_] != uint256(0) ||
            !_isContract(implementation_)
        ) return false;

        // Store in two-way mappings.
        _implementationOf[version_] = implementation_;
        _versionOf[implementation_] = version_;

        return true;
    }

    /// @dev Registers a migrator for between two versions. If `fromVersion_ == toVersion_`, migrator is an initializer.
    function _registerMigrator(uint256 fromVersion_, uint256 toVersion_, address migrator_) internal virtual returns (bool success_) {
        // Version 0 is invalid.
        if (fromVersion_ == uint256(0) || toVersion_ == uint256(0)) return false;

        // Migrator must either be zero (clearing) or a contract (setting).
        if (migrator_ != address(0) && !_isContract(migrator_)) return false;

        _migratorForPath[fromVersion_][toVersion_] = migrator_;

        return true;
    }

    /// @dev Upgrades a proxy to a new version of an implementation, with some migration arguments.
    ///      Inheritor should revert on `success_ = false`, since proxy can be set to new implementation, but failed to migrate.
    function _upgradeInstance(address proxy_, uint256 toVersion_, bytes memory arguments_) internal virtual returns (bool success_) {
        // Check that the proxy is currently a contract, just once, ahead of the 3 times it will be low-level-called.
        if (!_isContract(proxy_)) return false;

        address toImplementation = _implementationOf[toVersion_];

        // The implementation being migrated must have been registered (which also implies that `toVersion_` was not 0).
        if (toImplementation == address(0)) return false;

        // Fetch the implementation from the proxy.
        address fromImplementation;
        ( success_, fromImplementation ) = _getImplementationOfProxy(proxy_);

        if (!success_) return false;

        // Set the proxy's implementation.
        ( success_, ) = proxy_.call(abi.encodeWithSelector(IProxied.setImplementation.selector, toImplementation));

        if (!success_) return false;

        // Get the version of the `fromImplementation`, then get the `migrator` of the upgrade path to `toVersion_`.
        address migrator = _migratorForPath[_versionOf[fromImplementation]][toVersion_];

        // If there is no migrator, then no migration is necessary, so long as no migration arguments were provided.
        if (migrator == address(0)) return arguments_.length == uint256(0);

        // Call the migrate function on the proxy, passing any migration arguments.
        ( success_, ) = proxy_.call(abi.encodeWithSelector(IProxied.migrate.selector, migrator, arguments_));
    }

    /// @dev Returns the deterministic address of a proxy given some salt.
    function _getDeterministicProxyAddress(bytes32 salt_) internal virtual view returns (address deterministicProxyAddress_) {
        // See https://docs.soliditylang.org/en/v0.8.7/control-structures.html#salted-contract-creations-create2
        return address(
            uint160(
                uint256(
                    keccak256(
                        abi.encodePacked(
                            bytes1(0xff),
                            address(this),
                            salt_,
                            keccak256(abi.encodePacked(type(Proxy).creationCode, abi.encode(address(this), address(0))))
                        )
                    )
                )
            )
        );
    }

    /// @dev Returns whether the account is currently a contract.
    function _isContract(address account_) internal view returns (bool isContract_) {
        return account_.code.length != uint256(0);
    }

}