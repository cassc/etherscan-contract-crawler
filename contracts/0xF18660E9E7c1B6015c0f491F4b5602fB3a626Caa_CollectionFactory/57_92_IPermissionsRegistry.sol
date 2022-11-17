// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.10;

/**
 * @title Highlight permissions registry interface
 * @author [email protected], [email protected]
 */
interface IPermissionsRegistry {
    /**
     * @notice Emitted when a platform executor is added
     */
    event PlatformExecutorAdded(address indexed newExecutor);

    /**
     * @notice Emitted when a platform executor is deprecated
     */
    event PlatformExecutorDeprecated(address indexed oldExecutor);

    /**
     * @notice Emitted when a currrency is whitelisted system wide
     */
    event CurrencyWhitelisted(address indexed currency);

    /**
     * @notice Emitted when a currrency is unwhitelisted system wide
     */
    event CurrencyUnwhitelisted(address indexed currency);

    /**
     * @dev Swap the platform executor. Expected to be protected by a smart contract wallet.
     */
    function addPlatformExecutor(address _executor) external;

    /**
     * @dev Deprecate the platform executor.
     */
    function deprecatePlatformExecutor(address _executor) external;

    /**
     * @dev Whitelists a currency
     */
    function whitelistCurrency(address _currency) external;

    /**
     * @dev Unwhitelists a currency
     */
    function unwhitelistCurrency(address _currency) external;

    /**
     * @dev Returns true if executor is the platform executor
     */
    function isPlatformExecutor(address executor) external view returns (bool);

    /**
     * @dev Returns the platform executor
     */
    function platformExecutors() external view returns (address[] memory);

    /**
     * @dev Returns true if a currency is whitelisted
     */
    function isCurrencyWhitelisted(address _currency) external view returns (bool);

    /**
     * @dev Returns whitelisted currencies
     */
    function whitelistedCurrencies() external view returns (address[] memory);
}