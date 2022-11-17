// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import "./interfaces/IPermissionsRegistry.sol";
import "../utils/ERC165/ERC165.sol";
import "../utils/Ownable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

/**
 * @title Highlight permissions registry
 * @author [email protected], [email protected]
 * @dev Allows for O(1) swapping of the platform executor.
 */
contract PermissionsRegistry is IPermissionsRegistry, Ownable, ERC165 {
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;

    /**
     * @dev Whitelisted currencies for system
     */
    EnumerableSetUpgradeable.AddressSet internal _whitelistedCurrencies;

    /**
     * @dev Platform transaction executors
     */
    EnumerableSetUpgradeable.AddressSet internal _platformExecutors;

    /**
     * @notice Initialize the registry with an initial platform executor and the platform vault
     */
    constructor(address _initialExecutor, address _initialOwner) {
        _platformExecutors.add(_initialExecutor);
        _transferOwnership(_initialOwner);
    }

    /**
     * @dev Add platform executor. Expected to be protected by a smart contract wallet.
     */
    function addPlatformExecutor(address _executor) external onlyOwner {
        require(_executor != address(0), "Cannot set to null address");
        require(_platformExecutors.add(_executor), "Already added");
        emit PlatformExecutorAdded(_executor);
    }

    /**
     * @dev Deprecate the platform executor.
     */
    function deprecatePlatformExecutor(address _executor) external onlyOwner {
        require(_platformExecutors.remove(_executor), "Not deprecated");
        emit PlatformExecutorDeprecated(_executor);
    }

    /**
     * @dev Whitelists a currency
     */
    function whitelistCurrency(address _currency) external onlyOwner {
        require(_whitelistedCurrencies.add(_currency), "Already whitelisted");
        emit CurrencyWhitelisted(_currency);
    }

    /**
     * @dev Unwhitelists a currency
     */
    function unwhitelistCurrency(address _currency) external onlyOwner {
        require(_whitelistedCurrencies.remove(_currency), "Not whitelisted");
        emit CurrencyUnwhitelisted(_currency);
    }

    /**
     * @dev Returns true if executor is a platform executor
     */
    function isPlatformExecutor(address _executor) external view returns (bool) {
        return _platformExecutors.contains(_executor);
    }

    /**
     * @dev Returns platform executors
     */
    function platformExecutors() external view returns (address[] memory) {
        return _platformExecutors.values();
    }

    /**
     * @dev Returns true if a currency is whitelisted
     */
    function isCurrencyWhitelisted(address _currency) external view returns (bool) {
        return _whitelistedCurrencies.contains(_currency);
    }

    /**
     * @dev Returns whitelisted currencies
     */
    function whitelistedCurrencies() external view returns (address[] memory) {
        return _whitelistedCurrencies.values();
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165) returns (bool) {
        return interfaceId == type(IPermissionsRegistry).interfaceId || super.supportsInterface(interfaceId);
    }
}