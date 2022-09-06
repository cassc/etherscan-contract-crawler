// SPDX-License-Identifier: BUSDL-1.1
pragma solidity 0.6.11;

/**
 * @notice The address registry has two important purposes, one which
 * is fairly concrete and another abstract.
 *
 * 1. The registry enables components of the APY.Finance system
 * and external systems to retrieve core addresses reliably
 * even when the functionality may move to a different
 * address.
 *
 * 2. The registry also makes explicit which contracts serve
 * as primary entrypoints for interacting with different
 * components.  Not every contract is registered here, only
 * the ones properly deserving of an identifier.  This helps
 * define explicit boundaries between groups of contracts,
 * each of which is logically cohesive.
 */
interface IAddressRegistryV2 {
    /**
     * @notice Log when a new address is registered
     * @param id The ID of the new address
     * @param _address The new address
     */
    event AddressRegistered(bytes32 id, address _address);

    /**
     * @notice Log when an address is removed from the registry
     * @param id The ID of the address
     * @param _address The address
     */
    event AddressDeleted(bytes32 id, address _address);

    /**
     * @notice Register address with identifier
     * @dev Using an existing ID will replace the old address with new
     * @dev Currently there is no way to remove an ID, as attempting to
     * register the zero address will revert.
     */
    function registerAddress(bytes32 id, address address_) external;

    /**
     * @notice Registers multiple address at once
     * @dev Convenient method to register multiple addresses at once.
     * @param ids Ids to register addresses under
     * @param addresses Addresses to register
     */
    function registerMultipleAddresses(
        bytes32[] calldata ids,
        address[] calldata addresses
    ) external;

    /**
     * @notice Removes a registered id and it's associated address
     * @dev Delete the address corresponding to the identifier Time-complexity is O(n) where n is the length of `_idList`.
     * @param id ID to remove along with it's associated address
     */
    function deleteAddress(bytes32 id) external;

    /**
     * @notice Returns the list of all registered identifiers.
     * @return List of identifiers
     */
    function getIds() external view returns (bytes32[] memory);

    /**
     * @notice Returns the list of all registered identifiers
     * @param id Component identifier
     * @return The current address represented by an identifier
     */
    function getAddress(bytes32 id) external view returns (address);

    /**
     * @notice Returns the TVL Manager Address
     * @dev Not just a helper function, this makes explicit a key ID for the system
     * @return TVL Manager Address
     */
    function tvlManagerAddress() external view returns (address);

    /**
     * @notice Returns the Chainlink Registry Address
     * @dev Not just a helper function, this makes explicit a key ID for the system
     * @return Chainlink Registry Address
     */
    function chainlinkRegistryAddress() external view returns (address);

    /**
     * @notice Returns the DAI Pool Address
     * @dev Not just a helper function, this makes explicit a key ID for the system
     * @return DAI Pool Address
     */
    function daiPoolAddress() external view returns (address);

    /**
     * @notice Returns the USDC Pool Address
     * @dev Not just a helper function, this makes explicit a key ID for the system
     * @return USDC Pool Address
     */
    function usdcPoolAddress() external view returns (address);

    /**
     * @notice Returns the USDT Pool Address
     * @dev Not just a helper function, this makes explicit a key ID for the system
     * @return USDT Pool Address
     */
    function usdtPoolAddress() external view returns (address);

    /**
     * @notice Returns the MAPT Pool Address
     * @dev Not just a helper function, this makes explicit a key ID for the system
     * @return MAPT Pool Address
     */
    function mAptAddress() external view returns (address);

    /**
     * @notice Returns the LP Account Address
     * @dev Not just a helper function, this makes explicit a key ID for the system
     * @return LP Account Address
     */
    function lpAccountAddress() external view returns (address);

    /**
     * @notice Returns the LP Safe Address
     * @dev Not just a helper function, this makes explicit a key ID for the system
     * @return LP Safe Address
     */
    function lpSafeAddress() external view returns (address);

    /**
     * @notice Returns the Admin Safe Address
     * @dev Not just a helper function, this makes explicit a key ID for the system
     * @return Admin Safe Address
     */
    function adminSafeAddress() external view returns (address);

    /**
     * @notice Returns the Emergency Safe Address
     * @dev Not just a helper function, this makes explicit a key ID for the system
     * @return Emergency Safe Address
     */
    function emergencySafeAddress() external view returns (address);

    /**
     * @notice Returns the Oracle Adapter Address
     * @dev Not just a helper function, this makes explicit a key ID for the system
     * @return Oracle Adapter Address
     */
    function oracleAdapterAddress() external view returns (address);

    /**
     * @notice Returns the ERC20 Allocation Address
     * @dev Not just a helper function, this makes explicit a key ID for the system
     * @return ERC20 Allocation Address
     */
    function erc20AllocationAddress() external view returns (address);
}