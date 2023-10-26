// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

struct Implementation {
    address implAddress;
    bytes4[] selectors;
}

interface IAddressRelay {
    /**
     * @notice Returns the fallback implementation address
     */
    function fallbackImplAddress() external returns (address);

    /**
     * @notice Adds or updates selectors and their implementation addresses
     * @param _selectors The selectors to add or update
     * @param _implAddress The implementation address the selectors will point to
     */
    function addOrUpdateSelectors(
        bytes4[] memory _selectors,
        address _implAddress
    ) external;

    /**
     * @notice Removes selectors
     * @param _selectors The selectors to remove
     */
    function removeSelectors(bytes4[] memory _selectors) external;

    /**
     * @notice Removes an implementation address and all the selectors that point to it
     * @param _implAddress The implementation address to remove
     */
    function removeImplAddressAndAllSelectors(address _implAddress) external;

    /**
     * @notice Returns the implementation address for a given function selector
     * @param _functionSelector The function selector to get the implementation address for
     */
    function getImplAddress(
        bytes4 _functionSelector
    ) external view returns (address implAddress_);

    /**
     * @notice Returns all the implementation addresses and the selectors they support
     * @return impls_ An array of Implementation structs
     */
    function getAllImplAddressesAndSelectors()
        external
        view
        returns (Implementation[] memory impls_);

    /**
     * @notice Return all the fucntion selectors associated with an implementation address
     * @param _implAddress The implementation address to get the selectors for
     */
    function getSelectorsForImplAddress(
        address _implAddress
    ) external view returns (bytes4[] memory selectors_);

    /**
     * @notice Sets the fallback implementation address to use when a function selector is not found
     * @param _fallbackAddress The fallback implementation address
     */
    function setFallbackImplAddress(address _fallbackAddress) external;

    /**
     * @notice Updates the supported interfaces
     * @param _interfaceId The interface ID to update
     * @param _supported Whether the interface is supported or not
     */
    function updateSupportedInterfaces(
        bytes4 _interfaceId,
        bool _supported
    ) external;

    /**
     * @notice Returns whether the interface is supported or not
     * @param _interfaceId The interface ID to check
     */
    function supportsInterface(
        bytes4 _interfaceId
    ) external view returns (bool);
}